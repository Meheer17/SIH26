import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';

class ArogyaSathiScreen extends StatefulWidget {
  const ArogyaSathiScreen({super.key});

  @override
  State<ArogyaSathiScreen> createState() => _ArogyaSathiScreenState();
}

class _ArogyaSathiScreenState extends State<ArogyaSathiScreen> {
  final ApiClient _apiClient = ApiClient();
  final _authService = AuthService();

  final _hrController = TextEditingController(text: '75');
  final _spo2Controller = TextEditingController(text: '98');
  final _bodyTempController = TextEditingController(text: '37.0');
  final _envTempController = TextEditingController(text: '39.0');
  final _humidityController = TextEditingController(text: '60');
  final _waterController = TextEditingController(text: '45');
  
  String _selectedActivity = 'moderate';
  bool _isLoading = false;
  Map<String, dynamic>? _latestResult;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await _apiClient.get('apps/arogya/vitals');
      setState(() {
        _history = List<dynamic>.from(res);
        if (_history.isNotEmpty) {
          _latestResult = _history.first;
        }
      });
    } catch (e) {
      debugPrint('Error loading vitals history: $e');
    }
  }

  Future<void> _submitVitals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiClient.post(
        'apps/arogya/vitals',
        body: {
          'heart_rate': double.parse(_hrController.text),
          'spo2': double.parse(_spo2Controller.text),
          'body_temp_c': double.parse(_bodyTempController.text),
          'env_temp_c': double.parse(_envTempController.text),
          'humidity_percent': double.parse(_humidityController.text),
          'activity_level': _selectedActivity,
          'time_since_water_mins': int.parse(_waterController.text),
        },
      );

      setState(() {
        _latestResult = Map<String, dynamic>.from(res);
      });
      _fetchHistory();
      
      if (res['severity'] == 'CRITICAL') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ CRITICAL RISK! Auto-dispatching SOS Alert...'),
              backgroundColor: Colors.red,
            ),
          );
        }
        await _triggerSOS();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vitals recorded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerSOS() async {
    try {
      final res = await _apiClient.post(
        'alerts/dispatch',
        body: {
          'app_context': 'arogya_sathi',
          'severity': 'CRITICAL_SOS',
          'title': 'AROGYASATHI EMERGENCY SOS',
          'message': 'SOS ALERT! Critical health stress event triggered by user. Vitals snapshot: HR ${_hrController.text} bpm, Body Temp ${_bodyTempController.text}°C, Env Temp ${_envTempController.text}°C.',
          'recipients': ['Emergency Contacts', 'Rescue Cell'],
          'metadata': {
            'heart_rate': double.parse(_hrController.text),
            'body_temp_c': double.parse(_bodyTempController.text),
          }
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('SOS Alert Dispatched'),
            content: Text('Emergency alert generated successfully! ID: ${res["alert"]["alert_id"]}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS Trigger Failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ArogyaSathi Monitor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vitals Inputs Card
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vitals Entry Form',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hrController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Heart Rate (bpm)',
                                labelStyle: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _spo2Controller,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'SpO2 (%)',
                                labelStyle: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _bodyTempController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Body Temp (°C)',
                                labelStyle: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _envTempController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Ambient Temp (°C)',
                                labelStyle: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _humidityController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Humidity (%)',
                                labelStyle: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _waterController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Water intake (mins)',
                                labelStyle: TextStyle(color: Colors.white60),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1E293B),
                        value: _selectedActivity,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Activity Level',
                          labelStyle: TextStyle(color: Colors.white60),
                        ),
                        items: ['resting', 'moderate', 'strenuous'].map((act) {
                          return DropdownMenuItem(
                            value: act,
                            child: Text(act.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedActivity = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitVitals,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Record & Analyze'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _triggerSOS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF43F5E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('🆘 Trigger Emergency SOS'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Results Card
              if (_latestResult != null) ...[
                Card(
                  color: const Color(0xFF1E293B),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stress Scorecard',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Heat Stress Score: ${_latestResult!["heat_stress_score"]}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Dehydration Risk: ${_latestResult!["dehydration_risk_percent"]}%',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'RISK TIER: ${_latestResult!["severity"]}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Advisory:',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _latestResult!["recommendations"],
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // History Section
              const Text(
                'Logs History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._history.map((h) {
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      'Stress: ${h["heat_stress_score"]} (${h["severity"]})',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Dehydration: ${h["dehydration_risk_percent"]}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    trailing: Text(
                      'HR ${h["heart_rate"]} | Temp ${h["body_temp_c"]}°C',
                      style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
