import 'package:animinu/components/separator.dart';
import 'package:animinu/main.dart';
import 'package:animinu/utilities.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () {
            pop(context);
          },
        ),
        title: Text(
          'Einstellungen',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ListView(
            children: [
              Obx(
                () {
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.person_pin_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          animinu.username.value ?? 'Username nicht gefunden.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onTap: () {
                          TextEditingController controller =
                              TextEditingController(text: animinu.username.value);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Username'),
                              content: TextFormField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'Username',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Abbrechen'),
                                  onPressed: () {
                                    pop(context);
                                  },
                                ),
                                OutlinedButton(
                                  child: const Text('Update'),
                                  onPressed: () {
                                    if (controller.text.isNotEmpty) {
                                      // set username in database
                                      final user = animinu.myUser.value;

                                      database.ref().child(user!.uid).child('profile').update({
                                        'name': controller.text.trim(),
                                      });

                                      animinu.username.value = controller.text.trim();
                                    }
                                    pop(context);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Separator.horizontalDivider(),
                      ListTile(
                        trailing: Icon(
                          Icons.email,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          animinu.email.value ?? 'E-Mail nicht gefunden.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        subtitle: animinu.myUser.value != null
                            ? !animinu.myUser.value!.emailVerified
                                ? const Text(
                                    'Bitte bestätige deine E-Mail.',
                                    style: TextStyle(color: Colors.red),
                                  )
                                : null
                            : null,
                        onTap: animinu.myUser.value != null
                            ? !animinu.myUser.value!.emailVerified
                                ? () {
                                    animinu.myUser.value!.sendEmailVerification();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Bestätigungsemail wurde versandt. Bitte auch im Spam nachgucken.',
                                        ),
                                      ),
                                    );
                                  }
                                : null
                            : null,
                      ),
                      Separator.horizontalDivider(),
                    ],
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  isDarkmode(context) ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Gibt es einen ${isDarkmode(context) ? 'Lightmode' : 'Darkmode'}?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                subtitle: Text(
                  'Ja, du musst dafür dein geräteinternen ${isDarkmode(context) ? 'Lightmode' : 'Darkmode'} aktivieren.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              Separator.horizontalDivider(),
              ListTile(
                trailing: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Wer hat diese App gemacht?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                subtitle: Text(
                  'Emre Yurtseven.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Wer hat diese App gemacht?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      content: Text(
                        'Emre Yurtseven.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Separator.horizontalDivider(),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Log dich aus.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onTap: () async {
                  await auth.signOut();
                  final sp = await SharedPreferences.getInstance();
                  await sp.clear();
                  if (!mounted) return;
                  animinu.reset();
                  pop(context);
                },
              ),
              Separator.horizontalDivider(),
            ],
          ),
        ),
      ),
    );
  }
}
