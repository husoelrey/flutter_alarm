// lib/permission_screen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform; // Platform kontrolü için
import 'package:flutter/material.dart'; // Bu satır MUTLAKA olmalı
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

// Ekranın durumunu yönetmek için StatefulWidget'a dönüştürüyoruz
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false; // İzin isteme sırasında yükleme durumu

  // Android S (API 31) veya üstü olup olmadığını kontrol etme
  // (scheduleExactAlarm izninin gerekli olup olmadığını belirlemek için)
  // Not: Bu kontrol daha sağlam yapılabilir (device_info_plus gibi)
  // ama permission_handler zaten bu izni sadece S+ için yönetir.
  Future<bool> _isAndroid12OrHigher() async {
    // Şimdilik basitçe true dönüyoruz, modern cihazları hedeflediğimizi varsayarak.
    // Eğer eski sürümleri de desteklemek kritikse, buraya daha iyi bir kontrol eklenmeli.
    return true;
  }

  // Gerekli tüm izinleri isteyen ve sonucu kontrol eden fonksiyon
  Future<void> _requestAndCheckPermissions() async {
    // Butona basıldığında yükleme göstergesini başlat
    if (mounted) {
      setState(() { _isLoading = true; });
    }

    // İstenmesi gereken tüm izinlerin listesi
    List<Permission> permissionsToRequest = [
      Permission.notification, // Android 13+
      Permission.scheduleExactAlarm, // Android 12+
      // Batarya ve Overlay izinleri genellikle request() ile direkt verilemez,
      // Ayarlara yönlendirme daha mantıklıdır. Ama yine de isteyelim, belki bazı cihazlarda çalışır.
      Permission.ignoreBatteryOptimizations,
      Permission.systemAlertWindow,
    ];

    // İzinleri iste (kullanıcıya sistem diyalogları gösterilecek)
    // ignoreBatteryOptimizations ve systemAlertWindow için request() genellikle doğrudan
    // ayarlar sayfasını açar veya bir hata döndürebilir.
    Map<Permission, PermissionStatus> statuses = {};
    try {
      statuses = await permissionsToRequest.request();
      debugPrint("Permission request statuses: $statuses");
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
      // Özellikle overlay/battery izinleri için hata olabilir
    }


    // İzin isteme işlemi bittikten sonra durumları tekrar kontrol et
    final bool notificationGranted = await Permission.notification.isGranted;
    final bool exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    final bool batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;
    final bool overlayGranted = await Permission.systemAlertWindow.isGranted;

    final bool checkExactAlarm = await _isAndroid12OrHigher();

    // Tüm GEREKLİ izinler verilmiş mi?
    // Batarya ve Overlay izinleri manuel ayar gerektirebileceği için
    // ilk denemede verilmemiş olsa bile kullanıcıyı ayarlara yönlendirebiliriz.
    // Şimdilik hepsinin verilmiş olmasını bekleyelim.
    final bool allRequiredGranted = notificationGranted &&
        batteryGranted &&
        overlayGranted &&
        (!checkExactAlarm || exactAlarmGranted);

    debugPrint("Permission Status (after request): Battery=$batteryGranted, Overlay=$overlayGranted, ExactAlarm=$exactAlarmGranted, Notification=$notificationGranted");
    debugPrint("All required permissions granted (after request): $allRequiredGranted");

    // Yükleme göstergesini durdur
    if (mounted) {
      setState(() { _isLoading = false; });
    }


    // Sonucu değerlendir
    if (allRequiredGranted) {
      // Tüm izinler verildiyse ana sayfaya yönlendir ve bu ekranı kapat
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } else {
      // İzinlerden en az biri verilmediyse kullanıcıyı bilgilendir
      // ve ayarlara gitmesi için bir seçenek sun
      if (mounted) {
        _showPermissionDeniedDialog(context);
      }
    }
  }

  // İzinler reddedildiğinde veya manuel ayar gerektiğinde gösterilecek dialog
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Dialog dışına tıklayarak kapatmayı engelle
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
        title: const Text('İzinler Eksik veya Ayar Gerekiyor'),
        content: const SingleChildScrollView( // Uzun metinler için kaydırma ekle
          child: Text(
            'Alarmların güvenilir bir şekilde çalışabilmesi için tüm izinlerin verilmesi önemlidir.\n\n'
                'Özellikle "Pil Optimizasyonunu Yoksay" ve "Diğer Uygulamaların Üzerinde Göster" izinleri için uygulama ayarlarına gitmeniz gerekebilir.\n\n'
                'Lütfen uygulama ayarlarını açıp eksik izinleri kontrol edin.',
            style: TextStyle(height: 1.4), // Satır aralığı
          ),
        ),
        actionsAlignment: MainAxisAlignment.center, // Butonları ortala
        actions: [
          TextButton(
            child: const Text('Tamam'),
            onPressed: () => Navigator.of(ctx).pop(), // Sadece dialogu kapat
          ),
          ElevatedButton.icon( // Ayarları aç butonu daha belirgin olsun
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Ayarları Aç'),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Dialogu kapat
              await openAppSettings(); // Uygulama ayarlarını aç
              // Kullanıcı ayarlardan geri döndüğünde durumu tekrar kontrol etmek
              // için bir mekanizma eklenebilir (örn: WidgetsBindingObserver)
              // ama şimdilik basit tutuyoruz.
            },
          ),
        ],
      ),
    );
  }


  // --- Build Metodu ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerekli İzinler'),
        automaticallyImplyLeading: false, // Geri butonu olmasın
        backgroundColor: Colors.transparent, // Arka planla uyumlu
        elevation: 0, // Gölge olmasın
        centerTitle: true,
      ),
      body: SafeArea( // Ekran çentikleri vb. için güvenli alan
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // İçeriği dikeyde ortala
            crossAxisAlignment: CrossAxisAlignment.stretch, // Butonlar genişlesin
            children: [
              const Icon(Icons.shield, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 24),
              const Text(
                'Güvenilir Alarmlar İçin',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Uygulamanın arka planda ve kilit ekranında bile alarmları doğru zamanda çalabilmesi için aşağıdaki izinler gereklidir:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              // İzin listesi (Daha açıklayıcı)
              _buildPermissionItem(Icons.notifications_active_outlined, 'Bildirimler', 'Alarm durumu ve servis hakkında bilgi vermek için.'),
              _buildPermissionItem(Icons.schedule_outlined, 'Tam Zamanlı Alarm', '(Android 12+) Kesin zamanda alarm çalabilmek için.'),
              _buildPermissionItem(Icons.layers_outlined, 'Diğer Uygulamaların Üzerinde Gösterme', 'Kilit ekranında alarm arayüzünü göstermek için (ayarlar gerekebilir).'),
              _buildPermissionItem(Icons.battery_charging_full_outlined, 'Pil Optimizasyonunu Yoksay', 'Alarmların gecikmeden çalması için (ayarlar gerekebilir).'),

              const Spacer(), // Butonları aşağıya iter

              // Yükleme durumu veya İzin Ver Butonu
              _isLoading
                  ? const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
                  : ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Gerekli İzinleri İste'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.deepPurple, // Ana renk
                  foregroundColor: Colors.white, // Yazı rengi
                ),
                onPressed: _requestAndCheckPermissions, // Butona basınca izinleri iste
              ),
              const SizedBox(height: 10),
              // Ayarları Aç butonu (her zaman görünür)
              TextButton(
                onPressed: () async {
                  await openAppSettings(); // Doğrudan uygulama ayarlarına yönlendir
                },
                child: const Text('İzinleri Manuel Ayarla'),
              ),
              const SizedBox(height: 16), // Alt boşluk
            ],
          ),
        ),
      ),
    );
  }

  // İzin maddesi oluşturan yardımcı widget
  Widget _buildPermissionItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0), // Biraz daha aralık
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // İkon ve metni yukarı hizala
        children: [
          Icon(icon, color: Colors.deepPurple.withOpacity(0.8), size: 28), // İkon rengi ve boyutu
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)), // Başlık fontu
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.3)), // Alt yazı stili
              ],
            ),
          ),
        ],
      ),
    );
  }
}