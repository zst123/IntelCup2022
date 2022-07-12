import 'package:flutter/material.dart';
import 'package:intelcup/PersonalizePage.dart';
import 'package:intelcup/main.dart';
import 'package:process_run/process_run.dart';

import 'DashboardPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text("Intel Cup 2022"),
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset('assets/images/planet_icon.png',
                        height: 180,
                        width: 180,
                        fit: BoxFit.cover),
                  ),
                  Column(children: const [
                    Text("PLANET",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 56.0, fontWeight: FontWeight.w700, color: Colors.purple),
                    ),
                    Text("Personalized, Localized, Artificial Neural Network",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.normal, color: Colors.purple),
                    ),
                  ]),
                ]
            ),

            SizedBox(
              height: 60.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const MyTrainingPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    primary: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical:10),
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                child: const Text('Start Training!'),
              ),
            ),

            const Padding(padding: EdgeInsets.all(16.0)),

            SizedBox(
              height: 60.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const PersonalizePage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    primary: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical:10),
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                child: const Text('Personalise Your Model'),
              ),
            ),

            const Padding(padding: EdgeInsets.all(16.0)),

            SizedBox(
              height: 60.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const DashboardPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    primary: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical:10),
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
                child: const Text('Dashboard'),
              ),
            ),
          ],
        )
    );
  }
}