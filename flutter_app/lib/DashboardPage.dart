import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:intelcup/PersonalizePage.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool triggerDialogOpen = false;
  String triggerKeyword = "";

  ScrollController? scrollController;
  bool nightMode = false;

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

    // Execute once after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startShellProcess();
    });
  }

  void _doTheAction(String action_name) {
    print("_doTheAction: $action_name");

  }

  Future<void> _triggerWord() {
    // Reset keyword display
    triggerKeyword = "";

    // Then display dialog
    // https://stackoverflow.com/questions/69568862/flutter-showdialog-is-not-shown-on-popupmenuitem-tap
    return Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!triggerDialogOpen) {
        triggerDialogOpen = true;
        showDialog(
            context: context,
            builder: (_) {
              return triggerDialog ?? const Text("");
            }
        ).then((value) {
          triggerDialogOpen = false;
        });
      }
    });
  }

  Map<String, String> action_mapping = {};
  void _triggerAction(String action) {
    if (triggerDialogSetState != null) {
      if (action.contains("_#")) { // Indicate end of action words
        triggerDialogSetState!.call(() => triggerKeyword = action.replaceAll("_#", ""));
        // Check the action to be called
        String action_name = action_mapping[triggerKeyword.trim()] ?? "Nothing";
        print("Action call: [$triggerKeyword] -> $action_name");
        _doTheAction(action_name);

        // Close dialog a while after the keyword is triggered
        Future<void>.delayed(const Duration(milliseconds: 1500), () {
          if (triggerDialogOpen) {
            Navigator.pop(context);
          }
        });
      } else {
        triggerDialogSetState!.call(() => triggerKeyword = action);
      }
    }
  }

  Future<void> _killShellProcess() async {
    // taskkill -im python3.10.exe -f
    await (await Process.start('taskkill', ['-im', 'python3.10.exe', '-f'])).exitCode;
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

    // Generate activate_command_list.txt
    var prefs = await SharedPreferences.getInstance();
    String action = PersonalizePage.actions.first[0].toString();
    String triggerWord = prefs.getString('pref1_$action') ?? '';
    File f = File('../scripts/activate_command_list.txt');
    f.writeAsStringSync("$triggerWord\n", mode: FileMode.write);
    print("Wrote to ${f.toString()}: $triggerWord");
    
    // Generate action_command_list.txt
    action_mapping.clear();
    File f2 = File('../scripts/action_command_list.txt');
    f2.writeAsStringSync("", mode: FileMode.write);
    for (var action in PersonalizePage.actions.sublist(1)) {
      String actionWords = prefs.getString('pref1_${action[0]}') ?? '';
      f2.writeAsStringSync("$actionWords\n", mode: FileMode.append);
      print("Wrote to ${f2.toString()}: $actionWords");
      action_mapping[actionWords] = "${action[0]}";
    }
    print("Action mapping: $action_mapping");

    // Force kill existing python processes in case earlier socket was not released
    await _killShellProcess();

    void handleReceivedLine(String line) {
      print("<$line>");
      setState(() => body_text += line);
      // Dashboard is listening
      if (!isDashboardReady) {
        if (line.contains("\$\$ predict start") || line.contains("1/1 [==============================]")) {
          isDashboardReady = true;
          setState(() {});
        }
      }
      // Dashboard trigger word
      if (line.contains("@@ recieve:  #_")) {
        _triggerWord();
      } else if (line.contains("@@ recieve:")) { // Dashboard Action
        String action = line.split('@@ recieve:')[1].split('\$\$')[0].trim();
        _triggerAction(action);
      }
    }

    // Start dashboard manager script
    String workingDirectory = '../scripts/';
    process = await Process.start('python3', ['-u', '../scripts/dashboard_manager.py'], runInShell: true, workingDirectory: workingDirectory);
    process?.stderr
        .transform(utf8.decoder)
        .forEach(handleReceivedLine);
    await process?.stdout
        .transform(utf8.decoder)
        .forEach(handleReceivedLine);

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
                  onTap: () async {
                    await _killShellProcess();
                    setState(() => body_text = "Killed");
                  },
                  child: const Text("Kill dashboard manager"),
                ),
                PopupMenuItem<int>(
                  value: 0,
                  onTap: () => _startShellProcess(),
                  child: const Text("Restart dashboard manager"),
                ),
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
      backgroundColor: nightMode ? const Color.fromARGB(255, 10, 10, 50) : Colors.white,
      body: Column(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: <Widget> [
          Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text("Dashboard",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 56.0, fontWeight: FontWeight.w700, color: nightMode ? Colors.white : Colors.black),
            ),
          ),
          Text(isDashboardReady ? "Listening..." : "Starting process...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w700, color: nightMode ? Colors.white : Colors.black),
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
                child: Text(
                  body_text,
                  style: TextStyle(color: nightMode ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
