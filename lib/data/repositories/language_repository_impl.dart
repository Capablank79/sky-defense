import 'package:sky_defense/data/datasources/language_local_datasource.dart';
import 'package:sky_defense/domain/repositories/language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  const LanguageRepositoryImpl(this._localDataSource);

  final LanguageLocalDataSource _localDataSource;

  @override
  Future<String> getSavedLanguageCode() {
    return _localDataSource.getSavedLanguageCode();
  }

  @override
  Future<void> saveLanguageCode(String code) {
    return _localDataSource.saveLanguageCode(code);
  }
}
