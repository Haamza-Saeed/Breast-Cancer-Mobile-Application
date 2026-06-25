import 'package:flutter/material.dart';

class LocaleController {
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  static void setLocale(String code) {
    locale.value = Locale(code);
  }
}
