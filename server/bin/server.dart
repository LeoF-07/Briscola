import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'card.dart';


const List<String> semi = ["Denari", "Coppe", "Spade", "Bastoni"];
enum Player {player1, player2}


Future<void> main() async {
  // Avvia il server HTTP sulla porta 8080
  final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server avviato su ws://localhost:8080/ws');

  WebSocket? socket1;
  WebSocket? socket2;

  int connectedPlayers = 0;



  List<Card> cards = [];
  List<Card> player1Cards = [];
  List<Card> player2Cards = [];
  Card? briscola;

  void initCards(){
    for(String seme in semi){
      for(int i = 1; i <= 10; i++) {
        cards.add(Card(seme: seme, valore: i));
      }
    }
  }

  void shuffleCards(){
    cards.shuffle(Random());
  }

  List<Card> draw3Cards(){
    List<Card> drawedCards = [];
    for(int i = 0; i < 3; i++){
      drawedCards.add(cards.removeLast());
    }
    return drawedCards;
  }

  void sendInitializedGame(){
    String jsonMazzo = jsonEncode(cards.map((card) => card.toJson()).toList());
    String jsonBriscola = jsonEncode(briscola!.toJson());
    String jsonPlayer1Cards = jsonEncode(player1Cards.map((card) => card.toJson()).toList());
    String jsonPlayer2Cards = jsonEncode(player2Cards.map((card) => card.toJson()).toList());

    String jsonInitializedGameDataPlayer1 = jsonEncode(
      {
        'mazzo': jsonMazzo,
        'briscola': jsonBriscola,
        'playerCards': jsonPlayer1Cards
      }
    );

    String jsonInitializedGameDataPlayer2 = jsonEncode(
      {
        'mazzo': jsonMazzo,
        'briscola': jsonBriscola,
        'playerCards': jsonPlayer2Cards
      }
    );

    socket1!.add(jsonInitializedGameDataPlayer1);
    socket2!.add(jsonInitializedGameDataPlayer2);
  }

  void discoverBriscola(){
    briscola = cards.removeLast();

    print(briscola!.seme);
    print(briscola!.valore);

    String jsonBriscola = jsonEncode(
      {
        'message': 'briscola',
        'seme': briscola!.seme,
        'valore': briscola!.valore
      }
    );

    socket1!.add(jsonBriscola);
    socket2!.add(jsonBriscola);
  }

  void startGame(){
    initCards();
    shuffleCards();

    String jsonInit = jsonEncode({'message': 'init'});
    socket1!.add(jsonInit);
    socket2!.add(jsonInit);

    int initPlayer = 0;

    socket1.listen((data) {
      print(data);
      if(data == "initialized"){
        initPlayer++;
        if(initPlayer == 2){
          discoverBriscola();
          initPlayer++; // Così non li rileva due volte
        }
      }
    });
    socket2.listen((data) {
      print(data);
      if(data == "initialized"){
        initPlayer++;
        if(initPlayer == 2){
          discoverBriscola();
          initPlayer++;
        }
      }
    });
  }



  await for (HttpRequest req in server) {
    // Gestisce solo il percorso /ws
    if (req.uri.path == '/ws' && connectedPlayers == 0) {
      socket1 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');

      // Invia messaggio di benvenuto
      socket1.add('Connesso');
      // Lo cambio, devo trovare un modo per diversificare i tipi di messaggi inviati al client
      // Tipo qui potrei mandare un json {type: "message", content: "Connesso"} (o content, o data, o come voglio chiamarlo io)
      // E invece quando invio i dati di gioco {type: "gameData", content: "..."}

      connectedPlayers++;

      // Ascolta eventuali messaggi dal client
      /*socket1.listen((msg) {
        print('Messaggio dal client: $msg');
      });*/
    } 
    else if(req.uri.path == '/ws' && connectedPlayers == 1) {
      socket2 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');

      // Invia messaggio di benvenuto
      socket2.add('Connesso');

      startGame();
    }
    else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Endpoint non valido')
        ..close();
    }
  }
}