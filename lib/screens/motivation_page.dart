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
      appBar: AppBar(
        title: Text('Uyanma Motivasyonu Ekle'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Motivasyon cümlesi gir',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addMotivation(),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addMotivation,
              child: Text('Ekle'),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _motivations.isEmpty
                  ? Text('Henüz motivasyon eklenmedi.')
                  : ListView.builder(
                itemCount: _motivations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_motivations[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
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
