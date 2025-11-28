import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';

import 'game_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _serverMessage = "Nessuna connessione";

  List<Widget> widgets = [];

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() async {
    try {
      // Cambia localhost con l'IP del tuo PC se usi un emulatore Android
      final WebSocket socket = await WebSocket.connect('ws://10.0.2.2:8080/ws');
      socket.listen((data) {
        setState(() {
          _serverMessage = data.toString();
          if(_serverMessage != "Connesso"){
            _parseMessage(_serverMessage);
          }
        });
      });
    } catch (e) {
      setState(() {
        _serverMessage = "Errore di connessione: $e";
      });
    }
  }

  void _listen(WebSocket socket){

  }

  void _parseMessage(String serverMessage){
    String message = jsonDecode(serverMessage)['message'];
    switch (message) {
      case "init":
        initGame();
        break;
    }

  }

  void initGame(){
    setState(() {
      for(int i = 0; i < 40; i++){
        double y = 2;
        widgets.add(
          Positioned(
            left: 0,
            top: y,
            child: GameCard(),
          )
        );
        y += 2;
      }
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/background.png"), // percorso immagine
            fit: BoxFit.cover, // Adatta l'immagine a tutto lo schermo
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_serverMessage),
            ...widgets
          ]
        ),
      ),
    );
  }
}
