import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizePage extends StatefulWidget {
  static const actions = [
    ['Trigger', Icons.start],
    ['Time', Icons.access_time_outlined],
    ['Date', Icons.date_range],
    ['Weather', Icons.sunny],
    ['Music', Icons.queue_music],
    ['Lights-On', Icons.light_mode],
    ['Lights-Off', Icons.light_mode_outlined],
  ];
  const PersonalizePage({Key? key}) : super(key: key);

  @override
  State<PersonalizePage> createState() => _PersonalizePageState();
}

class _PersonalizePageState extends State<PersonalizePage> {

  SharedPreferences? prefs;
  List<String> keywordList = [];

  _PersonalizePageState() {
    SharedPreferences.getInstance().then((value) {
      setState(() => prefs = value);
    });
    File f = File('keywords.txt');
    f.exists().then((does_exist) {
      if (does_exist) {
        List<String> lines = f.readAsLinesSync();
        lines.removeWhere((line) => line.trim().isEmpty);
        keywordList.addAll(lines);
        print("Found keywords: ${keywordList.toString()}");
      } else {
        print("No keywords found");
      }
    });
  }

  void openDialogForAction(String action) {
    // keywordList
    List<String> associated = getKeywordsAssociated(action);
    print("openDialogForAction: associated->$associated");

    showDialog(context: context, builder: (ctx) {
      return AlertDialog(content: StatefulBuilder(
          builder: (BuildContext contest, StateSetter setDialogState) {
            Widget createPillButton(String text, bool add_remove) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    primary: !add_remove ? Colors.purple : Colors.grey),
                child: Text(text),
                onPressed: () {
                  print("Pill button pressed $text, $add_remove");
                  if (add_remove) {
                    associated.add(text);
                  } else {
                    associated.remove(text);
                  }
                  setKeywordsAssociated(action, associated);
                  setDialogState(() {});
                  setState(() {});
                },
                onLongPress: () {
                  print("Pill button long pressed $text, $add_remove");
                  associated.add(text);
                  setKeywordsAssociated(action, associated);
                  setDialogState(() {});
                  setState(() {});
                }
              );
            }

            Widget createAddKeywordWrapper() {
              List<Widget> _children = [];
              for (String keyword in keywordList) {
                if (!associated.contains(keyword)) {
                  _children.add(createPillButton(keyword, true));
                }
              }
              return Wrap(spacing: 10, runSpacing: 10, children: _children);
            }

            Widget createDeleteKeywordWrapper() {
              List<Widget> _children = [];
              for (String keyword in associated) {
                _children.add(createPillButton(keyword, false));
              }
              return Wrap(spacing: 10, runSpacing: 10, children: _children);
            }

            Widget dialog_interface = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Personalise Your Keywords", style: TextStyle(fontSize: 25)),
                const SizedBox(height: 20),
                createAddKeywordWrapper(),
                const SizedBox(height: 20),
                Card(
                  color: const Color.fromARGB(0xFF, 0xF8, 0xF8, 0xF8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: createDeleteKeywordWrapper(),
                  ),
                ),
              ],
            );
            return dialog_interface;
          }
      ));
    });
  }

  List<Widget> createActionList() {
    const List actions = PersonalizePage.actions;
    List<Widget> widgets = [];
    for (var action in actions) {
      Widget item = Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: Card(
          elevation: 4,
          child: InkWell(
            highlightColor: Colors.purple,
            onTap: () => openDialogForAction(action[0]),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: Text(action[0], style: const TextStyle(fontSize: 24.0)),
              leading: Icon(action[1]),
              //subtitle: Text(''),
              trailing: Text(getKeywordsAssociated(action[0]).join(' | ') ),
            ),
          ),
        ),
      );
      widgets.add(item);
    }
    return widgets;
  }

  List<String> getKeywordsAssociated(String action)  {
    if (prefs == null) return [];
    String keywords = prefs?.getString('pref1_$action') ?? '';
    return keywords.split(' ').where((element) => element.isNotEmpty).toList();
  }

  void setKeywordsAssociated(String action, List<String> keywords) {
    prefs?.setString('pref1_$action', keywords.join(' ')).whenComplete(() {
      print("Updated prefs: ${getKeywordsAssociated(action)}");
    });
  }

  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('PLANET Personalize Model'),
      ),
      backgroundColor: Colors.white,
      body: Column(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: <Widget> [
          Expanded(
            child: SingleChildScrollView(
              //controller: scrollController,
              child: Column(children: createActionList()),
            ),
          ),
        ],
      ),
    );
  }
}
