import 'package:sky_defense/domain/repositories/language_repository.dart';

class SetSavedLanguageUseCase {
  const SetSavedLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  Future<void> call(String code) {
    return _repository.saveLanguageCode(code);
  }
}
