import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:suerogu/model/restaurant.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'package:geoflutterfire2/geoflutterfire2.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class FireStore {

  late FirebaseFirestore db;
  late GeoFlutterFire geo;
  final collection = "restaurant";
  // final double standard = 0.001;
  final double standard = 0.01;
  final int limit = 30;

  // 初期化
  FireStore() {
    db = FirebaseFirestore.instance;
    geo = GeoFlutterFire();
  }

  // 店舗情報取得
  Future<List<Restaurant>> fetchRestaurant(
    double latitude,  // 緯度
    double longitude,  // 経度
  ) async {
    print("より小さい");
    print(latitude + standard);
    print("より大きい");
    print(latitude - standard);
    // 「かつ」の指定ができないから、2回に分けて取得する
    final docs1 = await db.collection(collection).limit(limit)
      // 緯度
      .where('latitude', isLessThan: latitude + standard) // より小さい
      .where('latitude', isGreaterThan: latitude - standard) // より大きい
      .get();
    final restaurant1 = docs1.docs.map((doc) => Restaurant(doc)).toList();
    final restaurant11 = restaurant1.where((res) {
      // return longitude + standard > res.longitude || longitude - standard < res.longitude;
      if (longitude > res.longitude) {
        return longitude - standard < res.longitude;
      } else {
        return longitude + standard > res.longitude;
      }
    }).toList();
    final ids = restaurant11.map((e) => e.id).toList();  // ドキュメントidのみの配列

    final docs2 = await db.collection(collection).limit(limit)
      // 経度
      .where('longitude', isLessThan: longitude + standard) // より小さい
      .where('longitude', isGreaterThan: longitude - standard) // より大きい
      .get();
    final restaurant2 = docs2.docs.map((doc) => Restaurant(doc)).toList();

    final restaurant22 = restaurant2.where((res) {
      // return latitude + latitude_standard < res.latitude || latitude - latitude_standard < res.latitude;
      if (latitude > res.latitude) {
        return latitude - standard < res.latitude;
      } else {
        return latitude + standard > res.latitude;
      }
    }).toList();

    // docs1との重複を弾く
    final filter_restaurant2 = restaurant22.where((res) {
      return !ids.contains(res.id);
    }).toList();

    // return restaurant11;

    restaurant1.addAll(filter_restaurant2);
    print(restaurant1.length);
    return restaurant1;
  }


  fetchRest ({
    required double latitude,  // 緯度
    required double longitude,  // 経度
    String? genre
  }) async {

    GeoFirePoint center = geo.point(
      latitude: latitude,
      longitude: longitude
    );

    Query<Map<String, dynamic>> collectionReference = db.collection(collection);
    if (genre != null) {
      print("ジャンル！！");
      collectionReference = collectionReference.where("genre", arrayContainsAny: [genre]);
    }

    double radius = 0.3;
    String field = 'position';

    Stream<List<DocumentSnapshot>> stream =
      geo.collection(collectionRef: collectionReference)
        .within(center: center, radius: radius, field: field);

    return stream;
  }
}
