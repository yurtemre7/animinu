import 'package:animinu/components/Dividers.dart';
import 'package:animinu/main.dart';
import 'package:animinu/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Einstellungen'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ListView(
            children: [
              Consumer(
                builder: (context, watch, child) {
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person_pin_rounded),
                        title: Text('${watch(username).state!}'),
                        onTap: () {
                          TextEditingController controller =
                              TextEditingController(text: context.read(username).state);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Username'),
                              content: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: Text('Abbrechen'),
                                  onPressed: () {
                                    pop(context);
                                  },
                                ),
                                ElevatedButton(
                                  child: Text('Update'),
                                  onPressed: () {
                                    if (controller.text.isNotEmpty) {
                                      // set username in database
                                      final user = context.read(myUser).state;

                                      database.reference().child(user!.uid).child('profile').update({
                                        'name': controller.text.trim(),
                                      });

                                      context.read(username).state = controller.text.trim();
                                    }
                                    pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Dividers.horizontalDivider(),
                      ListTile(
                        trailing: Icon(Icons.email),
                        title: Text(
                          watch(email).state!,
                        ),
                        subtitle: watch(myUser).state != null
                            ? !watch(myUser).state!.emailVerified
                                ? Text(
                                    'Bitte bestätige deine E-Mail.',
                                    style: TextStyle(color: Colors.red),
                                  )
                                : null
                            : null,
                        onTap: watch(myUser).state != null
                            ? !watch(myUser).state!.emailVerified
                                ? () {
                                    context.read(myUser).state!.sendEmailVerification();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Bestätigungsemail wurde versandt. Bitte auch im Spam nachgucken.',
                                        ),
                                      ),
                                    );
                                  }
                                : null
                            : null,
                      ),
                      Dividers.horizontalDivider(),
                    ],
                  );
                },
              ),
              ListTile(
                leading: Icon(isDarkmode(context) ? Icons.light_mode : Icons.dark_mode),
                title: Text('Gibt es einen ${isDarkmode(context) ? 'Lightmode' : 'Darkmode'}?'),
                subtitle: Text(
                    'Ja, du musst dafür dein geräteinternen ${isDarkmode(context) ? 'Lightmode' : 'Darkmode'} aktivieren.'),
              ),
              Dividers.horizontalDivider(),
              ListTile(
                trailing: Icon(Icons.info_outline),
                title: Text('Wer hat diese App gemacht?'),
                subtitle: Text('Emre Yurtseven.'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text('Bitteschön.'),
                    ),
                  );
                },
              ),
              Dividers.horizontalDivider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Log dich aus.'),
                onTap: () async {
                  await auth.signOut();
                  final sp = await SharedPreferences.getInstance();
                  await sp.clear();
                  pop(context);
                },
              ),
              Dividers.horizontalDivider(),
            ],
          ),
        ),
      ),
    );
  }
}
