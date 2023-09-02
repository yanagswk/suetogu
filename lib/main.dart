import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:suerogu/common/shared_preferences.dart';
import 'package:suerogu/firestore.dart';
import 'package:suerogu/model/restaurant.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:suerogu/page/detail.dart';
import 'package:suerogu/widget/draggable_scrollable.dart';

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
  late GoogleMapController? mapController = null;
  // 現在位置の記憶用
  late Position _currentPosition;
  late LatLng _afterCurrentPosition;

  var  _scrollController = DraggableScrollableController();

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
  late List<String> ids;

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
        mapController!.animateCamera(
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
        await _getRestaurant(
          _currentPosition.latitude,
          _currentPosition.longitude,
        );
      });
      await _getAddress();
    }).catchError((e) {
      print("エラーーーーーー");
      print(e);
    });
  }


  // データ取得
  // _getRestaurant(
  //   double latitude,
  //   double longitude,
  // ) async {
  //   print("検索");
  //   print("$latitude, $longitude");
  //   final store = FireStore();
  //   setState(() {
  //     restaurants.clear();
  //   });
  //   restaurants = await store.fetchRestaurant(
  //     latitude,
  //     longitude,
  //   );
  //   setState(() {
  //     restaurants;
  //   });
  // }


  _getRestaurant(
    double latitude,
    double longitude,
  ) async {
    print("検索");
    print("$latitude, $longitude");

    final store = FireStore();
    setState(() {
      restaurants.clear();
    });
    var stream = await store.aaaaaaa(
      latitude,
      longitude,
    );

    stream.listen((List<DocumentSnapshot> documentList) {
      restaurants = documentList.map((doc) => Restaurant(doc)).toList();
      print(restaurants.length);
      print(restaurants);
      setState(() {
        restaurants;
      });
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


  // お気に入りに追加/削除
  void _setFavorite(String id) {
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
      ids = ids.toSet().toList();
    }
    SharedPrefe.setFavoriteRestaurant(ids);
  }


  Widget googleMap(GlobalObjectKey<DraggableScrollableState> draggableScrollableKey) {
    return GoogleMap(
      markers: restaurants.map((Restaurant restaurant) {
        var latitude = restaurant.latitude;
        var longitude = restaurant.longitude;
        String location = '($latitude, $longitude)';
        return Marker(
          markerId: MarkerId(location),
          position: LatLng(latitude, longitude),
          icon: restaurant.id == targetRestaurant?.id
              ? BitmapDescriptor.defaultMarker
              : BitmapDescriptor.defaultMarkerWithHue(180)
          ,
          infoWindow: InfoWindow(
            title: restaurant.name,
            snippet: "($latitude, $longitude)",
          ),
          onTap: () {
            print("やあああああああああ");
            setState(() {
              targetRestaurant = restaurant;
            });
            // 子のWidgetの関数を呼ぶ
            draggableScrollableKey.currentState?.routeDetail(restaurant);
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
        // 地図の中心取得
        _afterCurrentPosition = position.target;
        // DraggableScrollableSheetへ通知
        // draggableScrollableKey.currentState?.animateToDrag(0.1);
      },
      // 地図のスワイプが完了したら最後に呼ばれる
      onCameraIdle:() {
        // TODO: ストップしたら、その中心付近のお店を検索
      },
    );
  }


  Widget _searchRestaurant() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.grey,
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width * 0.85,
            child: TextFormField(
              onFieldSubmitted: (value) {
                _searchPlace(value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white,
                  )
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                prefixIcon: IconButton(
                  color: Colors.grey[500],
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () {
                  },
                ),
                hintText: '場所を検索',
                hintStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // 現在地を表示
  Widget moveCurrentPlace() {
    return SafeArea(
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
                  mapController!.animateCamera(
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
    );
  }


  Widget zoomCamera() {
    return SafeArea(
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
                      mapController!.animateCamera(
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
                      mapController!.animateCamera(
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
    );
  }


  Widget targetAreaSearch() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          // 現在地表示ボタン
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: 30,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
            child: ActionChip(
              backgroundColor: Colors.white,
              // avatar: Icon(favorite ? Icons.favorite : Icons.favorite_border),
              label: const Text(
                'このエリアを検索',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold
                ),
              ),
              onPressed: () {
                setState(() {
                  print(_afterCurrentPosition);
                  _getRestaurant(
                    _afterCurrentPosition.latitude,
                    _afterCurrentPosition.longitude
                  );
                });
              },
            ),
          ),
        ),
      ),
    );
  }


  // 2地点間の距離の算出方法
  Future<bool> _searchPlace(target) async {
    try {
      print(target);
      List<Location>? destinationPlacemark = await locationFromAddress(target);

      double destinationLatitude = destinationPlacemark.first.latitude;
      double destinationLongitude = destinationPlacemark.first.longitude;
      String destinationCoordinatesString = '($destinationLatitude, $destinationLongitude)';

      print(destinationCoordinatesString);

      // 目的位置用マーカー
      Marker destinationMarker = Marker(
        markerId: MarkerId(destinationCoordinatesString),
        position: LatLng(destinationLatitude, destinationLongitude),
        infoWindow: InfoWindow(
          title: "ここやねん",
          snippet: "flutter",
        ),
        icon: BitmapDescriptor.defaultMarker,
        onTap: () {
        },
      );
      // マーカーをリストに追加する
      markers.add(destinationMarker);

      mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                destinationLatitude,
                destinationLongitude,
              ),
              zoom: 16.0,
            ),
          ),
        );

      // _searchPlace()
      _getRestaurant(
        destinationLatitude,
        destinationLongitude
      );

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

  Future _init() async {
    await SharedPrefe.init();
    ids = SharedPrefe.getFavoriteRestaurant();
  }


  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _init();
  }


  void slideInModal() async {
    _scrollController.animateTo(
      0.5,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut
    );
  }


  void slideOutModal() async {
    targetRestaurant = null;
    _scrollController.animateTo(
      0.3,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut
    );
  }


  void updateTargetRestaurant(Restaurant restaurant) {
    setState(() {
      targetRestaurant = restaurant;
    });
  }


  @override
  Widget build(BuildContext context) {
    // 画面の幅と高さを決定する
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    final draggableScrollableKey = GlobalObjectKey<DraggableScrollableState>(context);

    return Container(
      height: height,
      width: width,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            // google map
            googleMap(draggableScrollableKey),

            // 周辺の居酒屋一覧
            DraggableScrollable(
              key: draggableScrollableKey,
              restaurants: restaurants,
              mapController: mapController,
              updateFunc: updateTargetRestaurant,
            ),

            // ズームイン・ズームアウト
            zoomCamera(),
            // 現在地
            moveCurrentPlace(),
            // エリア検索
            targetAreaSearch(),
             // 開智位置と目的位置を入力するためのUI
            _searchRestaurant(),
          ],
        ),
      ),
    );
  }
}



