import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sky_defense/core/router/app_routes.dart';
import 'package:sky_defense/domain/entities/app_language.dart';
import 'package:sky_defense/domain/usecases/get_saved_language_usecase.dart';
import 'package:sky_defense/domain/usecases/set_saved_language_usecase.dart';
import 'package:sky_defense/presentation/screens/game_screen.dart';
import 'package:sky_defense/presentation/screens/home_screen.dart';
import 'package:sky_defense/presentation/screens/settings_screen.dart';
import 'package:sky_defense/presentation/screens/splash_screen.dart';
import 'package:sky_defense/presentation/providers/system_providers.dart';

final appLanguageControllerProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>(
  (Ref ref) => AppLanguageController(
    getSavedLanguageUseCase: ref.watch(getSavedLanguageUseCaseProvider),
    setSavedLanguageUseCase: ref.watch(setSavedLanguageUseCaseProvider),
  ),
);

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (context, state) => const GameScreen(),
      ),
    ],
  );
});

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController({
    required GetSavedLanguageUseCase getSavedLanguageUseCase,
    required SetSavedLanguageUseCase setSavedLanguageUseCase,
  })  : _getSavedLanguageUseCase = getSavedLanguageUseCase,
        _setSavedLanguageUseCase = setSavedLanguageUseCase,
        super(AppLanguage.spanish) {
    _load();
  }

  final GetSavedLanguageUseCase _getSavedLanguageUseCase;
  final SetSavedLanguageUseCase _setSavedLanguageUseCase;
  bool _initialized = false;

  Future<void> _load() async {
    _initialized = true;
    final String code = await _getSavedLanguageUseCase();
    state = AppLanguage.fromCode(code);
  }

  Future<void> ensureLoaded() async {
    if (_initialized) {
      return;
    }
    await _load();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) {
      return;
    }
    state = language;
    await _setSavedLanguageUseCase(language.code);
  }
}
