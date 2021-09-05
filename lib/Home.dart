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
import 'package:shared_preferences/shared_preferences.dart';

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
    getUserData();
  }

  void getUserData() async {
    final userData = database.reference().child('${user.uid}').child('profile');
    userData.once().then((DataSnapshot snapshot) {
      context.read(username).state = snapshot.value['name'];
      context.read(email).state = snapshot.value['email'];
    });

    if (!user.emailVerified) {
      final sp = await SharedPreferences.getInstance();
      auth.signInWithEmailAndPassword(
        email: sp.getString('email') ?? '',
        password: sp.getString('passwort') ?? '',
      );
    }
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
        title: Text('Deine AnimInu Liste'),
        leading: Icon(Icons.list_alt),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Einstellungen',
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
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            children: [
              aentryInput(),
              userAnimeList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget userAnimeList() {
    var query = database.reference().child('${user.uid}').child('anime');
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          getUserData();
        });
      },
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: FirebaseAnimatedList(
        shrinkWrap: true,
        query: query,
        sort: (a, b) => a.value['added'].compareTo(b.value['added']),
        defaultChild: Center(child: CircularProgressIndicator()),
        itemBuilder: (context, snapshot, animation, index) {
          final data = AEntry.fromSnapshot(snapshot.value);
          return SizeTransition(
            child: Dismissible(
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                FocusScope.of(context).unfocus();
                if (direction == DismissDirection.endToStart) {
                  await database
                      .reference()
                      .child('${user.uid}')
                      .child('anime')
                      .child(snapshot.key!)
                      .remove();
                }
              },
              confirmDismiss: (direction) async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Anime entfernen'),
                    content: Text('Möchtest du ${data.title} wirklich aus deiner Liste entfernen?'),
                    actions: [
                      TextButton(
                        child: Text('Abbrechen'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      ElevatedButton(
                        child: Text('Entfernen'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );
                return result;
              },
              key: Key(snapshot.key!),
              child: aentryTile(data, snapshot),
            ),
            sizeFactor: animation,
          );
        },
      ),
    );
  }

  Widget aentryInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextFormField(
              controller: inputController,
              autocorrect: false,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
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
                    TextEditingController currentController = TextEditingController();
                    TextEditingController totalController = TextEditingController();
                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
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
            onLongPress: () {
              FocusScope.of(context).unfocus();
              showDialog(
                context: context,
                builder: (context) {
                  TextEditingController currentController =
                      TextEditingController(text: '${data.currentEpisode}');
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Text('Dein Fortschritt'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${data.title}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: IconButton(
                                        onPressed: () {
                                          if (currentController.text != '1') {
                                            setState(() {
                                              currentController.text =
                                                  '${int.parse(currentController.text) - 1}';
                                            });
                                          }
                                          FocusScope.of(context).unfocus();
                                        },
                                        icon: Icon(Icons.remove)),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: currentController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      maxLength: 4,
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          setState(() {
                                            if ((int.tryParse(currentController.text) ??
                                                    data.totalEpisodes + 1) >
                                                data.totalEpisodes) {
                                              currentController.text = '${data.totalEpisodes}';
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: IconButton(
                                      onPressed: () {
                                        if (currentController.text != '${data.totalEpisodes}') {
                                          setState(() {
                                            currentController.text =
                                                '${int.parse(currentController.text) + 1}';
                                          });
                                        }
                                        FocusScope.of(context).unfocus();
                                      },
                                      icon: Icon(Icons.add),
                                    ),
                                  ),
                                ],
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
                            child: Text('Update'),
                            onPressed: () async {
                              if (currentController.text.isNotEmpty) {
                                await updateEntry(
                                  entry: AEntry(
                                    title: data.title,
                                    currentEpisode: int.tryParse(currentController.text) ?? 0,
                                    totalEpisodes: data.totalEpisodes,
                                    added: data.added,
                                  ),
                                  key: snapshot.key!,
                                );

                                pop(context);
                              }
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
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

  Future<void> updateEntry({required AEntry entry, required String key}) async {
    await database.reference().child('${user.uid}').child('anime').child(key).update({
      'title': entry.title,
      'currentEpisode': entry.currentEpisode,
      'totalEpisodes': entry.totalEpisodes,
      'added': entry.added.millisecondsSinceEpoch,
    });
  }
}
