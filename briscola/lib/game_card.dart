import 'package:flutter/material.dart';

class GameCard extends StatefulWidget{
  const GameCard({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<StatefulWidget> createState() => GameCardState();
}


class GameCardState extends State<GameCard>{
  String path = "images/cards/retro.jpg";
  String retroPath = "images/cards/retro.jpg";
  String? frontPath;

  String? seme;
  int? valore;

  void setFrontPath(String seme, int valore){
    this.seme = seme;
    this.valore = valore;
    frontPath = "images/cards/$seme/$valore.jpg";
  }

  void setVisible(){
    setState(() {
      path = frontPath!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: widget.width,
      height: widget.height,
    );
  }

}