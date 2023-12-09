import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:suerogu/common/shared_preferences.dart';
import 'package:suerogu/model/restaurant.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:suerogu/page/detail.dart';


class FavoriteDraggableScrollable extends StatefulWidget {
  // ゲーム情報
  List<Restaurant> restaurants;
  // マップの表示制御用
  GoogleMapController? mapController;
  // ターゲット店舗更新
  void Function(Restaurant) updateFunc;

  FavoriteDraggableScrollable({
    super.key,
    required this.restaurants,
    this.mapController,
    required this.updateFunc,
  });

  @override
  State<FavoriteDraggableScrollable> createState() => FavoriteDraggableScrollableState();
}

class FavoriteDraggableScrollableState extends State<FavoriteDraggableScrollable> {

  Restaurant? targetRestaurant;

  BuildContext? targetContext;

  // お気に入りid一覧
  late List<String> ids;

  final _scrollController = DraggableScrollableController();

  // モーダル内で遷移する
  void routeDetail(Restaurant restaurant) async {
    await animateToDrag(0.4);

    Navigator.of(targetContext!).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          // TODO: 遷移するのではなく、Visibilityを使ってDraggableScrollableを非表示・表示にできるか？
          // https://zenn.dev/captain_blue/articles/flutter-control-visibility
          return Detail(
            restaurant: restaurant,
            isFavorite: ids.contains(restaurant.id),
            updateFavorite: _setFavorite
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Offset begin = Offset(1.0, 0.0);
          final Offset end = Offset.zero;
          final Animatable<Offset> tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeInOut));
          final Animation<Offset> offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }


  // お気に入りに追加/削除
  void _setFavorite(String id) {
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
      ids = ids.toSet().toList();
    }
    SharedPrefe.setFavoriteRestaurant(ids);
    setState(() {
      ids;
    });
  }


  Future _init() async {
    await SharedPrefe.init();
    ids = SharedPrefe.getFavoriteRestaurant();
  }


  // DraggableScrollableSheetの表示割合を変更
  Future<void> animateToDrag(double size) async {
    _scrollController.animateTo(size,
      duration: Duration(milliseconds: 100), curve: Curves.easeInOut
    );
  }


  @override
  void initState() {
    super.initState();
    _init();
  }


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.7,
      controller: _scrollController,
      builder: (BuildContext context, ScrollController scrollController) {
        return Navigator(
          onGenerateRoute: (context) => MaterialPageRoute(
            builder: (context) {
              targetContext = context;
              return Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 218, 243, 255),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                // カート商品表示のタイトルとアイテム一覧を表示
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      // ドラッグ中に呼ばれる
                      onVerticalDragUpdate: (DragUpdateDetails details) {
                        final dy = details.delta.dy; // y座標の移動距離を取得
                        // 正の数の場合は上に移動。負の数の場合は下に移動
                        if (dy.isNegative) {
                          animateToDrag(0.9);
                        } else {
                          animateToDrag(0.1);
                        }
                      },
                      child: SizedBox(
                        height: 40,
                        child: Center(
                          child: Row(
                            children: [
                              Text(
                                "お気に入り一覧",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                color: Colors.grey[500],
                                icon: const Icon(Icons.clear_outlined),
                                onPressed: () {
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.grey[300],
                      thickness: 1,
                      height: 20,
                    ),
                    // 　カートのアイテム一覧を表示
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: widget.restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = widget.restaurants[index];
                          return GestureDetector(
                            onTap: () async {
                              final zoomLevel = await widget.mapController!.getZoomLevel();//現在のズームレベルを取得（現在のズームの倍率を変えないため）
                              //GoogleMapControllerのメソッドで任意の座標にカメラポジションを移動させる
                              await widget.mapController!.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(
                                      restaurant.latitude,
                                      restaurant.longitude
                                    ),
                                    zoom: zoomLevel,
                                  ),
                                ),
                              );
                              String latitude = restaurant.latitude.toString();
                              String longitude = restaurant.longitude.toString();
                              String location = '($latitude, $longitude)';
                              await widget.mapController!.showMarkerInfoWindow(MarkerId(location)); // マーカータップ以外のアクションから吹き出しを表示
                              widget.updateFunc(restaurant);  // 親の関数を実行
                              routeDetail(restaurant);
                            },
                            child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 100,
                                    color: Colors.grey.withOpacity(0.7),
                                    child: CachedNetworkImage(
                                      imageUrl: restaurant.images[0],
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, dynamic error) => const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        restaurant.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                      Text(restaurant.genre.join(", ")),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _setFavorite(restaurant.id);
                                  },
                                  selectedIcon: const Icon(Icons.favorite),
                                  icon: Icon(
                                    Icons.favorite_border,
                                    color: ids.contains(restaurant.id)
                                      ? Colors.red
                                      : Colors.white,
                                  ),
                                  isSelected: ids.contains(restaurant.id),
                                ),
                              ],
                            ),
                          )
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } ,
          ),
        );
      },
    );
  }

}