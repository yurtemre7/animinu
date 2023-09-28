import 'dart:developer';

import 'package:animinu/class/anime_entry.dart';
import 'package:animinu/main.dart';
import 'package:animinu/screens/settings.dart';
import 'package:animinu/utilities.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends ConsumerStatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  TextEditingController inputController = TextEditingController();

  User get user => ref.read(myUser)!;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    log(user.toString());

    final userData = database.ref().child(user.uid).child('profile');
    var res = await userData.once();
    if (res.snapshot.value != null) {
      var data = res.snapshot.value! as Map<dynamic, dynamic>;
      ref.read(username.notifier).state = data['name'];
      ref.read(email.notifier).state = data['email'];
    }

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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Deine AnimInu Liste',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          leading: Icon(
            Icons.list_alt,
            color: Theme.of(context).colorScheme.primary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'Einstellungen',
              onPressed: () {
                push(context, const Settings());
              },
            ),
          ],
          centerTitle: true,
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              animeEntryInput(),
              Expanded(child: userAnimeList()),
            ],
          ),
        ),
        resizeToAvoidBottomInset: true,
      ),
    );
  }

  Widget userAnimeList() {
    var query = database.ref().child(user.uid).child('anime');
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          getUserData();
        });
      },
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: FirebaseAnimatedList(
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        query: query,
        sort: (a, b) {
          var mapA = a.value as Map<dynamic, dynamic>;
          var mapB = b.value as Map<dynamic, dynamic>;

          return mapA['added'].compareTo(mapB['added']);
        },
        defaultChild: const Center(child: CircularProgressIndicator()),
        itemBuilder: (context, snapshot, animation, index) {
          final data = AnimeEntry.fromSnapshot(snapshot.value);
          return SizeTransition(
            sizeFactor: animation,
            child: Dismissible(
              direction: DismissDirection.endToStart,
              onDismissed: (direction) async {
                FocusScope.of(context).unfocus();
                if (direction == DismissDirection.endToStart) {
                  await database
                      .ref()
                      .child(user.uid)
                      .child('anime')
                      .child(snapshot.key!)
                      .remove();
                }
              },
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
              confirmDismiss: (direction) async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Anime entfernen'),
                    content: Text(
                        'Möchtest du "${data.title}" wirklich aus deiner Liste entfernen?'),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.errorContainer,
                        ),
                        child: Text(
                          'Entfernen',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                      OutlinedButton(
                        child: const Text('Abbruch'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                );
                return result;
              },
              key: Key(snapshot.key!),
              child: animeEntryTile(data, snapshot),
            ),
          );
        },
      ),
    );
  }

  Widget animeEntryInput() {
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
              decoration: const InputDecoration(
                hintText: 'Anime filtern oder hinzufügen..',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              if (inputController.text.isEmpty) {
                return;
              }
              showDialog(
                context: context,
                builder: (context) {
                  TextEditingController currentController =
                      TextEditingController();
                  TextEditingController totalController =
                      TextEditingController();
                  return StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return AlertDialog(
                        title: Text(
                          'Anime hinzufügen',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(inputController.text),
                              const SizedBox(height: 20),
                              Text(
                                'Bei welcher Episode bist du gerade im Anime?',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                              ),
                              TextFormField(
                                controller: currentController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.tertiary),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Wie viele Folgen hat dieser Anime?',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                              ),
                              TextFormField(
                                controller: totalController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.tertiary),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Abbruch'),
                            onPressed: () {
                              pop(context);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                          OutlinedButton(
                            child: const Text('Hinzufügen'),
                            onPressed: () async {
                              await addEntry(
                                entry: AnimeEntry(
                                  title: inputController.text.trim(),
                                  currentEpisode:
                                      int.tryParse(currentController.text) ?? 0,
                                  totalEpisodes:
                                      int.tryParse(totalController.text) ?? 0,
                                  added: DateTime.now(),
                                ),
                              );

                              if (!mounted) return;

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
            },
          ),
        ],
      ),
    );
  }

  Widget animeEntryTile(AnimeEntry data, DataSnapshot snapshot) {
    String txt = inputController.text.toLowerCase().trim();

    if (data.title.toLowerCase().contains(txt) ||
        data.title.toLowerCase().startsWith(txt) ||
        txt.contains(data.title.toLowerCase()) ||
        txt.isEmpty) {
      return ListTile(
        title: Text(
          data.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        subtitle: Text(
          '${data.currentEpisode}/${data.totalEpisodes}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        trailing: Align(
          alignment: Alignment.bottomRight,
          widthFactor: 0,
          child: Text(
            getDate(data.added),
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ),
        onTap: () async {
          FocusScope.of(context).unfocus();
          TextEditingController currentController =
              TextEditingController(text: '${data.currentEpisode}');
          TextEditingController totalController =
              TextEditingController(text: '${data.totalEpisodes}');
          await showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dein Fortschritt',
                        style: TextStyle(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        data.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text('Episode'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 4,
                            child: IconButton(
                              onPressed: () {
                                if (currentController.text != '1') {
                                  setState(() {
                                    currentController.text =
                                        '${int.parse(currentController.text) - 1}';
                                  });
                                }
                              },
                              color: Theme.of(context).colorScheme.primary,
                              icon: const Icon(Icons.remove),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: currentController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    if ((int.tryParse(currentController.text) ??
                                            data.totalEpisodes + 1) >
                                        data.totalEpisodes) {
                                      currentController.text =
                                          '${data.totalEpisodes}';
                                    }
                                  });
                                }
                              },
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: IconButton(
                              onPressed: () {
                                if (currentController.text !=
                                    totalController.text) {
                                  setState(() {
                                    currentController.text =
                                        '${int.parse(currentController.text) + 1}';
                                  });
                                }
                              },
                              icon: const Icon(Icons.add),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Text('Gesamt'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 4,
                            child: IconButton(
                              onPressed: () {
                                if (totalController.text != '1') {
                                  setState(() {
                                    totalController.text =
                                        '${int.parse(totalController.text) - 1}';
                                  });
                                }
                              },
                              color: Theme.of(context).colorScheme.primary,
                              icon: const Icon(Icons.remove),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: totalController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                setState(() {});
                              },
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  totalController.text =
                                      '${int.parse(totalController.text) + 1}';
                                });
                              },
                              icon: const Icon(Icons.add),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      ButtonBar(
                        alignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: const Text('Abbruch'),
                            onPressed: () {
                              pop(context);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                          OutlinedButton(
                            child: const Text('Update'),
                            onPressed: () async {
                              if (currentController.text.isNotEmpty) {
                                await updateEntry(
                                  entry: AnimeEntry(
                                    title: data.title,
                                    currentEpisode:
                                        int.tryParse(currentController.text) ??
                                            0,
                                    totalEpisodes:
                                        int.tryParse(totalController.text) ?? 0,
                                    added: data.added,
                                  ),
                                  key: snapshot.key!,
                                );
                                if (!mounted) return;
                                pop(context);
                              }
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
    return Container();
  }

  String getDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2, 4)}';
  }

  Future<void> addEntry({required AnimeEntry entry}) async {
    await database.ref().child(user.uid).child('anime').push().set({
      'title': entry.title,
      'currentEpisode': entry.currentEpisode,
      'totalEpisodes': entry.totalEpisodes,
      'added': entry.added.millisecondsSinceEpoch,
    });
  }

  Future<void> updateEntry({required AnimeEntry entry, required String key}) async {
    await database.ref().child(user.uid).child('anime').child(key).update({
      'title': entry.title,
      'currentEpisode': entry.currentEpisode,
      'totalEpisodes': entry.totalEpisodes,
      'added': entry.added.millisecondsSinceEpoch,
    });
  }
}
