import 'package:briscola/first_page.dart';
import 'package:flutter/material.dart';

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
  void play(){
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => FirstPage(key: UniqueKey(), title: 'FirstPage'))
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/sipario.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              width: 150,
              height: 150,
              margin: EdgeInsets.only(top: 100, bottom: 100),
              child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    "images/logo.png",
                    fit: BoxFit.cover,
                    width: 200,
                    height: 200,
                  )
              ),
            ),
            Align(
                alignment: Alignment.center,
                child: Text("PREMI IL PULSANTE PER GIOCARE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.bold))
            ),
            SizedBox(height: 50),
            Align(
                alignment: Alignment.center,
                child: ElevatedButton(onPressed: play, child: Text("GIOCA"))
            ),
          ],
        ),
      ),
    );
  }
}
