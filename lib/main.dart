// ────────────────────────────────────────────────────────────────────────
// main.dart    →  TAM DOSYA (Native Alarm Tetikleme & İzin Ekranı İçin Düzenlendi)
// ────────────────────────────────────────────────────────────────────────

// ——— Dart / Flutter —
import 'dart:convert'; // AlarmStorage için
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';           // debugPrint
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';             // MethodChannel
import 'motivation_page.dart';
// ——— Üçüncü-taraf paketler —
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // firstWhereOrNull için

// ——— Uygulama dosyaları —
import 'alarm_model.dart';
import 'alarm_storage.dart';
import 'permission_screen.dart'; // İzin ekranı

// ───────── Bildirim / kanal sabitleri ─────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const String alarmChannelId   = 'alarm_channel_id'; // Bildirimler için kanal ID
const String alarmChannelName = 'Alarm Notifications';
const String alarmChannelDesc = 'Channel for Alarm notifications';

/// 🔔 Native tarafa (MainActivity) mesaj göndermek için kanal
const MethodChannel _nativeChannel =
MethodChannel('com.example.alarm/native');

// ───────── Alarm callback (ARTIK KULLANILMIYOR) ─────────
// Tetikleme tamamen native tarafta (AlarmTriggerReceiver) gerçekleşiyor.

/// Bildirim kanalını yapılandırma fonksiyonu
Future<void> _configureNotificationChannel() async {
  if (!Platform.isAndroid) return;
  const androidPlatformChannelSpecifics = AndroidNotificationChannel(
    alarmChannelId,
    alarmChannelName,
    description: alarmChannelDesc,
    importance: Importance.max,
    playSound: false, // Ses RingService'den gelecek
  );
  try {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidPlatformChannelSpecifics);
    debugPrint("Notification channel '$alarmChannelId' created or updated.");
  } catch (e) {
    debugPrint("Failed to create notification channel: $e");
  }
}


// 🔽 1)  ---  MainShell'i ÖNCE tanımla (veya MyApp'ten sonra) ---
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AlarmHomePage(),
    MotivationPage(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_alarm),
            label: 'Alarmlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_quote),
            label: 'Motivasyonlar',
          ),
        ],
      ),
    );
  }
}
// ───────────────────── ANA UYGULAMA GİRİŞ NOKTASI ─────────────────────

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gerekirse tarih formatlamayı başlat
  await initializeDateFormatting('tr_TR', null);

  // --- Bildirimler (Opsiyonel) ---
  // final launch = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  // final openedViaNotifPayload = launch?.notificationResponse?.payload;

  const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: initAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint("Notification tapped with payload: ${response.payload}");
      // Tıklanınca ana sayfaya gitmek yeterli olabilir.
    },
  );
  await _configureNotificationChannel();

  // --- İzinler (Sadece Durum Kontrolü) ---
  bool allCriticalPermissionsGranted = false;
  if (Platform.isAndroid) {
    debugPrint("Checking critical permissions status...");
    // İzinleri istemek yerine SADECE durumlarını KONTROL ET
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    final overlayStatus = await Permission.systemAlertWindow.status;
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    final notificationStatus = await Permission.notification.status;

    // Durumları kontrol et
    final batteryGranted = batteryStatus.isGranted;
    final overlayGranted = overlayStatus.isGranted;
    final exactAlarmGranted = exactAlarmStatus.isGranted;
    final notificationGranted = notificationStatus.isGranted;

    // Android 12+ kontrolü (basitleştirilmiş)
    final bool checkExactAlarm = await _isAndroid12OrHigher();

    // Tüm GEREKLİ izinler verilmiş mi?
    allCriticalPermissionsGranted = batteryGranted && overlayGranted && notificationGranted && (!checkExactAlarm || exactAlarmGranted) ;

    debugPrint("Permission Status (Initial Check): Battery=$batteryGranted, Overlay=$overlayGranted, ExactAlarm=$exactAlarmGranted (Required: $checkExactAlarm), Notification=$notificationGranted");
    debugPrint("All critical permissions granted on startup: $allCriticalPermissionsGranted");

  } else {
    allCriticalPermissionsGranted = true; // Diğer platformlar için
  }

  // --- Alarm Yöneticisi Başlatma (ARTIK GEREKLİ DEĞİL) ---
  // await AndroidAlarmManager.initialize(); // KALDIRILDI

  // --- Uygulamayı Başlat ---
  runApp(
    MyApp(
      // İzinler tamamsa '/', eksikse '/permissions' rotasını başlat
      initialRoute: allCriticalPermissionsGranted ? '/' : '/permissions',
      // alarmPayload: openedViaNotifPayload,
    ),
  );
}

// Android S (API 31) veya üstü olup olmadığını kontrol etme (izin kontrolü için)
Future<bool> _isAndroid12OrHigher() async {
  if (Platform.isAndroid) {
    // Daha kesin kontrol için device_info_plus kullanılabilir, şimdilik varsayım yapalım.
    return true; // Modern cihazlarda kontrol gerekli varsayımı
  }
  return false;
}

// ───────────────────── FLUTTER UYGULAMASI (MyApp Widget) ─────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute, this.alarmPayload});


  final String initialRoute;
  final String? alarmPayload;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Alarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: initialRoute,
      routes: {
        '/': (_)  => const MainShell(),
        '/permissions': (_) => const PermissionScreen(), // PermissionScreen widget'ını kullan
      },
      // onGenerateRoute: Artık /ring rotası Flutter'da ele alınmıyor.
      onGenerateRoute: (settings) {
        debugPrint("onGenerateRoute called for ${settings.name} - No specific handler.");
        return null;
      },
    );
  }
}

// ───────────────── ANA SAYFA VE DİĞER WIDGETLAR ─────────────────

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({super.key});

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  List<AlarmInfo> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Artık main kontrol ettiği için buradaki kontrol kaldırılabilir veya
    // sadece bir loglama/doğrulama amaçlı kalabilir.
    // Şimdilik kaldırıyorum, eğer main'deki yönlendirme çalışıyorsa gerek yok.
    // _checkPermissionsAndLoad();
    _loadAlarmsAndReschedule(); // Doğrudan alarmları yükle
  }

  // Bu fonksiyon artık initState'ten çağrılmıyor ama referans olarak kalabilir.
  /*
  Future<void> _checkPermissionsAndLoad() async {
    if (Platform.isAndroid) {
      final batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;
      final overlayGranted = await Permission.systemAlertWindow.isGranted;
      final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
      final notificationGranted = await Permission.notification.isGranted;
      final bool checkExactAlarm = await _isAndroid12OrHigher();

      if (!batteryGranted || !overlayGranted || !notificationGranted || (checkExactAlarm && !exactAlarmGranted)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (mounted) {
              Navigator.of(context).pushReplacementNamed('/permissions');
           }
        });
        return;
      }
    }
    _loadAlarmsAndReschedule();
  }
  */

  Future<void> _loadAlarmsAndReschedule() async {
    // İzinlerin burada tekrar kontrol edilmesi GEREKLİ DEĞİL,
    // çünkü bu sayfaya gelindiyse izinler zaten tam olmalı.
    setState(() { _isLoading = true; });
    _alarms = await AlarmStorage.loadAlarms();
    final now = DateTime.now();
    bool needsSave = false;
    List<AlarmInfo> updatedAlarms = [];
    List<Future<bool>> scheduleFutures = [];

    for (var alarm in _alarms) {
      if (alarm.isActive && alarm.repeatDays.isEmpty && alarm.dateTime.isBefore(now)) {
        debugPrint("Deactivating past one-shot alarm ID: ${alarm.id}");
        alarm.isActive = false;
        needsSave = true;
        scheduleFutures.add(_scheduleSystemAlarm(alarm)); // Native cancel çağırır
      } else {
        if (alarm.isActive) {
          DateTime nextAlarmTime = alarm.calculateNextAlarmTime(now);
          if (alarm.dateTime != nextAlarmTime) {
            debugPrint("Updating next alarm time for ID ${alarm.id} from ${alarm.dateTime} to $nextAlarmTime");
            alarm.dateTime = nextAlarmTime;
            needsSave = true;
          }
        }
        scheduleFutures.add(_scheduleSystemAlarm(alarm)); // Native schedule/cancel çağırır
      }
      updatedAlarms.add(alarm);
    }

    await Future.wait(scheduleFutures);

    if (needsSave) {
      await AlarmStorage.saveAlarms(updatedAlarms);
    }

    _alarms = updatedAlarms..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (mounted) {
      setState(() { _isLoading = false; });
    }
    debugPrint("Alarms loaded and requested native scheduling/cancellation.");
  }

  Future<void> _showAddEditAlarmDialog({AlarmInfo? existingAlarm}) async {
    final result = await showDialog<AlarmInfo>(
      context: context,
      builder: (context) => _AlarmEditDialog(initialAlarm: existingAlarm),
    );
    if (result != null) {
      await _saveOrUpdateAlarm(result);
    }
  }

  Future<void> _saveOrUpdateAlarm(AlarmInfo alarm) async {
    final now = DateTime.now();
    alarm.dateTime = alarm.calculateNextAlarmTime(now);
    alarm.isActive = true;

    bool scheduled = await _scheduleSystemAlarm(alarm); // Native schedule çağır

    if (scheduled) {
      int existingIndex = _alarms.indexWhere((a) => a.id == alarm.id);
      setState(() {
        if (existingIndex != -1) {
          _alarms[existingIndex] = alarm;
        } else {
          _alarms.add(alarm);
        }
        _alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
      await AlarmStorage.saveAlarms(_alarms);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Alarm ${existingIndex != -1 ? 'güncellendi' : 'kuruldu'}: ${DateFormat('dd MMM HH:mm', 'tr_TR').format(alarm.dateTime)}'),
              duration: const Duration(seconds: 2)),
        );
      }
    } else {
      debugPrint("Failed to request native schedule for ID: ${alarm.id}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Alarm kurma isteği gönderilemedi! Lütfen tekrar deneyin.')),
        );
      }
    }
  }

  Future<void> _toggleAlarm(AlarmInfo alarm, bool isActive) async {
    final originalState = alarm.isActive;
    setState(() {
      alarm.isActive = isActive;
      if (isActive) {
        alarm.dateTime = alarm.calculateNextAlarmTime(DateTime.now());
      }
    });

    bool success = await _scheduleSystemAlarm(alarm); // Native schedule/cancel çağır

    if (success) {
      await AlarmStorage.updateAlarm(alarm);
      debugPrint("Alarm (ID: ${alarm.id}) status update request sent: $isActive");
    } else {
      setState(() { alarm.isActive = originalState; });
      debugPrint("Failed to send status update for alarm (ID: ${alarm.id}).");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm durumu güncellenemedi!')),
        );
      }
    }
  }

  // Native metodları çağıran fonksiyon
  Future<bool> _scheduleSystemAlarm(AlarmInfo alarm) async {
    if (alarm.isActive) {
      debugPrint(
          "Requesting native schedule: ID ${alarm.id}, Time: ${alarm.dateTime.millisecondsSinceEpoch}");
      try {
        await _nativeChannel.invokeMethod('scheduleNativeAlarm', {
          'id': alarm.id,
          'timeInMillis': alarm.dateTime.millisecondsSinceEpoch,
          'isRepeating': alarm.repeatDays.isNotEmpty,
        });
        debugPrint("Native schedule request successful for ID: ${alarm.id}");
        return true;
      } catch (e, s) {
        debugPrint("🚨 Failed to invoke native schedule method for ID ${alarm.id} → $e\n$s");
        return false;
      }
    } else {
      debugPrint("Requesting native cancel: ID ${alarm.id}");
      try {
        await _nativeChannel.invokeMethod('cancelNativeAlarm', {'id': alarm.id});
        debugPrint("Native cancel request successful for ID: ${alarm.id}");
        return true;
      } catch (e, s) {
        debugPrint("🚨 Failed to invoke native cancel method for ID ${alarm.id} → $e\n$s");
        return false;
      }
    }
  }

  // Native iptal metodunu çağıran fonksiyon
  Future<void> _deleteAlarm(AlarmInfo alarm, int index) async {
    debugPrint("Requesting native cancel for deletion: ID ${alarm.id}");
    bool cancelled = false;
    try {
      await _nativeChannel.invokeMethod('cancelNativeAlarm', {'id': alarm.id});
      debugPrint("Native cancel request successful for deletion ID: ${alarm.id}");
      cancelled = true;
    } catch (e,s) {
      debugPrint("🚨 Failed to invoke native cancel method during deletion for ID ${alarm.id} → $e\n$s");
    }

    setState(() { _alarms.removeAt(index); });
    await AlarmStorage.saveAlarms(_alarms);
    debugPrint('Alarm (ID: ${alarm.id}) deleted from list.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Alarm silindi${cancelled ? "" : " (Sistemden kaldırılamamış olabilir!)"}'),
            duration: const Duration(seconds: 2)),
      );
    }
  }

  // --- Ana Sayfa Build Metodu ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmlarım'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm),
            tooltip: 'Yeni Alarm Ekle',
            onPressed: () => _showAddEditAlarmDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
          ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.alarm_off, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Henüz alarm kurulmadı.\nEklemek için sağ üstteki + ikonuna dokunun.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ))
          : ListView.separated(
        itemCount: _alarms.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          final now = DateTime.now();
          final nextOccurrence = alarm.dateTime;

          String nextTimeString;
          if (!alarm.isActive) {
            nextTimeString = "Pasif";
          } else if (nextOccurrence.isBefore(now) && alarm.repeatDays.isEmpty) {
            nextTimeString = "Pasif (Geçmiş)";
          } else {
            final isToday = now.year == nextOccurrence.year && now.month == nextOccurrence.month && now.day == nextOccurrence.day;
            final isTomorrow = now.add(const Duration(days: 1)).year == nextOccurrence.year && now.add(const Duration(days: 1)).month == nextOccurrence.month && now.add(const Duration(days: 1)).day == nextOccurrence.day;
            if (isToday) {
              nextTimeString = 'Bugün ${DateFormat('HH:mm').format(nextOccurrence)}';
            } else if (isTomorrow) {
              nextTimeString = 'Yarın ${DateFormat('HH:mm').format(nextOccurrence)}';
            } else {
              nextTimeString = DateFormat('dd MMM E, HH:mm', 'tr_TR').format(nextOccurrence);
            }
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            leading: Icon(
              alarm.isActive ? Icons.alarm_on : Icons.alarm_off,
              color: alarm.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
              size: 30,
            ),
            title: Text(
              DateFormat('HH:mm').format(alarm.dateTime), // DateTime kullanılıyor
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: alarm.isActive ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey[500],
                decoration: !alarm.isActive ? TextDecoration.lineThrough : null,
                decorationColor: Colors.grey[500],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (alarm.label != null && alarm.label!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      alarm.label!,
                      style: TextStyle(
                          fontSize: 16,
                          color: alarm.isActive ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${alarm.repeatDaysText} | $nextTimeString',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            trailing: Switch(
              value: alarm.isActive,
              onChanged: (bool value) { _toggleAlarm(alarm, value); },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => _showAddEditAlarmDialog(existingAlarm: alarm),
            onLongPress: () async {
              bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Alarmı Sil?'),
                    content: Text(
                        'Bu alarmı (${DateFormat('HH:mm').format(alarm.dateTime)}${alarm.label != null && alarm.label!.isNotEmpty ? ' - ${alarm.label}' : ''}) kalıcı olarak silmek istediğinizden emin misiniz?'), // DateTime kullanılıyor
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('İPTAL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('SİL', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
              if (confirmDelete == true) {
                _deleteAlarm(alarm, index);
              }
            },
          );
        },
      ),
    );
  }
}

// --- Alarm Ekleme/Düzenleme Dialog Widget'ı ---
class _AlarmEditDialog extends StatefulWidget {
  final AlarmInfo? initialAlarm;
  const _AlarmEditDialog({super.key, this.initialAlarm});

  @override
  __AlarmEditDialogState createState() => __AlarmEditDialogState();
}

class __AlarmEditDialogState extends State<_AlarmEditDialog> {
  late TimeOfDay _selectedTime;
  late TextEditingController _labelController;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTime = widget.initialAlarm?.timeOfDay ?? TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5)));
    _labelController = TextEditingController(text: widget.initialAlarm?.label ?? '');
    _selectedDays = widget.initialAlarm?.repeatDays.toSet() ?? {};
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() { _selectedTime = picked; });
    }
  }

  void _save() async {
    final now = DateTime.now();
    // Sadece saat bilgisini içeren geçici bir DateTime oluştur
    DateTime baseDateTimeWithSelectedTime = DateTime(now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

    final alarmInfo = AlarmInfo(
      id: widget.initialAlarm?.id ?? await AlarmStorage.getNextAlarmId(),
      dateTime: baseDateTimeWithSelectedTime, // Geçici zaman (asıl hesaplama saveOrUpdate'te)
      label: _labelController.text.trim(),
      repeatDays: _selectedDays.toList()..sort(),
      isActive: widget.initialAlarm?.isActive ?? true,
    );
    Navigator.of(context).pop(alarmInfo); // Dialogu kapat ve sonucu döndür
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Center(child: Text(widget.initialAlarm == null ? 'Yeni Alarm Kur' : 'Alarmı Düzenle')),
      contentPadding: const EdgeInsets.all(16.0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    MaterialLocalizations.of(context).formatTimeOfDay(_selectedTime, alwaysUse24HourFormat: true),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 24, thickness: 1),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Alarm Etiketi (Opsiyonel)',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text('Tekrarlama Günleri:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: List<Widget>.generate(7, (int index) {
                final dayValue = index + 1;
                final isSelected = _selectedDays.contains(dayValue);
                return ChoiceChip(
                  label: Text(dayNames[index]),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) { _selectedDays.add(dayValue); }
                      else { _selectedDays.remove(dayValue); }
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : isDarkMode ? Colors.white70 : Colors.black87),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                );
              }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedDays.clear()),
                  child: const Text("Temizle"),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDays = Set.from(allWeekdays)),
                  child: const Text("Tümünü Seç"),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          child: const Text('İptal'),
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
        ),
        ElevatedButton(
          child: const Text('Kaydet'),
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    );
  }
}

// ───────── intl PAKETİ İÇİN GEREKLİ AYARLAR ─────────
Future<void> initializeDateFormatting(String locale, String? _) async {
  Intl.defaultLocale = locale;
}