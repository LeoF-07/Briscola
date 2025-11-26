import 'package:flutter/material.dart';

class GameCard extends StatefulWidget{
  final String backPath = "images/back.png";
  final String frontPath;

  const GameCard({super.key, required this.frontPath});

  @override
  State<StatefulWidget> createState() => GameCardState();
}


class GameCardState extends State<GameCard>{

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Image.asset(
        "images/background.png",
        fit: BoxFit.cover,
        width: 200,
        height: 200,
      ),
    );
  }

}