import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:suerogu/firestore.dart';
import 'package:suerogu/model/restaurant.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class Secrets {
  // Google Maps APIキーをここに追加
  static const API_KEY = 'AIzaSyAEnWfsC84p0E4hFsTrGFMsBKkYdlGryds';
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // マップビューの初期位置
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  // マップの表示制御用
  late GoogleMapController mapController;
  // 現在位置の記憶用
  late Position _currentPosition;

  // 場所の記憶用
  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();
  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();
  String _currentAddress = '';
  String _startAddress = '';
  String _destinationAddress = '';
  String? _placeDistance;

  Set<Marker> markers = {};

  List<Restaurant> restaurants = [];
  Restaurant? targetRestaurant;

  // PolylinePoints用オブジェクト
  late PolylinePoints polylinePoints;
  // 参加する座標のリスト
  List<LatLng> polylineCoordinates = [];
  // 2点間を結ぶポリラインを格納した地図
  Map<PolylineId, Polyline> polylines = {};


  // 現在位置の取得方法
  _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are deniedddddddddd');
      }
    }

    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() async {
        // 位置を変数に格納する
        _currentPosition = position;

        print('現在地: $_currentPosition');

        // カメラを現在位置に移動させる場合
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _currentPosition.latitude,
                _currentPosition.longitude,
              ),
              zoom: 16.0,
            ),
          ),
        );

        // ここで周辺の情報取得する
        await _getRestaurant();
      });
      await _getAddress();
    }).catchError((e) {
      print("エラーーーーーー");
      print(e);
    });
  }


  // データ取得
  _getRestaurant() async {
    final store = FireStore();
    restaurants = await store.fetchRestaurant(
      _currentPosition.latitude,
      _currentPosition.longitude,
    );
    setState(() {
      restaurants;
    });
  }


  // アドレスの取得方法
  _getAddress() async {
    try {
      // 座標を使用して場所を取得する
      List<Placemark> p = await placemarkFromCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude
      );

      // 最も確率の高い結果を取得
      Placemark place = p[0];

      setState(() {
        // アドレスの構造化
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
        // TextFieldのテキストを更新
        startAddressController.text = _currentAddress;

        // ユーザーの現在地を出発地とする設定
        _startAddress = _currentAddress;
      });
    } catch (e) {
      print(e);
    }
  }


  // UI表示用
  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) locationCallback,
  }) {
    return Container(
      width: width * 0.8,
      child: TextField(
        onChanged: (value) {
          locationCallback(value);
        },
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  Widget _searchRestaurant() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black38
            ),
            width: MediaQuery.of(context).size.width * 0.85,
            child: Padding(
              padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '場所検索',
                    style: TextStyle(fontSize: 20.0, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  _textField(
                      label: '開始位置',
                      hint: '開始位置を入力',
                      prefixIcon: Icon(Icons.directions_walk),
                      controller: startAddressController,
                      focusNode: startAddressFocusNode,
                      width: MediaQuery.of(context).size.width,
                      locationCallback: (String value) {
                        setState(() {
                          _startAddress = value;
                        });
                      }),
                  SizedBox(height: 10),
                  Visibility(
                    visible: _placeDistance == null ? false : true,
                    child: Text(
                      'DISTANCE: $_placeDistance km',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  ElevatedButton(
                    onPressed: () {
                      _RouteDistance();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'ルート検索'.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 店舗情報
  // Widget restaurantInfo() {
  //   return SafeArea(
  //     child: Align(
  //       alignment: Alignment.topCenter,
  //       child: Padding(
  //         padding: const EdgeInsets.only(top: 10.0),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             color: Colors.white
  //           ),
  //           width: MediaQuery.of(context).size.width * 0.85,
  //           height: MediaQuery.of(context).size.width * 0.4,
  //           child: Padding(
  //             padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: <Widget>[
  //                 Text(
  //                   targetName,
  //                   style: TextStyle(fontSize: 20.0, color: Colors.black),
  //                 ),
  //                 SizedBox(height: 10),
  //                 Text(
  //                   targetGenre,
  //                   style: TextStyle(fontSize: 15.0, color: Colors.black),
  //                 ),
  //                 SizedBox(height: 10),
  //                 Text(
  //                   targetAddress,
  //                   style: TextStyle(fontSize: 15.0, color: Colors.black),
  //                 ),
  //                 SizedBox(height: 10),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }


  // ドラグアップできるウィジェット
  Widget _draggableScrollable() {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
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
              //　カート商品表示のタイトル
              const SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    "付近のタバコOKな居酒屋",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              //　カートのアイテム一覧を表示
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return GestureDetector(
                      onTap: () async {
                        final zoomLevel = await mapController.getZoomLevel();//現在のズームレベルを取得（現在のズームの倍率を変えないため）
	                      //GoogleMapControllerのメソッドで任意の座標にカメラポジションを移動させる
                        await mapController.animateCamera(
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
                        setState(() {
                          targetRestaurant = restaurant;
                        });
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
                              child: const Center(
                                  child: Text(
                                "Image",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              )),
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
                                Text(restaurant.genre),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.delete,
                            ),
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
      },
    );
  }


    // 2地点間の距離の算出方法
  Future<bool> _RouteDistance() async {
    try {
      for (var restaurant in restaurants) {
        // print(restaurant.address);
        // List<Location>? destinationPlacemark = await locationFromAddress(restaurant.address);

        // double destinationLatitude = destinationPlacemark.first.latitude;
        // double destinationLongitude = destinationPlacemark.first.longitude;
        // String destinationCoordinatesString = '($destinationLatitude, $destinationLongitude)';

        // print(destinationCoordinatesString);

        // // 目的位置用マーカー
        // Marker destinationMarker = Marker(
        //   markerId: MarkerId(destinationCoordinatesString),
        //   position: LatLng(destinationLatitude, destinationLongitude),
        //   infoWindow: InfoWindow(
        //     title: restaurant.name,
        //     snippet: "flutter",
        //   ),
        //   icon: BitmapDescriptor.defaultMarker,
        //   onTap: () {
        //     setState(() {
        //       targetName = restaurant.name;
        //       targetGenre = restaurant.genre;
        //       targetAddress = restaurant.address;
        //     });
        //   },
        // );
        // // マーカーをリストに追加する
        // markers.add(destinationMarker);
      }

      setState(() {});

      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }


  _createPolylines(
      double startLatitude,
      double startLongitude,
      double destinationLatitude,
      double destinationLongitude,
      ) async {
    polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Secrets.API_KEY,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: TravelMode.walking,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }



  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    // 画面の幅と高さを決定する
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: <Widget>[

            GoogleMap(
              markers: restaurants.map((Restaurant restaurant) {
                var latitude = restaurant.latitude;
                var longitude = restaurant.longitude;
                String location = '($latitude, $longitude)';
                return Marker(
                  markerId: MarkerId(location),
                  position: LatLng(latitude, longitude),
                  icon: restaurant.id == targetRestaurant?.id
                      ? BitmapDescriptor.defaultMarker
                      : BitmapDescriptor.defaultMarkerWithHue(180),
                  infoWindow: InfoWindow(
                    title: restaurant.name,
                    snippet: "($latitude, $longitude)",
                  ),
                  onTap: () {
                    setState(() {
                      targetRestaurant = restaurant;
                    });
                  });
                }).toSet(),
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              // 地図も中心の経度と緯度を取得
              onCameraMove:(position) {
                // print(position.target);
              },
              // 地図のスワイプが完了したt最後に呼ばれる
              onCameraIdle:() {
                print("ストップ");
              },
            ),

            _draggableScrollable(),

            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 100.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      // ズームインボタン
                      ClipOval(
                        child: Material(
                          color: Colors.blue.shade100, // ボタンを押す前のカラー
                          child: InkWell(
                            splashColor: Colors.blue, // ボタンを押した後のカラー
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Icon(Icons.add),
                            ),
                            onTap: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      //　ズームアウトボタン
                      ClipOval(
                        child: Material(
                          color: Colors.blue.shade100, // ボタンを押す前のカラー
                          child: InkWell(
                            splashColor: Colors.blue, // ボタンを押した後のカラー
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Icon(Icons.remove),
                            ),
                            onTap: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                  // 現在地表示ボタン
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange.shade100, // ボタンを押す前のカラー
                      child: InkWell(
                        splashColor: Colors.blue, // ボタンを押した後のカラー
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 18.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),


             // 開智位置と目的位置を入力するためのUI
            // _searchRestaurant(),

            // 店情報表示
            // restaurantInfo()

          ],
        ),
      ),
    );
  }
}