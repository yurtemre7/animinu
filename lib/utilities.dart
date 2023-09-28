import 'package:flutter/material.dart';

void push(context, view) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => view));
}

void pushReplacement(context, view) {
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => view));
}

void pop(context) {
  Navigator.pop(context);
}

bool isDarkmode(context) {
  return MediaQuery.of(context).platformBrightness == Brightness.dark;
}
