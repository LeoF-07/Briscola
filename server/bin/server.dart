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
  List<Card> socket1Mazzo = [];
  List<Card> socket2Mazzo = [];
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


  void drawCards(WebSocket socket){
    List<Card> drawedCards = [];
    for(int i = 0; i < 3; i++){
      drawedCards.add(cards.removeLast());
    }

    String jsonCards = jsonEncode(
      {
        'message': 'drawCards',
        'cards': drawedCards.map((c) => {'seme': c.seme, 'valore': c.valore}).toList()
      }
    );

    socket.add(jsonCards);
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


  int readyPlayers = 0;

  void listen(WebSocket socket){
    socket.listen((data) {
      print(data);
      readyPlayers++;
      if(data == "initialized" && readyPlayers == 2){
        discoverBriscola();
        readyPlayers = 0;
      }
      else if(data == "briscola discovered" && readyPlayers == 2){
          drawCards(socket1!);
          drawCards(socket2!);
          readyPlayers = 0;
      }
    });
  }

  void startGame(){
    initCards();
    shuffleCards();

    String jsonInit = jsonEncode({'message': 'init'});
    socket1!.add(jsonInit);
    socket2!.add(jsonInit);

    listen(socket1);
    listen(socket2);
  }



  await for (HttpRequest req in server) {
    // Gestisce solo il percorso /ws
    if (req.uri.path == '/ws' && connectedPlayers == 0) {
      socket1 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');
      socket1.add('Connesso');
      connectedPlayers++;
    } 
    else if(req.uri.path == '/ws' && connectedPlayers == 1) {
      socket2 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');
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