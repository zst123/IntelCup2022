import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:intelcup/WelcomePage.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_window/desktop_window.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

import 'MyCustomRecorder.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    DesktopWindow.setWindowSize(const Size(800,600));
  }
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
      home: WelcomePage(),
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

  int prefSamplingRate = 16000;
  double prefRecordingTime = 1.0;

  // Audio player
  AudioPlayer player = AudioPlayer();
  int maxduration = 100;
  int currentpos = 0;
  String currentpostlabel = "00:00";
  bool isplaying = false;

  Future updatePreferences({
    int newSamplingRate = -1,
    double newRecordingTime = -1,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (newSamplingRate > 0) await prefs.setInt('prefSamplingRate', newSamplingRate);
    if (newRecordingTime > 0) await prefs.setDouble('prefRecordingTime', newRecordingTime);

    prefSamplingRate = prefs.getInt('prefSamplingRate') ?? 16000;
    prefRecordingTime = prefs.getDouble('prefRecordingTime') ?? 1.0;

    return;
  }

  void _incrementCounter() async {
    bool isRecording = await record.isRecording();
    bool hasPermission = await record.hasPermission();
    await updatePreferences();

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
          startRecording(prefSamplingRate, prefRecordingTime);
        }
      }
      return;
    });
  }

  void stopRecording({int delay = 0}) {
    progress_animation = false;
    status_text = "Recording stopped";
    if (delay > 0) {
      Future.delayed(Duration(milliseconds: delay), () => record.stop());
    } else {
      record.stop();
    }
  }

  void startRecording(int samplingRate, double maxTime) {
    DateTime now = DateTime.now();

    String datetimestring = DateFormat("yyyyMMdd_kkmmss").format(now);
    String filename = fileprefix.isEmpty ?
                      "Keyword-$datetimestring.wav" :
                      "$fileprefix-$datetimestring.wav";

    progress_animation = true;
    status_text = "Recording in progress";
    record.start(
      path: "tmp.wav",
      encoder: AudioEncoder.wav, // by default
      samplingRate: samplingRate,
      maxTime: maxTime, // sec
      //bitRate: 128000, // by default
    );

    // Start timer
    Timer.periodic(
      Duration(milliseconds: (maxTime*1000 - 400).toInt()), (Timer timer) {
      setState(() {
        stopRecording(delay: 400+250);
        timer.cancel();
        File('tmp.wav').rename(filename);

        // Dialog with state
        StateSetter? _setDialogState;

        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
                content: StatefulBuilder(
                    builder: (BuildContext contest, StateSetter setDialogState) {
                      _setDialogState = setDialogState;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Text("Saved to $filename", style: TextStyle(fontSize: 15)),
                          const SizedBox(height: 10),
                          Text(currentpostlabel, style: TextStyle(fontSize: 25)),

                          Slider(
                            value: currentpos.toDouble(),
                            min: 0,
                            max: maxduration.toDouble(),
                            divisions: maxduration,
                            label: currentpostlabel,
                            onChanged: (double value) async {
                              int seekval = value.round();
                              await player.seek(Duration(milliseconds: seekval));
                              currentpos = seekval;
                            },
                          ),
                          Wrap(
                            spacing: 10,
                            children: [
                              ElevatedButton.icon(
                                  onPressed: () {
                                    if(!isplaying){
                                      setDialogState(() {
                                        isplaying = true;
                                        currentpos = 0;
                                        player.play(DeviceFileSource(filename));
                                      });
                                    } else {
                                      player.stop();
                                      setDialogState(() {
                                        isplaying = false;
                                      });
                                    }
                                  },
                                  icon: Icon(isplaying ? Icons.stop : Icons.play_arrow),
                                  label: Text(isplaying ? "Stop" : "Play")
                              ),

                              ElevatedButton.icon(
                                  onPressed: () {
                                    File(filename).delete().whenComplete(() {
                                      Navigator.pop(context);
                                    });
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text("Delete")
                              ),
                            ],
                          )

                        ],
                      );
                    }
                )
            );
          },
        ).then((value) {
          // on closed
          _setDialogState = null;
        });

        // Audio player controller
        maxduration = (maxTime * 1000).toInt(); //get the duration of audio
        StreamSubscription? positionSub;
        positionSub = player.onPositionChanged.listen((Duration  p) {
          // Workaround 1 second resolution in the position change
          // by estimating the time between each callback as 2s00ms
          if (p.inMilliseconds > currentpos) {
            currentpos = p.inMilliseconds;
          } else {
            currentpos += 200;
          }
          currentpos = min(maxduration, currentpos); // don't exceed
          print("onPositionChanged:" + currentpos.toString());
          //generating the duration label
          int sseconds = Duration(milliseconds:currentpos).inSeconds;
          int smillis = Duration(milliseconds:currentpos).inMilliseconds;
          int rseconds = sseconds;
          int rmillis = smillis - rseconds*1000;

          currentpostlabel = "$rseconds.${rmillis.toString().padLeft(2, "0")}";
          if (_setDialogState == null) {
            positionSub?.cancel();
          } else {
            _setDialogState!(() {});
          }
        });
        StreamSubscription? completeSub;
        completeSub = player.onPlayerComplete.listen((event) {
          if (_setDialogState == null) {
            completeSub?.cancel();
          } else {
            _setDialogState!(() {
              isplaying = false;
            });
          }
        });
      });
    },
    );
  }

  void _settingsPane() async {
    await updatePreferences();
    double tempSamplingRate = prefSamplingRate.toDouble();
    double tempRecordingTime = prefRecordingTime;

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Sampling Rate (Hz)'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SpinBox(
                min: 1,
                max: 100000,
                value: tempSamplingRate,
                decimals: 0,
                step: 1,
                onChanged: (double val) => { tempSamplingRate = val },
              ),
            ),
            const Text('Recording Time (sec)'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SpinBox(
                min: 0.1,
                max: 10.0,
                value: tempRecordingTime,
                decimals: 1,
                step: 0.1,
                onChanged: (double val) => { tempRecordingTime = val },
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Save');
              updatePreferences(
                  newSamplingRate: tempSamplingRate.toInt(),
                  newRecordingTime: tempRecordingTime,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _startTrainModel() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("To be implemented"),
          behavior: SnackBarBehavior.floating,
        )
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
      backgroundColor: Colors.white,
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset('assets/images/moon.png',
                  height: 130,
                  width: 130,
                  fit: BoxFit.cover),
            ),
            const Text(
              "Enter keyword for training",
              style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.normal),
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
            Wrap(
              children: [
                ElevatedButton.icon(
                  onPressed: _incrementCounter,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
                  label: const Text('Record'),
                  icon: const Icon(Icons.record_voice_over),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                ElevatedButton.icon(
                  onPressed: _settingsPane,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
                  label: const Text('Settings'),
                  icon: const Icon(Icons.settings),
                ),
              ],
            ),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                    status_text,
                    style: Theme.of(context).textTheme.headline5,
                ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50.0,
          child: (progress_animation ?
            LinearProgressIndicator(value: null) :
            Text("")
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startTrainModel,
        label: Wrap(children: const [Icon(Icons.train), Text(' Train Model')]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
