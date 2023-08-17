import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suerogu/model/restaurant.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class FireStore {

  late FirebaseFirestore db;
  final collection = "restaurant";
  // final double standard = 0.0005;
  final double standard = 0.001;
  final int limit = 30;

  // 初期化
  FireStore() {
    db = FirebaseFirestore.instance;
  }

  // 店舗情報取得
  Future<List<Restaurant>> fetchRestaurant(
    double latitude,  // 緯度
    double longitude,  // 経度
  ) async {
    // 「かつ」の指定ができないから、2回に分けて取得する
    final docs1 = await db.collection(collection).limit(limit)
      // 緯度
      .where('latitude', isLessThan: latitude + standard) // より小さい
      .where('latitude', isGreaterThan: latitude - standard) // より大きい
      .get();
    final restaurant1 = docs1.docs.map((doc) => Restaurant(doc)).toList();
    final ids = restaurant1.map((e) => e.id).toList();  // ドキュメントidのみの配列

    final docs2 = await db.collection(collection).limit(limit)
      // 経度
      .where('longitude', isLessThan: longitude + standard) // より小さい
      .where('longitude', isGreaterThan: longitude - standard) // より大きい
      .get();
    final restaurant2 = docs2.docs.map((doc) => Restaurant(doc)).toList();

    // docs1との重複を弾く
    final filter_restaurant2 = restaurant2.where((res) {
      return !ids.contains(res.id);
    }).toList();

    restaurant1.addAll(filter_restaurant2);
    print(restaurant1.length);
    return restaurant1;
  }
}