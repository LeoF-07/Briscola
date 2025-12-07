import 'dart:io';
import 'game_session.dart';


WebSocket? socket1;
WebSocket? socket2;

int connectedPlayers = 0;

Future<void> main() async {
  // Avvia il server HTTP sulla porta 8080
  final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server avviato su ws://localhost:8080/ws');

  await for (HttpRequest req in server) {
    print('Richiesta ricevuta: ${req.uri.path} da ${req.connectionInfo?.remoteAddress}');
    // Gestisce solo il percorso /ws
    if (req.uri.path == '/ws' && connectedPlayers == 0) {
      print("Tentativo di upgrade...");
      socket1 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');
      socket1!.add('Connesso');
      connectedPlayers++;
    } 
    else if(req.uri.path == '/ws' && connectedPlayers == 1) {
      socket2 = await WebSocketTransformer.upgrade(req);
      print('Nuovo client collegato');
      socket2!.add('Connesso');

      //startGame();


      connectedPlayers = 0;
      GameSession(socket1: socket1, socket2: socket2);
    }
    else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..write('Endpoint non valido')
        ..close();
    }
  }
}