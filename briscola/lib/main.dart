import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

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
  WebSocket? socket;

  late List indicatori = [
    Center(child: ElevatedButton(onPressed: _connectToServer, child: Text("Connettiti")))
  ];

  String _serverMessage = "Nessuna connessione";

  List<GlobalKey<GameCardState>> keysCard = [];
  List<ValueNotifier<Offset>> positions = []; // notifiers per ogni carta
  List<bool> tapEnabled = [];

  int lastDrawCard = 1;

  @override
  void initState() {
    super.initState();
    //_connectToServer();
  }

  void _connectToServer() async {
    indicatori.removeLast();
    indicatori.add(Center(child: Text("Collegamento...")));
    
    try {
      // Cambia localhost con l'IP del tuo PC se usi un emulatore Android
      socket = await WebSocket.connect('ws://10.0.2.2:8080/ws');
      indicatori.removeLast();
      indicatori.add(Center(child: Text("In attesa dell'avversario...")));
      _listen();
    } catch (e) {
      setState(() {
        _serverMessage = "Errore di connessione: $e";
      });
    }
  }

  void _listen(){
    socket!.listen((data) {
      setState(() {
        _serverMessage = data.toString();
        if(_serverMessage != "Connesso"){
          _parseMessage(_serverMessage);
        }
      });
    });
  }

  void _parseMessage(String serverMessage){
    final decodedServerMessage = jsonDecode(serverMessage);
    String message = decodedServerMessage['message'];

    switch (message) {
      case "init":
        initGame();
        break;
      case "briscola":
        //WidgetsBinding.instance.addPostFrameCallback((_) {
          discoverBriscola(decodedServerMessage['seme'], decodedServerMessage['valore']);
        //});
        break;
    }

  }

  void initGame(){
    indicatori.removeLast();

    double x = 0;
    double y = 470;
    for (int i = 0; i < 40; i++) {
      keysCard.add(GlobalKey<GameCardState>());
      positions.add(ValueNotifier(Offset(x, y)));
      tapEnabled.add(false);
      y += 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      socket!.add("initialized");
    });
  }

  void discoverBriscola(String seme, int valore) {
    keysCard[keysCard.length - 1].currentState!.setFrontPath(seme, valore);
    keysCard[keysCard.length - 1].currentState!.setVisible();
    moveCard(keysCard.length - lastDrawCard, Offset(0, 220));
    lastDrawCard++;

    socket!.add("briscola discovered");
  }

  void moveCard(int index, Offset newPos) {
    positions[index].value = newPos;
  }

  void giocaCarta(int i){
    moveCard(i, const Offset(100, 100));
  }


  double x = 0;
  double y = 470;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          //children: widgets
          children: [
            for (int i = 0; i < keysCard.length; i++)
              ValueListenableBuilder<Offset>(
                valueListenable: positions[i],
                builder: (context, pos, child) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    left: pos.dx,
                    top: pos.dy,
                    child: GestureDetector(
                      onTap: tapEnabled[i] ? () {
                        giocaCarta(i);
                        //disableTap(i); // disabilita dopo il primo tap
                      } : null,
                      child: GameCard(key: keysCard[i]),
                    ),
                  );
                },
              ),
            ...indicatori
          ],
        ),
      ),
    );
  }
}
