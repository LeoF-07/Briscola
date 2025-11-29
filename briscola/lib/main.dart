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
  List<Offset> coordinate = []; // notifiers per ogni carta
  List<bool> tapEnabled = [];

  int lastDrawCard = 1;

  @override
  void initState() {
    super.initState();
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
        discoverBriscola(decodedServerMessage['seme'], decodedServerMessage['valore']);
        break;
      case "drawCards":
        drawCards(decodedServerMessage['cards']);
    }

  }

  void initGame(){
    indicatori.removeLast();

    double x = 0;
    double y = 470;
    for (int i = 0; i < 40; i++) {
      keysCard.add(GlobalKey<GameCardState>());
      coordinate.add(Offset(x, y));
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

  Future<void> drawMyCards(List cards) async {
    double x = 240;

    await for (var i in Stream.periodic(Duration(seconds: 1), (count) => count).take(3))
    {
      moveCard(keysCard.length - lastDrawCard, Offset(x, 800));
      setState(() {
        tapEnabled[keysCard.length - lastDrawCard] = true;
      });

      await Future.delayed(Duration(milliseconds: 100), () {
        int cardIndex = lastDrawCard;
        setState(() {
          keysCard[keysCard.length - cardIndex].currentState!.setFrontPath(cards[i]['seme'], cards[i]['valore']);
          keysCard[keysCard.length - cardIndex].currentState!.setVisible();
        });
      });
      lastDrawCard++;
      x -= 80;
    }
  }

  void drawOpponentCards(){
    double x = 80;
    Stream.periodic(Duration(seconds: 1), (count) {
      return count;
    }).take(3).listen((data)
    {
      moveCard(keysCard.length - lastDrawCard, Offset(x, -50));
      lastDrawCard++;
      x += 80;
    });
  }

  void drawCards(List cards) async {
    await drawMyCards(cards);
    drawOpponentCards();
  }

  void moveCard(int index, Offset newPos) {
    setState(() {
      coordinate[index] = newPos;
    });
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
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                left: coordinate[i].dx,
                top: coordinate[i].dy,
                child: GestureDetector(
                  onTap: tapEnabled[i] ? () {
                    giocaCarta(i);
                    //disableTap(i); // disabilita dopo il primo tap
                  } : null,
                  child: GameCard(key: keysCard[i]),
                ),
              ),
            ...indicatori
          ],
        ),
      ),
    );
  }
}
