import 'package:animinu/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _emailInput(),
                  _passwordInput(),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: !keyboard ? loginButtons(context) : SizedBox(),
    );
  }

  Widget loginButtons(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      buttonPadding: EdgeInsets.all(20),
      children: [
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              await auth
                  .signInWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
              )
                  .then((user) async {
                final sp = await SharedPreferences.getInstance();
                sp.setString('email', user.user!.email!);
                sp.setString('passwort', passwordController.text.trim());
                context.read(myUser).state = user.user;
              }).catchError((error) {
                error = error as FirebaseAuthException;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error.message!),
                ));
              });
            }
          },
          child: Text(
            'Einloggen',
          ),
        ),
        OutlinedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              auth
                  .createUserWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
              )
                  .then((user) async {
                final sp = await SharedPreferences.getInstance();
                sp.setString('email', user.user!.email!);
                sp.setString('passwort', passwordController.text.trim());
                context.read(myUser).state = user.user;
                await database.reference().child(user.user!.uid).child('profile').set({
                  'name': emailController.text.trim().split('@')[0],
                  'email': emailController.text.trim(),
                  'uid': user.user!.uid,
                });
                context.read(myUser).state!.sendEmailVerification();
              }).catchError((error) {
                error = error as FirebaseAuthException;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error.message!),
                ));
              });
            }
          },
          child: Text(
            'Registrieren',
          ),
        ),
      ],
    );
  }

  Widget _emailInput() {
    return Container(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deine E-Mail Adresse:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: emailController,
            validator: required,
            onChanged: (value) {},
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: 'deine@mail.de',
              filled: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _passwordInput() {
    return Container(
      padding: EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dein Passwort:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: passwordController,
            validator: (txt) {
              if ((txt ?? '').isEmpty) {
                return 'Bitte gib dein Passwort ein';
              } else if ((txt ?? '').length < 6) {
                return 'Das Passwort muss mindestens 6 Zeichen lang sein';
              }
              return null;
            },
            obscureText: true,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (value) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: '**********',
              filled: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide.none,
              ),
              counter: Text(passwordController.text.length.toString()),
            ),
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  // valid email checker
  bool validateEmail(String value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    return regex.hasMatch(value);
  }

  String? required(value) {
    if (value.isEmpty) {
      return 'Please enter an e-mail.';
    } else if (!validateEmail(value)) {
      return 'Please enter a valid e-mail.';
    }
    return null;
  }
}
