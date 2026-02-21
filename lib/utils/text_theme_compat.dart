import 'package:flutter/material.dart';

extension TextThemeCompat on TextTheme {
  TextStyle? get headline6 => titleLarge;
  TextStyle? get bodyText1 => bodyLarge;
}
