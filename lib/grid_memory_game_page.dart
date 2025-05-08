import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:alarm/main.dart'; // nativeAlarmId

class GridMemoryGamePage extends StatefulWidget {
  const GridMemoryGamePage({super.key, this.alarmId});
  final int? alarmId;

  @override
  State<GridMemoryGamePage> createState() => _GridMemoryGamePageState();
}

class _GridMemoryGamePageState extends State<GridMemoryGamePage> {
  // ——— parametreler ———
  static const int gridSize = 25;
  static const int hintCount = 8;
  static const int clicksPerHint = 8;
  static const Duration hintDuration = Duration(seconds: 3);
  static const int totalSeconds = 35;

  // ——— renk paleti ———
  static const Color bgNavy = Color(0xFF0A0D2B);
  static const Color tileBase = Color(0xFF1A1E3F);
  static const Color tileHint = Colors.tealAccent;
  static const Color tileWrong = Color(0xFFE53935);

  // ——— durum ———
  int? alarmIdEffective;
  final Set<int> hintIndexes = {};
  final Set<int> foundIndexes = {};
  final Set<int> selected = {};
  Set<int> currentHint = {};

  bool showHints = true;
  int secondsLeft = totalSeconds;
  Timer? timeoutTimer;

  static const platform = MethodChannel('com.example.alarm/native');

  @override
  void initState() {
    super.initState();

    alarmIdEffective = widget.alarmId ?? nativeAlarmId;

    if (alarmIdEffective == null) {
      debugPrint("⚠️ GridMemoryGamePage: alarmId bulunamadı, sayfa kapatılıyor.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    _generateHints();
    _startHint(first: true);
    _startTimer();
  }

  Future<void> _playSavedAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    final soundPath = prefs.getString('selected_alarm_sound');

    if (soundPath != null && soundPath.isNotEmpty) {
      final player = AudioPlayer();
      await player.play(DeviceFileSource(soundPath));
    } else {
      debugPrint("Alarm sesi bulunamadı");
    }
  }

  void _generateHints() {
    final rand = Random();
    while (hintIndexes.length < hintCount) {
      hintIndexes.add(rand.nextInt(gridSize));
    }
  }

  void _startHint({bool first = false}) {
    currentHint = hintIndexes.difference(foundIndexes);
    if (!first) selected.clear();
    setState(() => showHints = true);

    Future.delayed(hintDuration, () {
      if (mounted) setState(() => showHints = false);
    });
  }

  void _startTimer() {
    timeoutTimer?.cancel();
    timeoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft == 0) {
        t.cancel();
        _restartAlarmNative();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  void _restartAlarmNative() async {
    try {
      await platform.invokeMethod("restartAlarmFromFlutter", {
        "alarmId": alarmIdEffective,
      });
    } catch (e) {
      debugPrint("restartAlarmFromFlutter error → $e");
    }
  }

  void _handleTap(int idx) {
    if (showHints || selected.contains(idx) || foundIndexes.contains(idx)) return;

    setState(() => selected.add(idx));

    if (hintIndexes.contains(idx)) {
      foundIndexes.add(idx);
    }

    if (foundIndexes.length == hintCount) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.of(context).pushReplacementNamed(
          '/typing',
          arguments: {"alarmId": alarmIdEffective},
        );
      });
      return;
    }

    if (selected.length >= clicksPerHint) {
      _startHint();
    }
  }

  @override
  void dispose() {
    timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: bgNavy,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: secondsLeft / totalSeconds,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(tileHint),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(22),
                  itemCount: gridSize,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemBuilder: (_, i) {
                    final bool correct = foundIndexes.contains(i);
                    final bool hintNow = showHints && currentHint.contains(i);
                    final bool tappedBad = selected.contains(i) && !correct;

                    Color color = tileBase;
                    double opacity = 1;

                    if (correct || hintNow) color = tileHint;
                    if (tappedBad) {
                      color = tileWrong;
                      opacity = 0.45;
                    }

                    return GestureDetector(
                      onTap: () => _handleTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: color.withOpacity(opacity),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 7,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
