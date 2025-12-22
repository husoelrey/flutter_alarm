import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/good_morning.dart';
import '../services/native_channel_service.dart';

/// A screen that requires the user to type a motivational sentence to dismiss the alarm.
class MotivationTypingPage extends StatefulWidget {
  final int? alarmId;
  const MotivationTypingPage({super.key, this.alarmId});

  @override
  State<MotivationTypingPage> createState() => _MotivationTypingPageState();
}

class _MotivationTypingPageState extends State<MotivationTypingPage> {
  static const _nativeChannel = MethodChannel('com.example.alarm/native');
  static const int _totalDurationSeconds = 60;

  String _targetSentence = '';
  String _currentInput = '';
  Timer? _countdownTimer;
  int _secondsRemaining = _totalDurationSeconds;
  final _textController = TextEditingController();

  late final int? _effectiveAlarmId;

  @override
  void initState() {
    super.initState();
    _effectiveAlarmId = widget.alarmId ?? nativeAlarmId;

    _pickRandomSentence();
    _startCountdown();
    // Enable immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    // Restart the alarm if the challenge was not completed
    if (_currentInput != _targetSentence) {
      _restartAlarm();
    }
    _textController.dispose();
    // Disable immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Fetches motivational sentences from storage and picks one at random.
  Future<void> _pickRandomSentence() async {
    final prefs = await SharedPreferences.getInstance();
    final sentences = prefs.getStringList('motivations') ?? [];
    final random = Random();

    if (sentences.isEmpty) {
      _targetSentence = 'Today is a great day to be great.';
    } else {
      _targetSentence = sentences[random.nextInt(sentences.length)];
    }
    if (mounted) setState(() {});
  }

  /// Starts the countdown timer. If it reaches zero, the alarm is restarted.
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 0) {
        _countdownTimer?.cancel();
        _restartAlarm();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  /// Calls the native side to restart the alarm if the user fails the challenge.
  Future<void> _restartAlarm() async {
    if (_effectiveAlarmId == null) {
      debugPrint("Cannot restart alarm: Alarm ID is missing.");
      return;
    }
    try {
      debugPrint("Restarting alarm via native channel for ID: $_effectiveAlarmId");
      await _nativeChannel.invokeMethod('restartAlarmFromFlutter', {'alarmId': _effectiveAlarmId});
    } catch (e) {
      debugPrint("Failed to invoke restartAlarmFromFlutter: $e");
    }
  }

  /// Called every time the text in the TextField changes.
  void _onInputChanged(String value) {
    setState(() => _currentInput = value);

    // Verify if the typed text matches the target sentence
    if (_currentInput == _targetSentence) {
      _onChallengeCompleted();
    }
  }

  /// Called when the user successfully types the target sentence.
  void _onChallengeCompleted() {
    _countdownTimer?.cancel();

    // Cancel the native alarm since the challenge was completed
    if (_effectiveAlarmId != null) {
      _nativeChannel.invokeMethod('cancelNativeAlarm', {'id': _effectiveAlarmId});
    }

    // Navigate to the success screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GoodMorningPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent user from leaving
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
            child: _targetSentence.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Wake-Up Challenge',
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
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: _buildStyledTextSpans(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _textController,
                        autofocus: true,
                        cursorColor: Colors.tealAccent,
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white12,
                          hintText: 'Type here...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _onInputChanged,
                      ),
                      const Spacer(),
                      _buildTimerUI(),
                      const SizedBox(height: 40),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Builds the list of TextSpans to show character-by-character validation.
  List<TextSpan> _buildStyledTextSpans() {
    return List.generate(_targetSentence.length, (i) {
      final bool isTyped = i < _currentInput.length;
      final bool isCorrect = isTyped && _currentInput[i] == _targetSentence[i];

      Color color;
      if (isCorrect) {
        color = Colors.tealAccent;
      } else if (isTyped) {
        color = Colors.redAccent;
      } else {
        color = Colors.white54;
      }

      return TextSpan(
        text: _targetSentence[i],
        style: TextStyle(
          fontSize: 22,
          fontFamily: 'FiraCode', // A monospaced font is good for this
          letterSpacing: 0.5,
          color: color,
        ),
      );
    });
  }

  /// Builds the circular timer widget.
  Widget _buildTimerUI() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: _secondsRemaining / _totalDurationSeconds,
              strokeWidth: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.tealAccent),
            ),
          ),
          Text(
            '$_secondsRemaining',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent,
            ),
          ),
        ],
      ),
    );
  }
}
