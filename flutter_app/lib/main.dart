import 'dart:async';

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
      home: const MyHomePage(title: 'PLANET Training Interface'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String status_text = "Idling";
  double? progress_animation = null;
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
    progress_animation = 0;
    status_text = "Recording stopped";
    record.stop();
  }

  void startRecording() {
    DateTime now = DateTime.now();
    String datetimestring = DateFormat("yyyyMMdd_kkmmss").format(now);
    String filename = fileprefix.isEmpty ?
                      "keyword-$datetimestring.wav":
                      "$fileprefix-$datetimestring.wav";

    progress_animation = null;
    status_text = "Recording in progress";
    record.start(
      path: './$filename.wav',
      encoder: AudioEncoder.wav, // by default
      samplingRate: 44100,
      maxTime: 5000, // ms
      //bitRate: 128000, // by default
    );

    // Start timer
    Timer.periodic(
      const Duration(milliseconds: 1100), (Timer timer) {
        setState(() {
          stopRecording();
          timer.cancel();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                // Retrieve the text the that user has entered by using the
                // TextEditingController.
                content: Text("Saved to $filename.wav"),
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
        title: Text(widget.title),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            Text(
              status_text,
              style: Theme.of(context).textTheme.headline5,
            ),
            LinearProgressIndicator(
              minHeight: 5,
              value: progress_animation,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Record',
        child: const Icon(Icons.audio_file_outlined),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
