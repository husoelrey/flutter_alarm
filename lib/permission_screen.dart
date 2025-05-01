// lib/permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _requestPermissions(BuildContext context) async {
    final batteryOk = await Permission.ignoreBatteryOptimizations.request().isGranted;
    final overlayOk = await Permission.systemAlertWindow.request().isGranted;

    if (batteryOk && overlayOk) {
      // Ayarlar tamamlandıysa ana ekrana git
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      // Kullanıcı izinleri kapattıysa uyarı göster
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('İzin Gerekli'),
          content: const Text(
              'Uygulamanın düzgün çalışması için gerekli izinleri vermeniz gerekiyor.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tamam'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İzinler')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Uygulamanın düzgün çalışabilmesi için aşağıdaki izinlere ihtiyaç vardır:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              '🔋 Batarya optimizasyonundan muaf tut\n🪟 Diğer uygulamaların üzerinde göster',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _requestPermissions(context),
              child: const Text('İzinleri Ver ve Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}
