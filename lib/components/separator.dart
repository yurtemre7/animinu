import 'package:flutter/material.dart';

class Separator {
  static const double horizontal = 1.0;
  static const double vertical = 1.0;

  static Widget horizontalDivider({double thickness = 2.0}) {
    return Divider(
      thickness: thickness,
    );
  }
}
