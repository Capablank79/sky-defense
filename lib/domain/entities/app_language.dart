import 'dart:ui';

enum AppLanguage {
  spanish('es'),
  english('en');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (AppLanguage value) => value.code == code,
      orElse: () => AppLanguage.spanish,
    );
  }
}
