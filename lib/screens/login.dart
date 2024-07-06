import 'package:animinu/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: loginButtons(context),
    );
  }

  Widget loginButtons(BuildContext context) {
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      buttonPadding: const EdgeInsets.all(20),
      children: [
        TextButton(
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
                animinu.myUser.value = user.user;
                await database.ref().child(user.user!.uid).child('profile').set({
                  'name': emailController.text.trim().split('@')[0],
                  'email': emailController.text.trim(),
                  'uid': user.user!.uid,
                });
                animinu.myUser.value!.sendEmailVerification();
              }).catchError((error) {
                error = error as FirebaseAuthException;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(error.message!),
                ));
              });
            }
          },
          child: const Text(
            'Registrieren',
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) {
              return;
            }
            try {
              var user = await auth.signInWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim(),
              );

              final sp = await SharedPreferences.getInstance();
              sp.setString('email', user.user!.email!);
              sp.setString('passwort', passwordController.text.trim());
              animinu.myUser.value = user.user;
            } on FirebaseAuthException catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(error.message!),
              ));
            }
          },
          child: const Text(
            'Einloggen',
          ),
        ),
      ],
    );
  }

  Widget _emailInput() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deine E-Mail Adresse:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: emailController,
            validator: required,
            onChanged: (value) {},
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              hintText: 'deine@mail.de',
              filled: true,
              border: UnderlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 20),
            autofillHints: const [AutofillHints.username, AutofillHints.email],
          ),
        ],
      ),
    );
  }

  Widget _passwordInput() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dein Passwort:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
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
              border: const UnderlineInputBorder(
                borderSide: BorderSide.none,
              ),
              counter: Text(passwordController.text.length.toString()),
            ),
            style: const TextStyle(fontSize: 20),
            autofillHints: const [AutofillHints.password],
          ),
        ],
      ),
    );
  }

  // valid email checker
  bool validateEmail(String value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
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
