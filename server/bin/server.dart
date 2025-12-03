import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'card.dart';


const List<String> semi = ["Denari", "Coppe", "Spade", "Bastoni"];
enum Player {player1, player2}


WebSocket? socket1;
  WebSocket? socket2;

  int connectedPlayers = 0;


  Map<int, int> cardPoints = {
      1: 11,
      2: 0,
      3: 10,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
      8: 2,
      9: 3,
      10: 4
  };

  List<int> playerPoints = [0, 0];

  List<Card> cards = [];
  List<List<Card>> mazzi = [[],[]];
  Card? briscola;

  List<dynamic> cardsToConfront = ["", ""];

  int turno = 0;
  bool canPlay = false;
  List<WebSocket> sockets = [];

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

  void chooseTheFirst(){
    turno = Random().nextInt(2);
  }

  void play(){
    //for(int i = 0; i < 6; i++){
      sockets[turno].add(jsonEncode({"message": "your turn"}));
      /*if(turno == 0 && canPlay){
        canPlay = false;
        turno = 1;
      }
      else if(turno == 1 && canPlay){
        canPlay = false;
        turno = 0;
      }*/
    //}
  }

  void setPlayedCard(int player, String seme, int valore){
    cardsToConfront[player] = Card(seme: seme, valore: valore);
  }

  void sendToTheOpponent(int player, String seme, int valore){
    sockets[(player + 1) % 2].add(jsonEncode({"message": "opponent played", "seme": seme, "valore": valore}));
  }

  int makeConfront(){
    Card firstCard = cardsToConfront[0];
    Card secondCard = cardsToConfront[1];

    String semeRiferimento = cardsToConfront[turno].seme;

    if(firstCard.seme == briscola!.seme && secondCard.seme != briscola!.seme){
      playerPoints[0] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
      return 0;
    }
    else if(secondCard.seme == briscola!.seme && firstCard.seme != briscola!.seme){
      playerPoints[1] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
      return 1;
    }
    else if((firstCard.seme == briscola!.seme && secondCard.seme == briscola!.seme)){
      if(cardPoints[firstCard.valore]! > cardPoints[secondCard.valore]!){
        playerPoints[0] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
        return 0;
      }
      else{
        playerPoints[1] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
        return 1;
      }
    }
    else if(firstCard.seme != briscola!.seme && secondCard.seme != briscola!.seme){
      if(firstCard.seme == semeRiferimento && secondCard.seme == semeRiferimento){
        if(cardPoints[firstCard.valore]! > cardPoints[secondCard.valore]!){
          playerPoints[0] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
          return 0;
        }
        else{
          playerPoints[1] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
          return 1;
        }
      }
      if(firstCard.seme == semeRiferimento && secondCard.seme != semeRiferimento){
        playerPoints[0] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
        return 0;
      }
      else if(secondCard.seme == semeRiferimento && firstCard.seme != semeRiferimento){
        playerPoints[1] += cardPoints[firstCard.valore]! + cardPoints[secondCard.valore]!;
        return 1;
      }
    }

    return 0;
  }


  int readyPlayers = 0;

  void listen(WebSocket socket, int player){
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
      else if(data == "cards drawed" && readyPlayers == 2){
        chooseTheFirst();
        print("Turno: $turno");
        canPlay = true;
        play();
        readyPlayers = 0;
      }
      else if(data.toString().startsWith("{")){
        final decodedData = jsonDecode(data);
        if(decodedData['message'] == "card played"){
          setPlayedCard(player, decodedData['seme'], decodedData['valore']);
          sendToTheOpponent(player, decodedData['seme'], decodedData['valore']);
        }
        readyPlayers--; // Non serve contarli
      }
      else if(data == "opponent card received"){
        print(readyPlayers);
        print("Turno ex: $turno");
        turno = (turno + 1) % 2;
        print("Turno: $turno");
        if(readyPlayers == 1){
          canPlay = true;
          //play();
          // return
        }
        else if(readyPlayers == 2){
          int winner = makeConfront();
          turno = winner;
          sockets[winner].add(jsonEncode({"message": "you won"}));
          sockets[(winner + 1) % 2].add(jsonEncode({"message": "you lose"}));
          mazzi[winner].add(cardsToConfront[0]);
          mazzi[winner].add(cardsToConfront[1]);
          readyPlayers = 0;

          print(winner);
          print(playerPoints);
        }

        play();
      }
      else if(data == "confront received" && readyPlayers == 2){
        canPlay = true;
        readyPlayers = 0;
        play();
      }
    });
  }

  void startGame(){
    initCards();
    shuffleCards();

    String jsonInit = jsonEncode({'message': 'init'});
    socket1!.add(jsonInit);
    socket2!.add(jsonInit);

    sockets.add(socket1!);
    sockets.add(socket2!);

    listen(socket1!, 0);
    listen(socket2!, 1);
  }


Future<void> main() async {
  // Avvia il server HTTP sulla porta 8080
  final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server avviato su ws://localhost:8080/ws');



  await for (HttpRequest req in server) {
    // Gestisce solo il percorso /ws
    if (req.uri.path == '/ws' && connectedPlayers == 0) {
      socket1 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');
      socket1!.add('Connesso');
      connectedPlayers++;
    } 
    else if(req.uri.path == '/ws' && connectedPlayers == 1) {
      socket2 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');
      socket2!.add('Connesso');

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