import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Home',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Content coming soon',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
