import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

  Future<bool> _isAndroid12OrHigher() async {
    return true; // Assume modern devices
  }

  Future<void> _requestAndCheckPermissions() async {
    if (mounted) setState(() => _isLoading = true);

    final permissionsToRequest = [
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.ignoreBatteryOptimizations,
      Permission.systemAlertWindow,
    ];

    try {
      await permissionsToRequest.request();
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
    }

    final batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;
    final overlayGranted = await Permission.systemAlertWindow.isGranted;
    final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    final notificationGranted = await Permission.notification.isGranted;

    final checkExactAlarm = await _isAndroid12OrHigher();

    final allGranted = batteryGranted &&
        overlayGranted &&
        notificationGranted &&
        (!checkExactAlarm || exactAlarmGranted);

    if (mounted) setState(() => _isLoading = false);

    if (allGranted) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/splash');
    } else {
      if (mounted) _showPermissionDeniedDialog(context);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
        title: const Text('İzinler Eksik veya Ayar Gerekli'),
        content: const SingleChildScrollView(
          child: Text(
                '⚡️ Özellikle "Pil Optimizasyonu", "Diğer Uygulamaların Üzerinde Gösterme" ve "Kilit Ekranında Gösterme" izinleri ÇOK KRİTİK.\n\n'
                '⚡️ Uygulama ayarlarını açarak(seni yönlendireceğim) eksik izinleri oradan diğer izinler gibi bir başlık altından ver',
            style: TextStyle(height: 1.4),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Ayarları Aç'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Gerekli İzinler'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                ' Uygulamanın Düzgün Çalışması İçin',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Uygulamanın düzgün çalışabilmesi için aşağıdaki izinlere ihtiyaç var:',
                style: TextStyle(fontSize: 15, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildPermissionItem('🔔', 'Bildirimler', 'Alarm hakkında bilgi vermek için.'),
              _buildPermissionItem('⏰', 'Kesin Zamanlı Alarm', '(Android 12+) Zamanında çalabilmesi için.'),
              _buildPermissionItem('🧱', 'Üzerinde Gösterme!!!', 'Kilit ekranında alarm arayüzü göstermek için.'),
              _buildPermissionItem('⚡️', 'Pil Optimizasyonunu Yoksay!!!', 'Gecikmesiz çalışması için.'),

              const Spacer(),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Kontrol et'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: _requestAndCheckPermissions,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async => await openAppSettings(),
                child: const Text('⚙️ Teknik bilgim var, izinleri kendim ayarlayacağım'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
