import 'package:flutter/material.dart';
import 'package:kkpchatapp/data/local_storage/local_db_helper.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en', 'US');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final savedLocale = LocalDbHelper.getLocale();
    if (savedLocale != null) {
      _locale = savedLocale;
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await LocalDbHelper.saveLocale(locale);
    notifyListeners();
  }

  Future<void> clearLocale() async {
    _locale = const Locale('en', 'US');
    await LocalDbHelper.clearLocale();
    notifyListeners();
  }
}
