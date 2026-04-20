import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sky_defense/core/config/game_config_provider.dart';
import 'package:sky_defense/core/router/app_routes.dart';
import 'package:sky_defense/presentation/providers/app_providers.dart';
import 'package:sky_defense/presentation/providers/feature_providers.dart';
import 'package:sky_defense/presentation/providers/system_providers.dart';
import 'package:sky_defense/presentation/widgets/app_text.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await ref.read(appLanguageControllerProvider.notifier).ensureLoaded();
    await ref.read(configRuntimeProvider.notifier).load();
    final bool valid = await ref.read(systemValidatorProvider).validate(
          config: ref.read(gameConfigFacadeProvider),
        );
    if (!valid) {
      await ref.read(configRuntimeProvider.notifier).reload();
    }
    await ref.read(playerProvider.notifier).initializeIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppText(
          textKey: 'splash_loading',
          variant: AppTextVariant.heading,
        ),
      ),
    );
  }
}
