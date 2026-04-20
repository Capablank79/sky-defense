import 'package:flutter/material.dart';
import 'package:sky_defense/core/theme/app_spacing.dart';
import 'package:sky_defense/presentation/widgets/app_container.dart';
import 'package:sky_defense/presentation/widgets/app_text.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          textKey: 'game_title',
          variant: AppTextVariant.heading,
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AppContainer(
          elevationPreset: AppContainerElevation.low,
          child: AppText(
            textKey: 'game_placeholder',
            variant: AppTextVariant.body,
          ),
        ),
      ),
    );
  }
}
