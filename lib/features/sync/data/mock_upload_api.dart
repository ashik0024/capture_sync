import 'dart:io';

import '../../../core/network/connectivity_service.dart';

class MockUploadApi {
  final ConnectivityService connectivityService;

  bool shouldFail;

  MockUploadApi({
    required this.connectivityService,
    this.shouldFail = false,
  });

  Future<void> uploadImage({
    required File image,
  }) async {
    print('Mock API: Starting upload...');

    // Simulate network latency.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    // Check if the image still exists.
    if (!await image.exists()) {
      throw Exception(
        'Image file does not exist',
      );
    }

    // -----------------------------------------
    // CHECK REAL INTERNET CONNECTION
    // -----------------------------------------

    final hasInternet =
    await connectivityService.hasInternetConnection();

    if (!hasInternet) {
      print(
        'Mock API: No internet connection',
      );

      throw const SocketException(
        'No internet connection',
      );
    }

    // -----------------------------------------
    // SIMULATED SERVER FAILURE
    // -----------------------------------------

    if (shouldFail) {
      print(
        'Mock API: Simulated server failure',
      );

      throw Exception(
        'Mock API: Upload failed',
      );
    }

    // -----------------------------------------
    // MOCK SUCCESS
    // -----------------------------------------

    print(
      'Mock API: Upload successful '
          '${image.path}',
    );
  }
}