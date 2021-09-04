import 'package:animinu/Home.dart';
import 'package:animinu/Login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auth = FirebaseAuth.instance;
final database = FirebaseDatabase.instance;
final myUser = StateProvider<User?>((ref) {});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimInu',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      darkTheme: ThemeData.dark(),
      home: Loading(),
    );
  }
}

class Loading extends StatefulWidget {
  Loading({Key? key}) : super(key: key);

  @override
  _LoadingState createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      if (mounted) {
        auth.userChanges().listen((user) {
          context.read(myUser).state = user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, child) {
        return watch(myUser).state != null ? Home() : Login();
      },
    );
  }
}
