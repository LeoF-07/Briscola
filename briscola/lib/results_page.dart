import 'package:briscola/main.dart';
import 'package:flutter/material.dart';

import 'game_card.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, required this.title, required this.decodedServerMessage});

  final String title;
  final Map<String, dynamic> decodedServerMessage;

  @override
  State<ResultsPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultsPage> {
  List<dynamic> myCards = [];
  List<GlobalKey<GameCardState>> myKeyCardsState = [];
  List<Map<String, dynamic>> myCardsDetails = [];
  List<GameCard> opponentCards = [];
  List<GlobalKey<GameCardState>> opponentKeyCardsState = [];
  List<int> punteggiMieCarte = [];
  List<int> punteggiCarteAvversario = [];


  TextStyle stileIndicatore = TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold);


  num mioPunteggio = 0; // card['punteggio'] è un num
  num punteggioAvversario = 0;

  @override
  void initState() {
    super.initState();
    myCards = widget.decodedServerMessage['yourCards'];
    for (var card in myCards) {
      punteggiMieCarte.add(card['punteggio']);
      myCardsDetails.add({'seme': card['seme'], 'valore': card['valore']});
      mioPunteggio += card['punteggio'];
    }
  }

  void showResults(){
    for (int i = 0; i < myCards.length; i++) {
      myKeyCardsState.add(GlobalKey<GameCardState>());
    }
    setState(() {
      show = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < myKeyCardsState.length; i++) {
        final st = myKeyCardsState[i].currentState;
        if (st != null) {
          st.setFrontPath(myCardsDetails[i]['seme'], myCardsDetails[i]['valore']);
          st.setVisible(true);
        }
      }
    });
  }

  void restart(){
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(key: UniqueKey(), title: 'FirstPage'))
    );
  }

  bool show = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> rowsOfCards = [];

    for (int i = 0; i < (myKeyCardsState.length / 6).ceil(); i++) {
      List<Widget> cardsInARow = [];
      for (int j = 0, cardIndex = i * 6; j < 6 && cardIndex < myKeyCardsState.length; j++, cardIndex++){
        cardsInARow.add(
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameCard(key: myKeyCardsState[cardIndex],
                      width: 50,
                      height: 100
                  ),
                  Text("${punteggiMieCarte[cardIndex]}", style: stileIndicatore)
                ]
            )
          )
        );
      }

      rowsOfCards.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cardsInARow,
          )
      );
    }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...rowsOfCards,
            SizedBox(height: 30),
            !show ?
              ElevatedButton(onPressed: showResults, child: Text("Mostra i risultati")) :
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Hai totalizzato un punteggio di $mioPunteggio punti", style: stileIndicatore,),
                  (widget.decodedServerMessage['result'] == 'you won') ?
                    Text("Hai vinto", style: stileIndicatore) :
                    (widget.decodedServerMessage['result'] == 'you lost') ?
                      Text("Hai perso", style: stileIndicatore) :
                      Text("Pareggio", style: stileIndicatore),
                  SizedBox(height: 30),
                  ElevatedButton(onPressed: restart, child: Text("Torna alla schermata home"))
                ]
              )
          ]
        ),
      ),
    );
  }

}