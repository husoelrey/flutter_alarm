import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper extends StatefulWidget {
  final Widget child;
  const PermissionHelper({super.key, required this.child});

  @override
  State<PermissionHelper> createState() => _PermissionHelperState();
}

class _PermissionHelperState extends State<PermissionHelper> {
  bool _needsPermissions = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final exact   = await Permission.scheduleExactAlarm.isDenied;
    final overlay = await Permission.systemAlertWindow.isDenied;
    final battery = await Permission.ignoreBatteryOptimizations.isDenied;

    setState(() => _needsPermissions = exact || overlay || battery);
  }

  Future<void> _askPermissions() async {
    await [
      Permission.scheduleExactAlarm,
      Permission.systemAlertWindow,
      Permission.ignoreBatteryOptimizations,
      if (await Permission.notification.isDenied) Permission.notification,
    ].request();

    await openAppSettings(); // ayar sayfasına götür!!!!
    await Future.delayed(const Duration(seconds: 2));
    _check();   // geri dönünce tekrar kontrol et!!
  }

  @override
  Widget build(BuildContext context) {
    if (!_needsPermissions) return widget.child;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm, size: 96, color: Colors.deepPurple),
              const SizedBox(height: 24),
              const Text(
                'Aşağıdaki izinleri MUTLAKA açman gerekiyor:',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,

              ),

              const SizedBox(height: 16),
              _bullet('• Bildirim gösterme'),
              _bullet('• Tam zamanlı alarm kurma'),
              _bullet('• Diğer uygulamaların üzerinde gösterme'),
              _bullet('• Pil optimizasyonundan hariç tutma'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _askPermissions,
                child: const Text('İzinleri Ver ve Ayarları Aç'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(String txt) =>
      Align(alignment: Alignment.centerLeft, child: Text(txt));
}
