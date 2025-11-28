import 'package:flutter/material.dart';

class GameCard extends StatefulWidget{
  final String backPath = "images/back.png";

  const GameCard({super.key});

  @override
  State<StatefulWidget> createState() => GameCardState();
}


class GameCardState extends State<GameCard>{
  String? frontPath;

  void setFrontPath(String path){
    frontPath = path;
  }

  void setVisible(){

  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Image.asset(
        "images/cards/retro.jpg",
        fit: BoxFit.cover,
        width: 100,
        height: 300,
      ),
    );
  }

}