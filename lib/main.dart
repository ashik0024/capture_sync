import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/ServiceLocator.dart';
import 'core/storage/hive_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final hiveStorage = HiveStorage();

  await hiveStorage.init();

  // Initialize all application services
  await ServiceLocator.init();

  // Start application
  runApp(
    const CaptureSyncApp(),
  );
}