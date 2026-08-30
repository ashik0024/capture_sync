import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveStorage {
  static const String uploadBoxName = 'upload_queue';

  Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox<Map>(
      uploadBoxName,
    );
  }

  Box<Map> get uploadBox {
    return Hive.box<Map>(
      uploadBoxName,
    );
  }
}