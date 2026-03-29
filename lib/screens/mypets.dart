import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/card.dart';

class MyPets extends StatefulWidget {
  static const routeName = '/mypets';

  const MyPets({Key? key})
      : super(key: key); // Use required keyword and nullable type

  _MyPetsState createState() => _MyPetsState();
}

class _MyPetsState extends State<MyPets> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          color: Colors.black,
          iconSize: 40,
          icon: Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: SvgPicture.asset('assets/images/BellAndNotification.svg'),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: CustomScrollView(
        shrinkWrap: true,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              height: 136,
              margin: EdgeInsets.symmetric(vertical: 30, horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'My Pet\'s',
                    style: TextStyle(fontSize: 45, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          SliverGrid.count(
            crossAxisCount: 2,
            children: <Widget>[
              card(context, 'AddPets', 'svg', 'Add Pet'),
              // Other pet cards will be added dynamically from Firebase
            ],
          ),
        ],
      ),
    );
  }
}
