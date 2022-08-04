import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:intelcup/PersonalizePage.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<String> body_text = [];
  Process? process;
  bool isDashboardReady = false;

  AlertDialog? triggerDialog;
  StateSetter? triggerDialogSetState;
  bool triggerDialogOpen = false;
  String triggerKeyword = "";

  ScrollController? scrollController;
  bool nightMode = false;
  bool consoleViewEnabled = true;

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

  void showSnackbar(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 10), content: Text(text))
      );
    }
  }

  Process? tts_process;
  void _readTTS(String text) async {
    print("** Read TTS: $text");
    String workingDirectory = '../Intel_Cup_voice_feedback/';

    // For first run, start the process
    if (tts_process == null) {
      tts_process = await Process.start('python3', ['-u', 'text_to_speech.py'], runInShell: false, workingDirectory: workingDirectory);
      tts_process?.exitCode.then((value) {
        // Upon process exiting, delete reference to object to prevent memory leak
        tts_process = null;
      });
    }

    // Subsequent runs, read the text
    tts_process?.stdin.writeln(text);

    // Show snackbar label
    showSnackbar(text);
  }

  bool musicPlaying = false;
  int musicVolume = 0;
  Process? music_process;
  void _playMusic() async {
    print("** Play Music");
    String workingDirectory = '../Intel_Cup_voice_feedback/';

    // For first run, start the process
    if (music_process == null) {
      music_process = await Process.start('python3', ['-u', 'play_music.py'], runInShell: false, workingDirectory: workingDirectory);
      musicVolume = 50;
      musicPlaying = true;
      music_process?.exitCode.then((value) {
        // Upon process exiting, delete reference to object to prevent memory leak
        music_process = null;
        musicPlaying = false;
      });
    }

    // Subsequent runs, play the music
    musicPlaying = true;
    music_process?.stdin.writeln("-3"); // -3 = play
    await music_process?.stdin.flush();


    // Show snackbar label
    showSnackbar("Playing music");
  }
  void _pauseMusic() async {
    if (music_process != null) {
      music_process?.stdin.writeln("-2"); // -2 = pause
      await music_process?.stdin.flush();
      musicPlaying = false;
    }
    showSnackbar("Stopping music");
  }
  void _increaseMusic() async {
    if (music_process != null) {
      musicVolume += 10;
      if (musicVolume > 100) musicVolume = 100;
      music_process?.stdin.writeln("$musicVolume");
      await music_process?.stdin.flush();
    }
    showSnackbar("Increasing music volume");
  }
  void _decreaseMusic() async {
    if (music_process != null) {
      musicVolume -= 10;
      if (musicVolume < 0) musicVolume = 0;
      music_process?.stdin.writeln("$musicVolume");
      await music_process?.stdin.flush();
    }
    showSnackbar("Decrease music volume");
  }

  void _handleMusicDuringTrigger(bool dialogShowing) async {
    if (dialogShowing) {
      // Lower
      if (music_process != null) {
        //music_process?.stdin.writeln("-2"); // -2 = pause
        music_process?.stdin.writeln("30"); // temporarily reduce volume
      }
    } else {
      if (music_process != null) {
        //music_process?.stdin.writeln("-3"); // -3 = play
        music_process?.stdin.writeln("$musicVolume"); // set back to original volume
      }
    }
  }

  void _doTheAction(String action_name) async {
    print("_doTheAction: $action_name");
    String workingDirectory = '../Intel_Cup_voice_feedback/';

    if (action_name == 'Trigger') {
      _readTTS("How may I help you?");
    } else if (action_name == 'Lights') {
      setState(() => nightMode = !nightMode);
      _readTTS("Switching the lights");
    } else if (action_name == 'Lights-On') {
      setState(() => nightMode = false);
      _readTTS("Turning on the lights");
    } else if (action_name == 'Lights-Off') {
      setState(() => nightMode = true);
      _readTTS("Turning off the lights");
    } else if (action_name == 'Time') {
      String formattedTime = DateFormat('hh:mm a').format(DateTime.now());
      _readTTS("The time now is $formattedTime");
    } else if (action_name == 'Date') {
      String formattedDate = DateFormat('dd MMMM yyyy ').format(DateTime.now());
      _readTTS("Today's date is $formattedDate");
    } else if (action_name == 'Weather') {
      Process.start('python3', ['-u', 'weather_report.py'], runInShell: false, workingDirectory: workingDirectory).then((pr) {
        pr.stdout.transform(utf8.decoder).forEach((line) {
          if (line.trim().isNotEmpty) {
            _readTTS("$line");
          }
        });
      });
    } else if (action_name == 'Temperature') {

    } else if (action_name == 'Music-Start') {
      _playMusic();
    } else if (action_name == 'Music-Stop') {
      _pauseMusic();
    } else if (action_name == 'Music-VolumeUp') {
      _increaseMusic();
    } else if (action_name == 'Music-VolumeDown') {
      _decreaseMusic();
    } else {
      _readTTS("Unknown action");
    }
  }

  Future<void> _triggerWord() {
    // Reset keyword display
    triggerKeyword = "";

    // Then display dialog
    // https://stackoverflow.com/questions/69568862/flutter-showdialog-is-not-shown-on-popupmenuitem-tap
    return Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!triggerDialogOpen) {
        _doTheAction("Trigger");
        _handleMusicDuringTrigger(true);
        triggerDialogOpen = true;
        showDialog(
            context: context,
            builder: (_) {
              return triggerDialog ?? const Text("");
            }
        ).then((value) {
          _handleMusicDuringTrigger(false);
          triggerDialogOpen = false;
          triggerDialogSetState = null;
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

  void _triggerClose() {
    print("_triggerClose");
    if (triggerDialogOpen) {
      Navigator.pop(context);
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
    body_text.clear();
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

    int handleCount = 0;
    void handleReceivedLine(String line) {
      print("<${line.trim()}>");

      /// Limit max console length to 300 lines
      if (body_text.length > 300) {
        body_text.removeAt(0);
      }
      body_text.add(line);

      // Dashboard is listening
      if (!isDashboardReady) {
        if (line.contains("\$\$ predict start") || line.contains("1/1 [==============================]")) {
          isDashboardReady = true;
        }
        setState(() {});
      } else {
        // During inference, update state every alternate line to reduce lag
        handleCount += 1;
        if (handleCount == 3) {
          handleCount = 0;
          setState(() {});
        }
      }
      // Dashboard trigger word
      if (line.contains("@@ recieve:  #_")) {
        _triggerWord();
      } else if (line.contains("\$_timeout_\$")) { // Dashboard Close Dialog
        _triggerClose();
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

  }

  @override
  Widget build(BuildContext context) {
    // Add a one time post frame callback, that scrolls the view to the bottom
    if (consoleViewEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollController!.jumpTo(scrollController!.position.maxScrollExtent);
      });
    }
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('PLANET User Dashboard'),
        actions: [
          FlatButton(
            textColor: Colors.white,
            onPressed: () {},
            child: Text("$musicVolume%"),
            shape: CircleBorder(side: BorderSide(color: Colors.transparent)),
          ),
          IconButton(
            onPressed: () {
              if (!musicPlaying) {
                _playMusic();
              } else {
                _pauseMusic();
              }
            },
            icon: musicPlaying ? const Icon(Icons.music_note) : const Icon(Icons.music_off),
            tooltip: "$musicVolume%",
          ),

          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem<int>(
                  value: 0,
                  onTap: () async {
                    await _killShellProcess();
                    setState(() => body_text.add("Killed"));
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
                  onTap: () => consoleViewEnabled = !consoleViewEnabled,
                  child: const Text("Toggle console view"),
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
        leading: BackButton(
          onPressed: () {
            // Kill python processes automatically upon exiting
            _killShellProcess();
            Navigator.pop(context);
          },
        ),
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
          if (consoleViewEnabled) Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Container(
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.fromLTRB(35, 130, 0, 0),
                child: Text(
                  body_text.join(""),
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
