import 'dart:math';

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

  int lastDrawCard = 39;
  List<int> drawedCards = [];
  List<int> opponentCards = [];

  int? indexOfPlayedCard;
  int? indexOfOpponentCard;

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
    keysCard[lastDrawCard].currentState!.setFrontPath(seme, valore);
    keysCard[lastDrawCard].currentState!.setVisible();
    moveCard(lastDrawCard, Offset(0, 220));
    lastDrawCard--;

    socket!.add("briscola discovered");
  }

  Future<void> drawMyCards(List cards) async {
    double x = 240;

    drawedCards.clear();
    await for (var i in Stream.periodic(Duration(seconds: 1), (count) => count).take(3))
    {
      moveCard(lastDrawCard, Offset(x, 800));

      int drawedCard = lastDrawCard;
      drawedCards.add(drawedCard);

      makeCardVisible(drawedCard, cards[i]['seme'], cards[i]['valore']);

      lastDrawCard--;
      x -= 80;
    }
  }

  Future<void> drawOpponentCards() async {
    opponentCards.clear();
    double x = 80;
    Stream.periodic(Duration(seconds: 1), (count) {
      return count;
    }).take(3).listen((data)
    {
      opponentCards.add(lastDrawCard);
      moveCard(lastDrawCard, Offset(x, -50));
      lastDrawCard--;
      x += 80;
    });
  }

  void drawCards(List cards) async {
    await drawMyCards(cards);
    await drawOpponentCards();
    socket!.add("cards drawed");
  }

  void makeCardsTappable(bool tappable){
    for(int drawedCard in drawedCards){
      setState(() {
        if(tappable) {
          tapEnabled[drawedCard] = true;
        } else {
          tapEnabled[drawedCard] = false;
        }
      });
    }
  }

  void makeCardVisible(int indice, String seme, int valore){
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        keysCard[indice].currentState!.setFrontPath(seme, valore);
        keysCard[indice].currentState!.setVisible();
      });
    });
  }

  void play(){
    makeCardsTappable(true);
  }

  void moveCard(int index, Offset newPos) {
    setState(() {
      coordinate[index] = newPos;
    });
  }

  void giocaCarta(int i){
    indexOfPlayedCard = i;
    moveCard(i, const Offset(200, 400));
    makeCardsTappable(false);
    drawedCards.remove(i);

    String playedCardJson = jsonEncode(
        {
          'message': 'card played',
          'seme': keysCard[i].currentState!.seme,
          'valore':  keysCard[i].currentState!.valore
        }
    );
    socket!.add(playedCardJson);
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
        break;
      case "your turn":
        play();
        break;
      case "opponent played":
        int index = Random().nextInt(opponentCards.length);
        indexOfOpponentCard = opponentCards[index];
        moveCard(opponentCards[index], Offset(200, 190));
        makeCardVisible(opponentCards[index], decodedServerMessage['seme'], decodedServerMessage['valore']);
        opponentCards.removeAt(index);
        socket!.add("opponent card received");
        break;
      case "you won":
        moveCard(indexOfPlayedCard!, Offset(300, 400));
        moveCard(indexOfOpponentCard!, Offset(300, 400));
        socket!.add("confront received");
        break;
      case "you lose":
        moveCard(indexOfPlayedCard!, Offset(300, 190));
        moveCard(indexOfOpponentCard!, Offset(300, 190));
        socket!.add("confront received");
        break;
    }

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
