import 'dart:io';
import 'dart:math';

class MockUploadApi {
  final Random _random = Random();

  Future<void> uploadImage({
    required File image,
  }) async {
    // Simulate network latency.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!await image.exists()) {
      throw Exception(
        'Image file does not exist',
      );
    }

    // -----------------------------------------
    // MOCK RESPONSE
    // -----------------------------------------
    //
    // 0 = success
    // 1 = failure
    //
    // Change this to control testing.
    //
    final shouldFail = _random.nextBool();

    if (shouldFail) {
      throw Exception(
        'Mock API: Upload failed',
      );
    }

    print(
      'Mock API: Upload successful '
          '${image.path}',
    );
  }
}