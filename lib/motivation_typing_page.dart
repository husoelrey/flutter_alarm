import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MotivationTypingPage extends StatefulWidget {
  final int? alarmId;
  const MotivationTypingPage({Key? key, this.alarmId}) : super(key: key);

  @override
  _MotivationTypingPageState createState() => _MotivationTypingPageState();
}

class _MotivationTypingPageState extends State<MotivationTypingPage> {
  static const _nativeChannel = MethodChannel('com.example.alarm/native');

  late String targetSentence;
  String userInput = '';
  Timer? countdownTimer;
  int remainingSeconds = 10; // test için kısa tut

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRandomMotivation();
    _startTimer();

    // Sistem çubuklarını gizle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _loadRandomMotivation() async {
    final prefs = await SharedPreferences.getInstance();
    final motivations = prefs.getStringList('motivations') ?? [];

    if (motivations.isEmpty) {
      targetSentence = "Bugün harika bir gün olacak.";
    } else {
      motivations.shuffle();
      targetSentence = motivations.first;
    }

    setState(() {});
  }

  void _startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        timer.cancel();
        _restartAlarm(); // süre bitti, alarm yeniden çalmalı
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  void _restartAlarm() {
    if (widget.alarmId != null) {
      _nativeChannel.invokeMethod("restartAlarmFromFlutter", {
        "alarmId": widget.alarmId,
      });
    }
    Navigator.of(context).pop(); // sayfayı kapat
  }

  void _checkInput(String value) {
    setState(() => userInput = value);
    if (userInput == targetSentence) {
      countdownTimer?.cancel();
      Navigator.of(context).pop(); // başarılı tamamlandı
    }
  }
  @override
  void dispose() {
    countdownTimer?.cancel();

    // 👇 Bu eksik: kullanıcı yazmadan çıkarsa alarm tekrar çalsın
    if (userInput != targetSentence && widget.alarmId != null) {
      _nativeChannel.invokeMethod("restartAlarmFromFlutter", {
        "alarmId": widget.alarmId,
      });
    }

    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // geri tuşunu engelle
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Uyanma Görevi'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: targetSentence.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                'Bu cümleyi yaz:',
                style: TextStyle(fontSize: 20, color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              Wrap(
                children: List.generate(targetSentence.length, (i) {
                  final correct = i < userInput.length &&
                      userInput[i] == targetSentence[i];
                  final attempted = i < userInput.length;
                  return Text(
                    targetSentence[i],
                    style: TextStyle(
                      fontSize: 24,
                      color: correct
                          ? Colors.white
                          : attempted
                          ? Colors.red
                          : Colors.grey[700],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextField(
                autofocus: true,
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cümleyi buraya yaz',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
                onChanged: _checkInput,
              ),
              const Spacer(),
              Text(
                'Kalan Süre: $remainingSeconds sn',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
