import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/database_helper.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'pt_BR';
  late AppLocalizations _localizations;

  String get locale => _locale;
  AppLocalizations get localizations => _localizations;

  bool get isEnglish => _locale == 'en';

  LocaleProvider() {
    _localizations = AppLocalizations(_locale);
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final saved = await DatabaseHelper.instance.getSetting('locale');
      if (saved != null && (saved == 'en' || saved == 'pt_BR')) {
        _locale = saved;
        _localizations = AppLocalizations(_locale);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading locale: $e');
    }
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    _locale = locale;
    _localizations = AppLocalizations(_locale);
    notifyListeners();
    try {
      await DatabaseHelper.instance.setSetting('locale', locale);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  Future<void> toggleLocale() async {
    await setLocale(_locale == 'pt_BR' ? 'en' : 'pt_BR');
  }
}
