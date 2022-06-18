import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';

import 'MyCustomRecorder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.purple,
      ),
      home: const MyTrainingPage(),
    );
  }
}

class MyTrainingPage extends StatefulWidget {
  const MyTrainingPage({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyTrainingPage> createState() => _MyTrainingPageState();
}

class _MyTrainingPageState extends State<MyTrainingPage> {
  String status_text = "Idling";
  bool progress_animation = false;
  final record = MyCustomRecordWindows();
  String fileprefix = "";

  void _incrementCounter() async {
    bool isRecording = await record.isRecording();
    bool hasPermission = await record.hasPermission();
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.

      // Check and request permission
      if (hasPermission) {
        if (!isRecording) {
          // Start recording
          startRecording();
        }
      }
      return;
    });
  }

  void stopRecording() {
    progress_animation = false;
    status_text = "Recording stopped";
    record.stop();
  }

  void startRecording() {
    DateTime now = DateTime.now();
    const double maxTime = 1.5;

    String datetimestring = DateFormat("yyyyMMdd_kkmmss").format(now);
    String filename = fileprefix.isEmpty ?
                      "Keyword-$datetimestring.wav" :
                      "$fileprefix-$datetimestring.wav";

    progress_animation = true;
    status_text = "Recording in progress";
    record.start(
      path: "tmp.wav",
      encoder: AudioEncoder.wav, // by default
      samplingRate: 44100,
      maxTime: maxTime, // sec
      //bitRate: 128000, // by default
    );

    // Start timer
    Timer.periodic(
      Duration(milliseconds: (maxTime*1000 + 250).toInt()), (Timer timer) {
        setState(() {
          stopRecording();
          timer.cancel();
          File('tmp.wav').rename(filename);
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                // Retrieve the text the that user has entered by using the
                // TextEditingController.
                content: Text("Saved to $filename"),
              );
            },
          );

        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('PLANET Training Interface'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Enter keyword for training",
              style: Theme.of(context).textTheme.headline5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child:
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Keyword',
                ),
                onChanged: (text) {
                  fileprefix = text;
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _incrementCounter,
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
              label: const Text('Record'),
              icon: const Icon(Icons.record_voice_over),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                    status_text,
                    style: Theme.of(context).textTheme.headline5,
                ),
            ),
            if (progress_animation) const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 0),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
