import 'package:alarm/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MotivationPage extends StatefulWidget {
  @override
  _MotivationPageState createState() => _MotivationPageState();
}

class _MotivationPageState extends State<MotivationPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _motivations = [];

  @override
  void initState() {
    super.initState();
    _loadMotivations();
  }

  Future<void> _loadMotivations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _motivations = prefs.getStringList('motivations') ?? [];
    });
  }

  Future<void> _saveMotivations() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('motivations', _motivations);
  }

  void _addMotivation() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _motivations.add(text);
        _controller.clear();
      });
      _saveMotivations();
    }
  }

  void _removeMotivation(int index) {
    setState(() {
      _motivations.removeAt(index);
    });
    _saveMotivations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Uyanma Motivasyonu Ekle'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Motivasyon cümlesi gir',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _addMotivation(),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addMotivation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: Text('Ekle'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _motivations.isEmpty
                  ? Center(child: Text('Henüz motivasyon eklenmedi.', style: TextStyle(color: AppColors.textDisabled)))
                  : ListView.separated(
                      itemCount: _motivations.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_motivations[index], style: TextStyle(color: AppColors.textPrimary)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: AppColors.error),
                            onPressed: () => _removeMotivation(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}