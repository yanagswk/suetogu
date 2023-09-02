import 'package:flutter/material.dart';
import 'package:suerogu/model/restaurant.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Detail extends StatefulWidget {

  Restaurant restaurant;

  Detail({
    super.key,
    required this.restaurant,
  });

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {

  late Restaurant restaurant;

  @override
  void initState() {
    super.initState();
    // 受け取った値をを変数に設定
    restaurant = widget.restaurant;
    setState(() {});
  }

  Widget BackButton() {
    return IconButton(
      icon: const Icon(
        Icons.cancel_outlined,
        color: Colors.grey,
      ),
      onPressed: () {
        // 一番最初の一覧画面に戻る
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 218, 243, 255),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  BackButton()
                ],
              ),
              const SizedBox(height: 10),
              Text(restaurant.genre),
              // const SizedBox(height: 5),
              Row(
                children: [
                  const Text("食べログ評価 : "),
                  // const SizedBox(width: 5),
                  RatingBar.builder(
                    itemBuilder: (context, index) => const Icon(Icons.star),
                    onRatingUpdate: (rating) {
                      //評価が更新されたときの処理を書く
                    },
                    initialRating: restaurant.evaluation == "-"
                      ? 0
                      : double.parse(restaurant.evaluation),
                    allowHalfRating: true,
                    ignoreGestures: true
                  ),
                  // const SizedBox(width: 10),
                  Text(
                    restaurant.evaluation,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    ),
                  )
                ],
              ),
              Text(restaurant.phone),
              Text(restaurant.opening_hours),
              Text(restaurant.address),
              Text(restaurant.url),
            ]
          ),
        ),
      ),
    );
  }
}


// class BackButton extends StatelessWidget {
//   const BackButton({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return TextButton(
//       child: const Text(
//         '<',
//         style: TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 12.0,
//         ),
//       ),
//       onPressed: () {
//         // 一番最初の一覧画面に戻る
//         Navigator.popUntil(context, (route) => route.isFirst);
//       },
//     );
//   }
// }