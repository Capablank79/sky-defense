abstract class LanguageRepository {
  Future<String> getSavedLanguageCode();
  Future<void> saveLanguageCode(String code);
}
