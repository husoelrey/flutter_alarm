import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm/main.dart';           // nativeAlarmId

class GridMemoryGamePage extends StatefulWidget {
  const GridMemoryGamePage({super.key, this.alarmId});
  final int? alarmId;

  @override
  State<GridMemoryGamePage> createState() => _GridMemoryGamePageState();
}

class _GridMemoryGamePageState extends State<GridMemoryGamePage> {
  // ——— oyun parametreleri ———
  static const int gridSize   = 25;
  static const int hintCount  = 8;   // doğru kare sayısı
  static const int maxClicksBeforeHint = 8; // toplam 8 hamlede bir yeni ipucu
  static const Duration hintDuration   = Duration(seconds: 3);

  // ——— durum ———
  late final int alarmIdEffective;              // tek kaynaktan ID
  final Set<int> allHintIndexes = {};
  final Set<int> foundIndexes   = {};
  final Set<int> selectedIndexes = {};
  Set<int> currentHint = {};

  bool showHints   = true;
  int  secondsLeft = 15;
  Timer? timeoutTimer;

  static const platform = MethodChannel('com.example.alarm/native');

  // ——— init ———
  @override
  void initState() {
    super.initState();
    alarmIdEffective = widget.alarmId ?? nativeAlarmId!;
    debugPrint("GridMemoryGamePage alarmIdEffective (init): $alarmIdEffective");

    _generateHints();
    _startHintPhase(first: true);
    _startTimeout();
  }

  // ——— oyun mantığı ———
  void _generateHints() {
    final rand = Random();
    allHintIndexes.clear();
    while (allHintIndexes.length < hintCount) {
      allHintIndexes.add(rand.nextInt(gridSize));
    }
  }

  void _startHintPhase({bool first = false}) {
    currentHint = allHintIndexes.difference(foundIndexes);
    if (!first) selectedIndexes.clear(); // yeni deneme

    setState(() => showHints = true);

    Future.delayed(hintDuration, () {
      if (mounted) setState(() => showHints = false);
    });
  }

  void _startTimeout() {
    timeoutTimer?.cancel();
    timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft == 0) {
        timer.cancel();
        _goBackToAlarm();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  void _goBackToAlarm() async {
    debugPrint("🧪 goBackToAlarm: $alarmIdEffective");
    try {
      await platform.invokeMethod("restartAlarmFromFlutter", {
        "alarmId": alarmIdEffective,
      });
    } catch (e) {
      debugPrint("Alarm yeniden başlatılamadı: $e");
    }
  }

  void _handleTap(int index) {
    if (showHints) return;                                      // ipucu açıkken tıklama yok
    if (selectedIndexes.contains(index) || foundIndexes.contains(index)) return;

    setState(() => selectedIndexes.add(index));

    // doğru kareyse kaydet
    if (allHintIndexes.contains(index)) {
      foundIndexes.add(index);
    }

    // HEDEF: tümünü bulduysa Typing ekranına
    if (foundIndexes.length == hintCount) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.of(context).pushReplacementNamed(
          '/typing',
          arguments: {"alarmId": alarmIdEffective},
        );
      });
      return;
    }

    // Her 8 hamlede bir kalan ipuçlarını göster
    if (selectedIndexes.length >= maxClicksBeforeHint) {
      _startHintPhase();
    }
  }

  @override
  void dispose() {
    timeoutTimer?.cancel();
    super.dispose();
  }

  // ——— UI ———
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bgColor   = cs.surfaceVariant;
    final goodColor = cs.tertiary;
    final hintColor = cs.primary;
    final neutral   = cs.outlineVariant;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              showHints ? "İPUCU" : "Seç (${secondsLeft}s)",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            // basit bir progress bar
            LinearProgressIndicator(
              value: secondsLeft / 15,
              minHeight: 6,
              backgroundColor: neutral.withOpacity(.3),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: gridSize,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (_, index) {
                  final bool isFound = foundIndexes.contains(index);
                  final bool isHint  = showHints && currentHint.contains(index);
                  final bool isSelected = selectedIndexes.contains(index);

                  Color tileColor  = neutral;
                  double opacity   = 1;

                  if (isFound) {
                    tileColor = goodColor;
                  } else if (isHint) {
                    tileColor = hintColor;
                  } else if (isSelected) {
                    tileColor = cs.errorContainer;
                    opacity   = .5;
                  }

                  return GestureDetector(
                    onTap: () => _handleTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: tileColor.withOpacity(opacity),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
