import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sky_defense/core/storage/hive_service.dart';
import 'package:sky_defense/presentation/providers/system_providers.dart';
import 'package:sky_defense/presentation/widgets/app_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final HiveService hiveService = await HiveService.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        keyValueStorageProvider.overrideWithValue(hiveService),
      ],
      child: const AppRoot(),
    ),
  );
}
