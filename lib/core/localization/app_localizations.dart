import 'package:flutter/material.dart';
import 'package:sky_defense/core/localization/localization_service.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._service);

  final Locale locale;
  final LocalizationService _service;
  late final Map<String, String> _localizedValues;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(localizations != null, 'AppLocalizations not found in context');
    return localizations!;
  }

  Future<void> load() async {
    _localizedValues = await _service.loadTranslations(locale.languageCode);
  }

  String tr(String key) {
    return _localizedValues[key] ?? key;
  }

  String trWithArgs(String key, Map<String, String> args) {
    String value = tr(key);
    for (final MapEntry<String, String> entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate(this._service);

  final LocalizationService _service;

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (Locale supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final AppLocalizations localizations = AppLocalizations(locale, _service);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
