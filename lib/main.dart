import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/storage/hive_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveStorage = HiveStorage();

  await hiveStorage.init();

  runApp(
    const CaptureSyncApp(),
  );
}