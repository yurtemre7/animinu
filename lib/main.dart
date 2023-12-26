import 'package:animinu/provider/animinu.dart';
import 'package:animinu/screens/home.dart';
import 'package:animinu/screens/login.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/instance_manager.dart';

final auth = FirebaseAuth.instance;
final database = FirebaseDatabase.instance;
late AnimInu animinu;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  animinu = Get.put(AnimInu());
  animinu.myUser.value = auth.currentUser;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return GetMaterialApp(
        title: 'AnimInu',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightDynamic,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkDynamic,
          brightness: Brightness.dark,
        ),
        home: Obx(
          () => animinu.myUser.value != null ? const Home() : const Login(),
        ),
      );
    });
  }
}
