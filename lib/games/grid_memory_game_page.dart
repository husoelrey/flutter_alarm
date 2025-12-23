import 'dart:async';
import 'dart:math';

import 'package:alarm/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/native_channel_service.dart';

/// A memory game screen displayed to the user after an alarm fires.
/// The user must find all highlighted tiles to dismiss the alarm.
class GridMemoryGamePage extends StatefulWidget {
  const GridMemoryGamePage({super.key, this.alarmId});

  /// The ID of the alarm that triggered this game.
  final int? alarmId;

  @override
  State<GridMemoryGamePage> createState() => _GridMemoryGamePageState();
}

class _GridMemoryGamePageState extends State<GridMemoryGamePage> {
  // --- Game Parameters ---
  static const int gridSize = 25; // 5x5 grid
  static const int totalHints = 8; // Number of tiles to find
  static const Duration hintDuration = Duration(seconds: 3);
  static const int gameDurationSeconds = 35;

  // --- Game State ---
  int? _effectiveAlarmId;
  final Set<int> _hintIndexes = {};
  final Set<int> _foundIndexes = {};
  final Set<int> _selectedIndexes = {};

  bool _isShowingHints = true;
  int _secondsLeft = gameDurationSeconds;
  Timer? _countdownTimer;

  static const _platformChannel = MethodChannel('com.example.alarm/native');

  @override
  void initState() {
    super.initState();

    _effectiveAlarmId = widget.alarmId ?? nativeAlarmId;

    // If no alarm ID is found, the page cannot function correctly.
    if (_effectiveAlarmId == null) {
      debugPrint("Error: GridMemoryGamePage was opened without an alarmId.");
      _navigateBack();
      return;
    }

    _generateHintIndexes();
    _showHintsAndPause();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Generates a random set of indexes for the tiles to be highlighted.
  void _generateHintIndexes() {
    final random = Random();
    while (_hintIndexes.length < totalHints) {
      _hintIndexes.add(random.nextInt(gridSize));
    }
  }

  /// Briefly shows the hint tiles to the user.
  void _showHintsAndPause() {
    setState(() => _isShowingHints = true);
    Future.delayed(hintDuration, () {
      if (mounted) {
        setState(() => _isShowingHints = false);
      }
    });
  }

  /// Starts the countdown timer. If it reaches zero, the alarm is restarted.
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        _restartAlarmViaNative();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  /// Handles a user tapping on a grid tile.
  void _handleTap(int index) {
    if (_isShowingHints || _foundIndexes.contains(index)) return;

    setState(() {
      _selectedIndexes.add(index);
      if (_hintIndexes.contains(index)) {
        _foundIndexes.add(index);
      }
    });

    // Check for win condition
    if (_foundIndexes.length == totalHints) {
      _onGameWon();
    }
  }

  /// Called when the user successfully finds all hint tiles.
  void _onGameWon() {
    _countdownTimer?.cancel();
    // A short delay to show the last correct tile
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/typing', // Navigate to the next challenge
          arguments: {"alarmId": _effectiveAlarmId},
        );
      }
    });
  }

  /// Navigates back, ensuring it happens after the current build frame.
  void _navigateBack() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // --- Native Communication ---

  /// Calls the native Android/iOS code to restart the alarm sound and activity.
  void _restartAlarmViaNative() async {
    try {
      debugPrint("Time is up! Restarting alarm via native channel.");
      await _platformChannel.invokeMethod("restartAlarmFromFlutter", {
        "alarmId": _effectiveAlarmId,
      });
    } catch (e) {
      debugPrint("Failed to invoke restartAlarmFromFlutter: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent the user from leaving the screen with the back button
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.gameGradient[1], // Use a dark tone from the gradient
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _secondsLeft / gameDurationSeconds,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tileHint),
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
                  itemBuilder: (_, index) {
                    final isCorrect = _foundIndexes.contains(index);
                    final isHint = _isShowingHints && _hintIndexes.contains(index);
                    final isWronglyTapped = _selectedIndexes.contains(index) && !isCorrect;

                    Color tileColor;
                    if (isCorrect || isHint) {
                      tileColor = AppColors.tileHint;
                    } else if (isWronglyTapped) {
                      tileColor = AppColors.tileWrong;
                    } else {
                      tileColor = AppColors.tileDefault;
                    }

                    return GestureDetector(
                      onTap: () => _handleTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
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
