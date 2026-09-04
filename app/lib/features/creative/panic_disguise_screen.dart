import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PanicDisguiseScreen extends StatefulWidget {
  const PanicDisguiseScreen({super.key});

  @override
  State<PanicDisguiseScreen> createState() => _PanicDisguiseScreenState();
}

class _PanicDisguiseScreenState extends State<PanicDisguiseScreen> {
  String _display = "0";
  Map<String, dynamic>? _sosDispatchResult;

  void _onKey(String val) {
    setState(() {
      if (val == "C") {
        _display = "0";
      } else {
        _display = _display == "0" ? val : _display + val;
      }
    });

    if (_display.endsWith("9999=")) {
      _triggerCovertSOS("FAKE_CALCULATOR_PIN");
    }
  }

  Future<void> _triggerCovertSOS(String type) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/api/v1/covert-sos/covert-trigger'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'trigger_type': type, 'lat': 28.6139, 'lng': 77.2090}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _sosDispatchResult = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('SOS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Calculator', style: TextStyle(color: Colors.white70, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _display,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF34D399), fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  "C", "/", "*", "-",
                  "7", "8", "9", "+",
                  "4", "5", "6", "=",
                  "1", "2", "3", "0"
                ].map((btn) {
                  return ElevatedButton(
                    onPressed: () => _onKey(btn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(btn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ),
            if (_sosDispatchResult != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF991B1B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'STEALTH SOS DISPATCHED: ${_sosDispatchResult!['covert_alert_id']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
