import 'dart:io';
import 'dart:convert';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String body_text = "";
  Process? process;
  bool isDashboardReady = false;

  AlertDialog? triggerDialog;
  StateSetter? triggerDialogSetState;
  String triggerKeyword = "";

  ScrollController? scrollController;
  _DashboardPageState() {
    scrollController = ScrollController();

    const imageWidget = FlareActor(
      'assets/images/space_demo.flr',
      alignment: Alignment.center,
      fit: BoxFit.cover,
      animation: 'loading',
    );
    const clippedImageWidget = ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      child: imageWidget,
    );
    triggerDialog = AlertDialog(
        backgroundColor: Colors.transparent,
        content: StatefulBuilder(
            builder: (BuildContext contest, StateSetter setDialogState) {
              triggerDialogSetState = setDialogState;
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.6,
                child: Stack(fit: StackFit.passthrough, children: <Widget>[
                  clippedImageWidget,
                  Text("\nHow may I help you?\n\n\n\n\n$triggerKeyword",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 30.0, fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(blurRadius: 5.0, color: Color.fromARGB(255, 0, 0, 0),),
                      ],
                    ),
                  )
                ]),
              );
            }
        )
    );
  }

  Future<void> _triggerWord() {
    // Reset keyword display
    triggerKeyword = "";

    // Then display dialog
    // https://stackoverflow.com/questions/69568862/flutter-showdialog-is-not-shown-on-popupmenuitem-tap
    return Future<void>.delayed(const Duration(milliseconds: 100), () {
      showDialog(
          context: context,
          builder: (_) {
            return triggerDialog ?? const Text("");
          }
      );
    });
  }

  void _triggerAction(String action) {
    if (triggerDialogSetState != null) {
      triggerDialogSetState!.call(() => triggerKeyword = action);
      // Close dialog a while after the keyword is triggered
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        Navigator.pop(context);
      });
    }
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
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem<int>(
                  value: 0,
                  onTap: _triggerWord,
                  child: const Text("Force trigger word"),
                ),
                PopupMenuItem<int>(
                  value: 0,
                  onTap: () {
                    _triggerWord().then((value) => Future<void>.delayed(const Duration(milliseconds: 1000), () => _triggerAction("Lights")));
                  },
                  child: const Text("Force trigger word with action"),
                ),
              ];
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: <Widget> [
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text("Dashboard",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 56.0, fontWeight: FontWeight.w700),
            ),
          ),
          Text(isDashboardReady ? "Listening..." : "Starting process...",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30.0, fontWeight: FontWeight.w700),
          ),
          SizedBox(
              height: 200, width: 800,
              child: isDashboardReady ?
                Lottie.network("https://assets10.lottiefiles.com/private_files/lf30_lv4zofni.json") :
                const Center(child: CircularProgressIndicator())
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
