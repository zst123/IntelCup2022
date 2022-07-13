import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intelcup/main.dart';
import 'package:lottie/lottie.dart';

class ModelTrainingPage extends StatefulWidget {
  const ModelTrainingPage({Key? key}) : super(key: key);

  @override
  State<ModelTrainingPage> createState() => _ModelTrainingPageState();
}

class _ModelTrainingPageState extends State<ModelTrainingPage> {

  double progress_ratio = 0;

  _ModelTrainingPageState() {
    // Execute once after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScripts();
    });
  }
  /*
  Future<void> _stopShellProcess() async {
    if (process != null) {
      process?.kill();
      process = null;
      await process?.exitCode;
    }
    body_text = "";
    setState(() {});
  }

  void _startShellProcess() async {
    await _stopShellProcess();

    // TODO: change to inference process
    //process = await Process.start('ping', ['8.8.8.8']);
    process = await Process.start('python3', ['mic_test.py']);
    process?.stderr
        .transform(utf8.decoder)
        .forEach(print);
    await process?.stdout
        .transform(utf8.decoder)
        .forEach((String line) {
      // Upon receiving the line
      body_text += line;
      print(line);
      setState(() {});
    });
    process

    process?.kill();
    process = null;
  }*/

  Future<void> _startScripts() async {
    print("Starting scripts");

    String workingDirectory = '../scripts/';
    // run following scripts
    // 0. housekeeping
    // 1. audio_preprocessing
    // 2. find_all_keywords
    // 3. v40_notebook
    // 4. mic_test
    setState(() => progress_ratio = 0);

    //-----------------------------------------------------------------------------------
    Process process0 = await Process.start('python3', ['housekeeping.py'], workingDirectory: workingDirectory);
    process0.stdout.transform(utf8.decoder).forEach(print);
    await process0.exitCode;
    setState(() => progress_ratio = 0.1);

    //-----------------------------------------------------------------------------------
    int count1 = 0;
    Process process1 = await Process.start('python3', ['-u', 'audio_preprocessing.py'], workingDirectory: workingDirectory);
    process1.stdout.transform(utf8.decoder).forEach((String line) {
      if (line.contains('Thread starting')) {
        count1 += 1;
      }
      if (line.contains('Thread finishing')) {
        setState(() => progress_ratio += 0.2 / count1);
      }
      print(line);
    });
    process1.stderr.transform(utf8.decoder).forEach(print);
    await process1.exitCode;
    setState(() => progress_ratio = 0.3);

    //-----------------------------------------------------------------------------------
    Process process2 = await Process.start('python3', ['find_all_keywords.py'], workingDirectory: workingDirectory);
    process2.stdout.transform(utf8.decoder).forEach(print);
    process2.stderr.transform(utf8.decoder).forEach(print);
    await process2.exitCode;
    setState(() => progress_ratio = 0.4);

    //-----------------------------------------------------------------------------------
    Process process3 = await Process.start('python3', ['v40_notebook.py'], workingDirectory: workingDirectory);
    process3.stderr.transform(utf8.decoder).forEach(print);
    process3.stdout.transform(utf8.decoder).forEach((String line) {
      if (line.contains('Epoch')) {
        setState(() => progress_ratio += 0.6 / 12);
      }
      print(line);
    });
    await process3.exitCode;
    setState(() => progress_ratio = 1.0);
  }

  void _returnBack() {
    Navigator.pop(context);
    Navigator.push(context,
      MaterialPageRoute(builder: (ctx) => const MyTrainingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rocket animation
    // https://github.com/aashiqumar/Flutter-Animation-Intro/blob/main/lib/animation_1.dart
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('PLANET Training Interface'),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Center(
            child: SizedBox(
                height: 300, width: 800,
                child: progress_ratio < 1 ? Lottie.network("https://assets5.lottiefiles.com/packages/lf20_xiussssy.json") :
                Padding(padding: const EdgeInsets.all(30), child: Image.asset('assets/images/planet_icon.png', fit: BoxFit.contain))
            ),
          ),
          Text(progress_ratio < 1 ? " Generating Your Model " : " Your Model Is Ready",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36.0, fontWeight: FontWeight.w700),
          ),
        ],

      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 50.0,
          child: LinearProgressIndicator(
              value: progress_ratio,
              backgroundColor: const Color.fromARGB(0x18, 0x00, 0x00, 0x00),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (progress_ratio == 1) {
            Navigator.pop(context);
          }
        },
        label: Wrap(children: [const Icon(Icons.repeat), Text(' Progress: ${(progress_ratio * 100).toInt()}%')]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
