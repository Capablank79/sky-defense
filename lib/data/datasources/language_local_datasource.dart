import 'package:sky_defense/core/constants/app_constants.dart';
import 'package:sky_defense/core/storage/preferences_service.dart';

class LanguageLocalDataSource {
  const LanguageLocalDataSource(this._preferencesService);

  final PreferencesService _preferencesService;

  Future<String> getSavedLanguageCode() async {
    return _preferencesService.readString(AppConstants.languageCodeKey) ??
        AppConstants.defaultLanguageCode;
  }

  Future<void> saveLanguageCode(String code) async {
    await _preferencesService.writeString(AppConstants.languageCodeKey, code);
  }
}
