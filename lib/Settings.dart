import 'package:animinu/components/Dividers.dart';
import 'package:animinu/main.dart';
import 'package:animinu/utilities.dart';
import 'package:flutter/material.dart';
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
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ListView(
            children: [
              ListTile(
                leading: Icon(isDarkmode(context) ? Icons.light_mode : Icons.dark_mode),
                title: Text('Gibt es einen ${isDarkmode(context) ? 'Lightmode' : 'Darkmode'}?'),
                subtitle: Text(
                    'Ja, du musst dafür dein geräteinternen ${isDarkmode(context) ? 'Lightmode' : 'Darkmode'} aktivieren.'),
              ),
              Dividers.horizontalDivider(),
              ListTile(
                trailing: Icon(Icons.person),
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
                  sp.clear();
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
