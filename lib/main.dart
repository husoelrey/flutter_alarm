// ────────────────────────────────────────────────────────────────────────
// main.dart    →  void main()’DEN ÖNCEKİ TAM KISIM
// ────────────────────────────────────────────────────────────────────────

// ——— Dart / Flutter —
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';           // debugPrint
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';             // MethodChannel

// ——— Üçüncü-taraf paketler —
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

// ——— Uygulama dosyaları —
import 'alarm_model.dart';
import 'alarm_storage.dart';
import 'permission_helper.dart';           // /permissions ekranı için
import 'permission_screen.dart';
import 'alarm_ring_screen.dart';

// ───────── Bildirim / kanal sabitleri ─────────
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const String alarmChannelId   = 'alarm_channel_id';
const String alarmChannelName = 'Alarm Notifications';
const String alarmChannelDesc = 'Channel for Alarm notifications';

/// 🔔  (Kotlin tarafına mesaj göndermek istersen hazır)
const MethodChannel _nativeChannel =
MethodChannel('com.example.alarm/native');

// ───────── Alarm callback (background isolate) ─────────
@pragma('vm:entry-point')
void alarmCallback() async {
  debugPrint('[AlarmCallback] triggered');

  final alarms = await AlarmStorage.loadAlarms();
  final now    = DateTime.now();

  AlarmInfo? current;
  Duration   minDiff = const Duration(days: 365);

  // En yakın (±2 dk) aktif alarmı bul
  for (final a in alarms.where((e) => e.isActive)) {
    final diff = now.difference(a.dateTime).abs();
    if (diff < const Duration(minutes: 2) && diff < minDiff) {
      minDiff = diff;
      current = a;
    }
  }

  // ➜ Tam-ekran aktiviteyi aç
  await _launchRingActivity(current?.id ?? -1);

  // ↻  Tekrarlıysa bir sonrakini kur
  if (current != null && current.repeatDays.isNotEmpty) {
    final next =
    current.calculateNextAlarmTime(now.add(const Duration(minutes: 1)));

    if (next != current.dateTime) {
      current.dateTime = next;

      await AndroidAlarmManager.oneShotAt(
        next,
        current.id,
        alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
      await AlarmStorage.updateAlarm(current);
    }
  } else if (current != null) {
    // Tek-seferlik: pasifleştir
    current.isActive = false;
    await AlarmStorage.updateAlarm(current);
  }
}

/// ───────── Tam-ekran AlarmRingActivity’yi başlat ─────────
Future<void> _launchRingActivity(int alarmId) async {
  if (!Platform.isAndroid) return; // iOS/Web’de yok say

  const String pkg = 'com.example.alarm'; // ← kendi paket adın
  try {
    final intent = AndroidIntent(
      action: 'android.intent.action.RUN',
      package: pkg,
      componentName: '$pkg.AlarmRingActivity',

      arguments: {'id': alarmId.toString()},
      flags: <int>[
        Flag.FLAG_ACTIVITY_NEW_TASK,
        Flag.FLAG_ACTIVITY_SINGLE_TOP,
      ],
    );
    await intent.launch();
  } catch (e, s) {
    debugPrint('🚨 AlarmRingActivity başlatılamadı → $e\n$s');
  }
}

/// (Opsiyonel) bildirim kanalı oluştur
Future<void> _configureNotificationChannel() async {
  const android = AndroidNotificationChannel(
    alarmChannelId,
    alarmChannelName,
    description: alarmChannelDesc,
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(android);
}

// ─────────────────────  buradan sonrası sizin mevcut  main()  fonksiyonunuz  ─────────────────────





final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();





Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bildirimden mi açıldı kontrolü
  final launch = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  final openedViaNotif = launch?.didNotificationLaunchApp ?? false;
  final payload = launch?.notificationResponse?.payload;

  // Bildirim yapılandırması
  const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const init = InitializationSettings(android: initAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    init,
    onDidReceiveNotificationResponse: (resp) {
      navigatorKey.currentState?.pushNamed(
        '/ring',
        arguments: {'id': int.tryParse(resp.payload ?? '-1') ?? -1},
      );
    },
  );

  // Bildirim & alarm izinleri (Android 13+ için önerilir)
  if (Platform.isAndroid) {
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
    await android?.requestNotificationsPermission();
  }

  // Kritik sistem izinleri kontrolü
  final batteryGranted = await Permission.ignoreBatteryOptimizations.isGranted;
  final overlayGranted = await Permission.systemAlertWindow.isGranted;
  final allCriticalPermissionsGranted = batteryGranted && overlayGranted;

  // Alarm servisini başlat
  await AndroidAlarmManager.initialize();

  // Uygulama başlat
  runApp(
    MyApp(
      initialRoute: allCriticalPermissionsGranted
          ? (openedViaNotif ? '/ring' : '/')
          : '/permissions', // Eğer izinler eksikse özel ekran
      alarmPayload: payload,
    ),
  );
}







//MYAPPP

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
      // 🟡 her zaman '/' ile başla, sonra yönlendir
      initialRoute: '/',
      routes: {
        '/': (_) => const AlarmHomePage(),
        '/permissions': (_) => const PermissionScreen(), // Varsa
      },
      onGenerateRoute: (settings) {
        // /ring?id=123 gibi bir yol geldiyse...
        if (settings.name?.startsWith('/ring') == true) {
          final uri = Uri.parse(settings.name!);
          final idParam = uri.queryParameters['id'] ?? alarmPayload ?? '-1';
          final alarmId = int.tryParse(idParam) ?? -1;

          return MaterialPageRoute(
            builder: (_) => AlarmRingScreen(alarmId: alarmId),
          );
        }
        return null;
      },
    );
  }
}

// ───────── Kalan kod (AlarmHomePage, _AlarmEditDialog, vs.) ─────────
// Senin mevcut kodun değişmeden aşağıda durabilir.

// --- Ana Sayfa Widget'ı (Stateful) ---
class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({super.key});

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

// --- Ana Sayfa State Sınıfı ---
class _AlarmHomePageState extends State<AlarmHomePage> {
  List<AlarmInfo> _alarms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlarmsAndReschedule();
  }

  Future<void> _loadAlarmsAndReschedule() async {
    setState(() {
      _isLoading = true;
    });
    _alarms = await AlarmStorage.loadAlarms();
    final now = DateTime.now();
    bool needsSave = false;

    List<Future<void>> scheduleFutures = [];

    for (var alarm in _alarms) {
      DateTime nextAlarmTime = alarm.calculateNextAlarmTime(now);
      if (alarm.dateTime != nextAlarmTime) {
        alarm.dateTime = nextAlarmTime;
        needsSave = true;
      }
      if (alarm.isActive) {
        // Sistemdeki alarmı kurma/güncelleme işlemini asenkron listeye ekle
        scheduleFutures.add(_scheduleSystemAlarm(alarm));
      } else {
        // Pasifse sistemden kaldır (zaten kuruluysa)
        scheduleFutures.add(AndroidAlarmManager.cancel(alarm.id));
      }
    }

    // Tüm sistem alarmı kurma/iptal etme işlemleri bitsin
    await Future.wait(scheduleFutures);

    if (needsSave) {
      await AlarmStorage.saveAlarms(_alarms);
    }

    _alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    print("Alarmlar yüklendi ve aktif olanlar (tekrar) kuruldu.");
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
    // Dialogdan gelen sadece saat bilgisini içeren dateTime'ı kullanarak,
    // doğru bir sonraki çalma zamanını hesapla.
    alarm.dateTime = alarm.calculateNextAlarmTime(DateTime(now.year, now.month,
        now.day, alarm.timeOfDay.hour, alarm.timeOfDay.minute));

    bool scheduled = await _scheduleSystemAlarm(alarm); // Sistemi kur/güncelle

    if (scheduled || !alarm.isActive) {
      // Başarıyla kurulduysa veya zaten pasifse
      int existingIndex = _alarms.indexWhere((a) => a.id == alarm.id);
      setState(() {
        if (existingIndex != -1) {
          _alarms[existingIndex] = alarm; // Güncelle
          print("Alarm güncellendi: ID ${alarm.id}");
        } else {
          _alarms.add(alarm); // Yeni ekle
          print("Yeni alarm eklendi: ID ${alarm.id}");
        }
        _alarms.sort(
            (a, b) => a.dateTime.compareTo(b.dateTime)); // Her zaman sıralı tut
      });
      await AlarmStorage.saveAlarms(_alarms); // Değişikliği kaydet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Alarm ${existingIndex != -1 ? 'güncellendi' : 'kuruldu'}.'),
            duration: Duration(seconds: 2)),
      );
    } else {
      print("Alarm (ID: ${alarm.id}) sisteme kurulamadı!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Alarm sisteme kurulamadı! Lütfen izinleri kontrol edin.')),
      );
    }
  }

  Future<void> _toggleAlarm(AlarmInfo alarm, bool isActive) async {
    alarm.isActive = isActive; // Önce nesneyi güncelle

    // Eğer aktif yapılıyorsa, bir sonraki zamanı tekrar hesapla ve kur
    // Eğer pasif yapılıyorsa, sadece iptal et
    bool success = await _scheduleSystemAlarm(alarm); // Sistemi kur/iptal et

    if (success || !isActive) {
      // Başarılıysa veya pasif yapıldıysa
      setState(() {}); // UI'ı güncelle (Switch durumu değişti)
      await AlarmStorage.updateAlarm(alarm); // Değişikliği kaydet
      print("Alarm (ID: ${alarm.id}) durumu güncellendi: $isActive");
    } else {
      // Aktif etmeye çalışırken hata olduysa, switch'i geri alalım
      alarm.isActive = !isActive; // Durumu geri al
      setState(() {}); // UI'ı tekrar eski haline getir
      print("Alarm (ID: ${alarm.id}) aktif edilemedi, sistem kurulamadı.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm aktif edilemedi!')),
      );
    }
  }

  // Sistemi kurma/iptal etme (refactor edildi)
  Future<bool> _scheduleSystemAlarm(AlarmInfo alarm) async {
    if (alarm.isActive) {
      // Aktifse, *hesaplanmış* bir sonraki zamana kur
      // calculateNextAlarmTime zaten doğru bir sonraki zamanı verir.
      print(
          "Sistem alarmı kuruluyor/güncelleniyor: ID ${alarm.id}, Time: ${alarm.dateTime}");
      return await AndroidAlarmManager.oneShotAt(
        alarm.dateTime,
        alarm.id,
        alarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true, // Bu önemli!
      );
    } else {
      // Pasifse, sistemden iptal et
      print("Sistem alarmı iptal ediliyor: ID ${alarm.id}");
      // Cancel her zaman true döner (eğer ID daha önce hiç kullanılmadıysa bile)
      // Bu yüzden doğrudan true dönebiliriz veya sonucu kontrol etmeyebiliriz.
      await AndroidAlarmManager.cancel(alarm.id);
      return true; // İptal işlemi başarılı kabul edilir
    }
  }

  Future<void> _deleteAlarm(AlarmInfo alarm, int index) async {
    await AndroidAlarmManager.cancel(alarm.id); // Önce sistemden kaldır
    setState(() {
      _alarms.removeAt(index); // Sonra listeden kaldır
    });
    await AlarmStorage.saveAlarms(_alarms); // Değişikliği kaydet
    print('Alarm (ID: ${alarm.id}) silindi.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Alarm silindi.'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmlarım'),
        backgroundColor:
            Theme.of(context).colorScheme.inversePrimary, // AppBar rengi
        actions: [
          IconButton(
            icon: Icon(Icons.add_alarm),
            tooltip: 'Yeni Alarm Ekle',
            onPressed: () => _showAddEditAlarmDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _alarms.isEmpty
              ? Center(
                  child: Column(
                  // İkon ve metin ekleyelim
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_off, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Henüz alarm kurulmadı.\nEklemek için sağ üstteki + ikonuna dokunun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ))
              : ListView.separated(
                  // Daha iyi ayırma için Separated kullan
                  itemCount: _alarms.length,
                  separatorBuilder: (context, index) => Divider(
                      height: 1, indent: 16, endIndent: 16), // Ayırıcı çizgi
                  itemBuilder: (context, index) {
                    final alarm = _alarms[index];
                    final now = DateTime.now();
                    // Sonraki çalma zamanını tekrar hesaplamaya gerek yok, yüklemede yapıldı.
                    final nextOccurrence = alarm.dateTime;
                    final isToday = now.year == nextOccurrence.year &&
                        now.month == nextOccurrence.month &&
                        now.day == nextOccurrence.day;
                    final isTomorrow = now.add(Duration(days: 1)).year ==
                            nextOccurrence.year &&
                        now.add(Duration(days: 1)).month ==
                            nextOccurrence.month &&
                        now.add(Duration(days: 1)).day == nextOccurrence.day;

                    String nextTimeString;
                    if (!alarm.isActive) {
                      nextTimeString = "Pasif";
                    } else if (isToday) {
                      nextTimeString =
                          'Bugün ${DateFormat('HH:mm').format(nextOccurrence)}';
                    } else if (isTomorrow) {
                      nextTimeString =
                          'Yarın ${DateFormat('HH:mm').format(nextOccurrence)}';
                    } else {
                      nextTimeString = DateFormat('dd MMM E, HH:mm', 'tr_TR')
                          .format(nextOccurrence);
                    }

                    return ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      // İç boşluk
                      leading: Icon(
                        alarm.isActive ? Icons.alarm_on : Icons.alarm_off,
                        color: alarm.isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 30, // İkon boyutu
                      ),
                      title: Text(
                        DateFormat('HH:mm').format(alarm.dateTime),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: alarm.isActive
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Colors.grey[500],
                          decoration: !alarm.isActive
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.grey[500],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (alarm.label != null && alarm.label!.isNotEmpty)
                            Padding(
                              // Etiket için biraz boşluk
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                alarm.label!,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: alarm.isActive
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                        : Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          Padding(
                            // Alt metin için boşluk
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
                        onChanged: (bool value) {
                          _toggleAlarm(alarm, value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      onTap: () =>
                          _showAddEditAlarmDialog(existingAlarm: alarm),
                      // Düzenle
                      onLongPress: () async {
                        // Silme onayı
                        bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Alarmı Sil?'),
                              content: Text(
                                  'Bu alarmı (${DateFormat('HH:mm').format(alarm.dateTime)}${alarm.label != null && alarm.label!.isNotEmpty ? ' - ${alarm.label}' : ''}) kalıcı olarak silmek istediğinizden emin misiniz?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text('İPTAL'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text('SİL',
                                      style: TextStyle(color: Colors.red)),
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

  const _AlarmEditDialog({this.initialAlarm});

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
    _selectedTime = widget.initialAlarm?.timeOfDay ??
        TimeOfDay.fromDateTime(now.add(Duration(minutes: 5)));
    _labelController =
        TextEditingController(text: widget.initialAlarm?.label ?? '');
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
          // 24 saat formatı
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _save() async {
    final now = DateTime.now();
    // Dialogdan sadece saat bilgisini içeren bir DateTime oluştur.
    // Gerçek çalma zamanı _saveOrUpdateAlarm içinde hesaplanacak.
    DateTime baseDateTimeWithSelectedTime = DateTime(
        now.year, now.month, now.day, _selectedTime.hour, _selectedTime.minute);

    final alarmInfo = AlarmInfo(
      id: widget.initialAlarm?.id ?? await AlarmStorage.getNextAlarmId(),
      dateTime: baseDateTimeWithSelectedTime,
      // Sadece saat bilgisi
      label: _labelController.text.trim(),
      repeatDays: _selectedDays.toList()..sort(),
      isActive: widget.initialAlarm?.isActive ??
          true, // Eskisinden al veya varsayılan true
    );
    Navigator.of(context).pop(alarmInfo); // Dialogu kapat ve sonucu döndür
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayNames = [
      'Pzt',
      'Sal',
      'Çar',
      'Per',
      'Cum',
      'Cmt',
      'Paz'
    ];
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Center(
          child: Text(widget.initialAlarm == null
              ? 'Yeni Alarm Kur'
              : 'Alarmı Düzenle')),
      contentPadding: EdgeInsets.all(16.0),
      // Kenar boşlukları
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, // İçeriği genişlet
          children: <Widget>[
            // Zaman Gösterimi ve Seçici
            Center(
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(8), // Tıklama efekti için
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    // Saati 24 saat formatında göster
                    MaterialLocalizations.of(context).formatTimeOfDay(
                        _selectedTime,
                        alwaysUse24HourFormat: true),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
            ),
            Divider(height: 24, thickness: 1),
            // Etiket Girişi
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Alarm Etiketi (Opsiyonel)',
                // icon: Icon(Icons.label_outline), // İkon yerine prefixIcon
                prefixIcon: Icon(Icons.label_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: 16),
            // Tekrarlama Günleri
            Text('Tekrarlama Günleri:',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
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
                      if (selected) {
                        _selectedDays.add(dayValue);
                      } else {
                        _selectedDays.remove(dayValue);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : isDarkMode
                              ? Colors.white70
                              : Colors.black87 // Tema uyumlu renk
                      ),
                  visualDensity: VisualDensity.compact,
                  // Daha kompakt görünüm
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16)), // Yuvarlak kenar
                );
              }),
            ),
            // Her gün / Hiçbiri Kısayolları
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _selectedDays.clear()),
                  child: Text("Temizle"),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _selectedDays = Set.from(allWeekdays)),
                  child: Text("Tümünü Seç"),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          // İptal butonu
          child: Text('İptal'),
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey), // Kenarlık rengi
          ),
        ),
        ElevatedButton(
          // Kaydet butonu (daha belirgin)
          child: Text('Kaydet'),
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary, // Ana renk
            foregroundColor:
                Theme.of(context).colorScheme.onPrimary, // Yazı rengi
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0)), // Dialog kenarları
    );
  }
}

// intl paketinin Türkçe tarih formatlaması için gerekli (main içinde çağrılıyor)
Future<void> initializeDateFormatting(String locale, String? _) async {
  // Bu fonksiyon normalde locale verisini yükler, ancak Flutter web dışı için
  // genellikle locale verisi zaten dahili gelir. Yine de intl'ın düzgün çalışması için
  // bu çağrı iyi bir pratiktir.
  var messages = await findLocaleData(locale);
  initializeMessages(locale, messages);
}

// Bu kısım intl >= 0.18 için gerekli olabilir
Map<String, dynamic> messages = {}; // Boş bir map tanımla
Future<Map<String, dynamic>> findLocaleData(String locale) async => messages;

void initializeMessages(String locale, Map<String, dynamic> messages) {}
