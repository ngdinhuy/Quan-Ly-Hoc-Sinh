import 'package:flutter/material.dart';
import 'simple_auth_screen.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Ứng dụng đã load thành công!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nếu bạn thấy màn hình này, có nghĩa là app đã chạy được.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                   MaterialPageRoute(
                    builder: (context) => const SimpleAuthScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Test Google Sign-in'),
            ),
          ],
        ),
      ),
    );
  }
}
