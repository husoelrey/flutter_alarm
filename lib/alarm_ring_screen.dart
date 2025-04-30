import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmRingScreen extends StatefulWidget {
  final int alarmId;
  const AlarmRingScreen({super.key, required this.alarmId});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _startLoopingAudio();                // ← yalnızca ses ayarımız
  }

  Future<void> _startLoopingAudio() async {
    _player = AudioPlayer();
    await _player.setSource(AssetSource('audio/un.mp3'));  // assets/audio/un.mp3
    await _player.setReleaseMode(ReleaseMode.loop);        // ⇒ sonsuz döngü
    await _player.resume();                                // ⇒ hemen çal
  }

  Future<void> _stopAndClose() async {
    await _player.stop();
    await _player.dispose();
    if (mounted) Navigator.pop(context);                   // Alarmı kapat
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade700,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              'UYANMA ZAMANI!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Icon(Icons.alarm, size: 120, color: Colors.white),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _stopAndClose,
                  child: const Text('KAPAT', style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
