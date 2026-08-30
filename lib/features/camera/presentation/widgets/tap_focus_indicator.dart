import 'package:flutter/material.dart';

class TapToFocusIndicator extends StatelessWidget {
  final Offset position;

  const TapToFocusIndicator({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Colors.yellow, size: 30),
      ),
    );
  }
}
