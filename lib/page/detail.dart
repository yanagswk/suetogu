import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:suerogu/common/shared_preferences.dart';
import 'package:suerogu/model/restaurant.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class Detail extends StatefulWidget {

  Restaurant restaurant;
  bool isFavorite;

  // ターゲット店舗更新
  void Function(String) updateFavorite;

  Detail({
    super.key,
    required this.restaurant,
    required this.isFavorite,
    required this.updateFavorite
  });

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {

  late Restaurant restaurant;
  late bool isFavorite;

  late double deviceWidth;

  // お気に入りid一覧
  late List<String> ids;

  @override
  void initState() {
    super.initState();
    // _init();
    restaurant = widget.restaurant;
    isFavorite = widget.isFavorite;
    setState(() {});
  }

  // Future _init() async {
  //   await SharedPrefe.init();
  //   ids = SharedPrefe.getFavoriteRestaurant();
  // }

  // // お気に入りに追加/削除
  // void _setFavorite(String id) {
  //   if (ids.contains(id)) {
  //     ids.remove(id);
  //   } else {
  //     ids.add(id);
  //     ids = ids.toSet().toList();
  //   }
  //   SharedPrefe.setFavoriteRestaurant(ids);
  // }


  Widget _backButton() {
    return IconButton(
      padding: EdgeInsets.only(right: 10),
      constraints: const BoxConstraints(),
      icon: const Icon(
        Icons.chevron_left,
        color: Colors.grey,
      ),
      onPressed: () {
        // 一番最初の一覧画面に戻る
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }


  Widget _goToGoogleMapApp() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.grey.shade200,
          ),
        ],
      ),
      child: ActionChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 追加：上下の余計なmarginを削除
        labelPadding: EdgeInsets.symmetric(horizontal: 1), // 追加：文字左右の多すぎるpaddingを調整
        visualDensity: VisualDensity(horizontal: 0.0, vertical: -4), // 追加：文字上下の多すぎるpaddingを調整
        backgroundColor: Colors.grey.shade300,
        avatar: const Icon(
          Icons.map_outlined,
          size: 18,
          color: Colors.red,
        ),
        label: const Text(
          '地図',
          style: TextStyle(
            fontSize: 13
          ),
        ),
        onPressed: () async {
          // google map アプリへ遷移
          final url =
            Uri.parse('https://www.google.com/maps/search/?api=1&query=${restaurant.latitude},${restaurant.longitude}');
          if (await canLaunchUrl(url)) {
            launchUrl(url);
          }
        },
      ),
    );
  }


  Widget _favoriteChip() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: ActionChip(
          padding: const EdgeInsets.only(left: 50, right: 50),
          label: Text(
            isFavorite ? 'お気に入り登録済み' : 'お気に入り登録する',
            style: TextStyle(
              fontSize: 13,
              color: isFavorite ? Colors.white : Colors.red,
            ),
          ),
          backgroundColor: isFavorite ? Colors.red : Colors.white,
          avatar: Icon(
            Icons.favorite_border,
            size: 18,
            color: isFavorite ? Colors.white : Colors.red,
          ),
          onPressed:() {
            setState(() {
              // 親にあるお気に入り関数を実行
              widget.updateFavorite(restaurant.id);
              isFavorite = !isFavorite;
            });
          },
        ),
      ),
    );
  }


  Widget _restaurantContent({
    required String title,
    required Widget widget,
    required double width
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: width * 0.3,
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold)
              ),
            ),
            Flexible(
              child: Container(
                child: widget
              )
            )
          ],
        ),
        Divider(
          color: Colors.grey[400],
          thickness: 1,
          height: 20,
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 218, 243, 255),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                _backButton(),
                Expanded(
                  child: Text(
                    restaurant.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                ),
                _goToGoogleMapApp()
              ],
            ),
            Divider(
              color: Colors.grey[300],
              thickness: 1,
              height: 20,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < restaurant.images.length; i++)
                            Container(
                              height: 100,
                              margin: const EdgeInsets.only(right: 10, left: 10, bottom: 10),
                              child: CachedNetworkImage(
                                imageUrl: restaurant.images[i],
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, dynamic error) => const Icon(Icons.error),
                              ),
                            ),
                        ],
                      ),
                    ),

                    _favoriteChip(),

                    _restaurantContent(
                      title: "ジャンル",
                      widget: Text(restaurant.genre.join(", ")),
                      width: deviceWidth
                    ),
                    _restaurantContent(
                      title: "評価",
                      widget: Row(
                        children: [
                          RatingBar.builder(
                            itemBuilder: (context, index) => const Icon(
                              Icons.star,
                              color: Colors.yellow,
                            ),
                            itemSize: 25,
                            unratedColor: Colors.grey[400],
                            onRatingUpdate: (rating) {
                              //評価が更新されたときの処理を書く
                            },
                            initialRating: restaurant.evaluation == "-"
                              ? 0
                              : double.parse(restaurant.evaluation),
                            allowHalfRating: true,
                            ignoreGestures: true
                          ),
                          const SizedBox(width: 5),
                          Text(
                            restaurant.evaluation,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red
                            )
                          )
                        ],
                      ),
                      width: deviceWidth
                    ),
                    _restaurantContent(
                      title: "電話番号",
                      widget: Text(restaurant.phone),
                      width: deviceWidth
                    ),
                    _restaurantContent(
                      title: "営業時間",
                      widget: Text(restaurant.opening_hours),
                      width: deviceWidth
                    ),
                    _restaurantContent(
                      title: "住所",
                      widget: Text(restaurant.address),
                      width: deviceWidth
                    ),
                  ]
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
