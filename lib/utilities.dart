import 'package:flutter/material.dart';
import 'package:get/get.dart';

void push(Widget page) {
  Get.to(() => page);
}

void pushReplacement(Widget page) {
  Get.off(() => page);
}

void pop() {
  Get.back();
}

bool isDarkmode(context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark;
}
