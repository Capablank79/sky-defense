import 'package:sky_defense/domain/repositories/language_repository.dart';

class GetSavedLanguageUseCase {
  const GetSavedLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  Future<String> call() {
    return _repository.getSavedLanguageCode();
  }
}
