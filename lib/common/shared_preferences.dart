import 'package:shared_preferences/shared_preferences.dart';


class SharedPrefe {
  static SharedPreferences? prefs;


  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  /// お気に入り設定
  static void setFavoriteRestaurant(List<String> res) {
    prefs!.setStringList('target', res);
  }


  /// お気に入り取得
  static List<String> getFavoriteRestaurant() {
    return prefs!.getStringList('target') ?? [];
  }

}