import 'package:animinu/Settings.dart';
import 'package:animinu/class/AEntry.dart';
import 'package:animinu/components/Dividers.dart';
import 'package:animinu/main.dart';
import 'package:animinu/utilities.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final User user;
  TextEditingController inputController = TextEditingController();

  @override
  void initState() {
    super.initState();

    user = context.read(myUser).state!;

    print(user);
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        leading: Icon(Icons.home),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              push(context, Settings());
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              aentryInput(),
              Expanded(
                child: FirebaseAnimatedList(
                  query: database.reference().child('${user.uid}').child('anime'),
                  sort: (a, b) => a.value['added'].compareTo(b.value['added']),
                  itemBuilder: (context, snapshot, animation, index) {
                    final data = AEntry.fromSnapshot(snapshot.value!);
                    return SizeTransition(
                      child: aentryTile(data, snapshot),
                      sizeFactor: animation,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container aentryInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextFormField(
              controller: inputController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Anime filtern oder hinzufügen..',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              if (inputController.text.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        TextEditingController currentController = TextEditingController();
                        TextEditingController totalController = TextEditingController();

                        return AlertDialog(
                          title: Text('Anime hinzufügen'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${inputController.text}'),
                                SizedBox(height: 20),
                                Text('Bei welcher Episode bist du gerade im Anime?'),
                                TextFormField(
                                  controller: currentController,
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: 20),
                                Text('Wie viele Folgen hat dieser Anime?'),
                                TextFormField(
                                  controller: totalController,
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Abbruch'),
                              onPressed: () {
                                pop(context);
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            ElevatedButton(
                              child: Text('Hinzufügen'),
                              onPressed: () async {
                                await addEntry(
                                  entry: AEntry(
                                    title: inputController.text.trim(),
                                    currentEpisode: int.tryParse(currentController.text) ?? 0,
                                    totalEpisodes: int.tryParse(totalController.text) ?? 0,
                                    added: DateTime.now(),
                                  ),
                                );

                                pop(context);
                                setState(() {
                                  inputController.clear();
                                });
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget aentryTile(AEntry data, DataSnapshot snapshot) {
    String txt = inputController.text.toLowerCase().trim();

    if (data.title.toLowerCase().contains(txt) ||
        data.title.toLowerCase().startsWith(txt) ||
        txt.contains(data.title.toLowerCase()) ||
        txt.isEmpty) {
      return Column(
        children: [
          ListTile(
            title: Text(
              data.title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${data.currentEpisode}/${data.totalEpisodes}',
            ),
            trailing: Align(
              alignment: Alignment.bottomRight,
              widthFactor: 0,
              child: Text(
                getDate(data.added),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            onLongPress: () {
              print(snapshot.key);
              deleteAEntry(snapshot.key!);
              FocusScope.of(context).unfocus();
            },
          ),
          Dividers.horizontalDivider(),
        ],
      );
    }
    return Container();
  }

  String getDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2, 4)}';
  }

  Future<void> addEntry({required AEntry entry}) async {
    await database.reference().child('${user.uid}').child('anime').push().set({
      'title': entry.title,
      'currentEpisode': entry.currentEpisode,
      'totalEpisodes': entry.totalEpisodes,
      'added': entry.added.millisecondsSinceEpoch,
    });
  }

  void deleteAEntry(String key) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Löschen'),
          content: Text('Möchtest du den Anime wirklich aus deiner Liste entfernen?'),
          actions: [
            TextButton(
              child: Text('Abbruch'),
              onPressed: () {
                pop(context);
              },
            ),
            ElevatedButton(
              child: Text('Löschen'),
              onPressed: () async {
                await database.reference().child('${user.uid}').child('anime').child(key).remove();
                pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
