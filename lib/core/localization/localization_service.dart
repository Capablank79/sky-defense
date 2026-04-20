import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sky_defense/core/constants/app_constants.dart';

class LocalizationService {
  const LocalizationService();

  Future<Map<String, String>> loadTranslations(String languageCode) async {
    final Map<String, String> en = await _loadSingleLanguage(
      'en',
    );
    if (languageCode == 'en') {
      return en;
    }

    final Map<String, String> requested = await _loadSingleLanguage(languageCode);
    return <String, String>{
      ...en,
      ...requested,
    };
  }

  Future<Map<String, String>> _loadSingleLanguage(String languageCode) async {
    try {
      final String raw = await rootBundle.loadString(
        'assets/lang/$languageCode.json',
        cache: true,
      );
      final Map<String, dynamic> decoded =
          json.decode(raw) as Map<String, dynamic>;
      return decoded.map(
        (String key, dynamic value) => MapEntry(key, value.toString()),
      );
    } catch (error) {
      debugPrint('LocalizationService._loadSingleLanguage failed for $languageCode: $error');
      if (languageCode == AppConstants.defaultLanguageCode) {
        return const <String, String>{};
      }
      return _loadSingleLanguage(AppConstants.defaultLanguageCode);
    }
  }
}
