import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {

  // 店名
  late String name;
  // 食べログurl
  late String url;
  // 食べログ内評価
  late String evaluation;
  // ジャンル
  late String genre;
  // 電話番号
  late String phone;
  // 営業時間
  late String opening_hours;
  // 住所
  late String address;
  // 緯度
  late double latitude;
  // 経度
  late double longitude;
  // ドキュメントID
  late String id;
  // 画像url
  late List images;

  Restaurant(DocumentSnapshot doc) {
    name = doc['name'];
    url = doc['url'];
    evaluation = doc['evaluation'];
    genre = doc['genre'];
    phone = doc['phone'];
    opening_hours = doc['opening_hours'];
    address = doc['address'];
    latitude = doc['latitude'];
    longitude = doc['longitude'];
    id = doc.id;
    images = doc['images'];
  }

}