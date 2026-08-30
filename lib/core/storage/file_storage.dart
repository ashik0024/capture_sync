import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileStorage {
  Future<Directory> _getImageDirectory() async {
    final directory =
    await getApplicationDocumentsDirectory();

    final imageDirectory = Directory(
      path.join(directory.path, 'captured_images'),
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(
        recursive: true,
      );
    }

    return imageDirectory;
  }

  Future<String> saveImage(
      String sourcePath,
      String fileName,
      ) async {
    final directory = await _getImageDirectory();

    final destinationPath =
    path.join(directory.path, fileName);

    final sourceFile = File(sourcePath);

    final savedFile = await sourceFile.copy(
      destinationPath,
    );

    return savedFile.path;
  }
}