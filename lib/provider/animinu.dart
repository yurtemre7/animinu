import 'package:animinu/class/mal_api.dart';
import 'package:animinu/token.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class AnimInu extends GetxController {
  final myUser = Rxn<User?>(null);
  final username = RxnString(null);
  final email = RxnString(null);

  final animeClient = Rx<MALApi>(
    MALApi(
      accessToken: "",
      clientToken: malClientToken,
    ),
  );

  reset() {
    myUser.value = null;
    username.value = null;
    email.value = null;
  }
}
