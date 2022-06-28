import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String body_text = "";
  Process? process;

  ScrollController? scrollController;
  _DashboardPageState() {
    scrollController = ScrollController();
  }

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

    process?.kill();
    process = null;
  }

  @override
  Widget build(BuildContext context) {
    // Add a one time post frame callback, that scrolls the view to the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController!.animateTo(
          scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 10),
          curve: Curves.linear
      );
    });
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('PLANET User Dashboard'),
      ),
      backgroundColor: Colors.white,
      body: Column(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: <Widget> [
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset('assets/images/saturn.png',
                      height: 180,
                      width: 180,
                      fit: BoxFit.cover),
                ),
                Column(children: const [
                  Text(" Dashboard ",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 56.0, fontWeight: FontWeight.w500),
                  ),
                ]),
              ]
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.fromLTRB(35, 130, 0, 0),
                child: Text(body_text),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Start'),
        onPressed: () {
          _startShellProcess();
        },
      ),
    );
  }
}
