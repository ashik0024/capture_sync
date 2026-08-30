import 'package:flutter/material.dart';

import '../features/camera/presentation/screens/camera_preview_screen.dart';

class CaptureSyncApp extends StatelessWidget {
  const CaptureSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CaptureSync',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const CameraPreviewScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CaptureSync'),
      ),
      body: const Center(
        child: Text(
          'CaptureSync',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}