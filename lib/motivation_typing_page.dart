import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'good_morning.dart';
import 'main.dart'; // 🔔 nativeAlarmId global değişkeni burada tanımlı olmalı

class MotivationTypingPage extends StatefulWidget {
  final int? alarmId;
  const MotivationTypingPage({super.key, this.alarmId});

  @override
  State<MotivationTypingPage> createState() => _MotivationTypingPageState();
}

class _MotivationTypingPageState extends State<MotivationTypingPage> {
  static const _native = MethodChannel('com.example.alarm/native');

  String _target = '';
  String _input  = '';
  late Timer _timer;
  int   _remaining = 60;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickSentence();
    _startTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _timer.cancel();
    if (_input != _target) _restartAlarm();
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _pickSentence() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('motivations') ?? [];
    _target = (list..shuffle()).isEmpty
        ? 'Bugün harika bir gün olacak.'
        : list.first;
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining == 0) {
        _timer.cancel();
        _restartAlarm();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _restartAlarm() async {
    final int? id = widget.alarmId ?? nativeAlarmId;
    if (id == null || id == -1) {
      debugPrint("❌ alarmId null veya -1 olduğu için restart yapılamadı.");
      return;
    }

    try {
      debugPrint("🔁 restartAlarmFromFlutter çağrılıyor → ID=$id");
      await _native.invokeMethod('restartAlarmFromFlutter', {'alarmId': id});
      debugPrint("✅ restartAlarmFromFlutter invokeMethod başarıyla gönderildi.");
    } catch (e) {
      debugPrint("❌ restartAlarmFromFlutter invokeMethod başarısız: $e");
    }
  }

  void _onChanged(String v) {
    setState(() => _input = v);
    if (_input == _target) {
      _timer.cancel();
      final int? id = widget.alarmId ?? nativeAlarmId;
      if (id != null && id != -1) {
        _native.invokeMethod('cancelNativeAlarm', {'id': id});
      }

      // önce bu sayfayı kapatıyoruz
      Navigator.of(context).pop();

      // ardından GoodMorningPage sayfasını açıyoruz
      Future.microtask(() {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GoodMorningPage()),
        );
      });
    }
  }


  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: () async => false,
    child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF221B36), Color(0xFF0D0B14)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: _target.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                '⏰  Uyanma Görevi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: RichText(
                  text: TextSpan(
                    children: List.generate(_target.length, (i) {
                      final correct = i < _input.length && _input[i] == _target[i];
                      final attempted = i < _input.length;
                      return TextSpan(
                        text: _target[i],
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'FiraCode',
                          letterSpacing: 0.5,
                          color: correct
                              ? Colors.tealAccent
                              : attempted
                              ? Colors.redAccent
                              : Colors.white54,
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                autofocus: true,
                cursorColor: Colors.tealAccent,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white12,
                  hintText: 'Buraya yaz…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onChanged,
              ),

              const Spacer(),

              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: _remaining / 60,
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.tealAccent),
                      ),
                    ),
                    Text(
                      '$_remaining',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.tealAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  );
}
