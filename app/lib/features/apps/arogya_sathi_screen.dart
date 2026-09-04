import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_service.dart';
import '../../core/speech/speech_service.dart';
import '../../core/sensors/fall_detection_service.dart';

class ArogyaSathiScreen extends StatefulWidget {
  const ArogyaSathiScreen({super.key});

  @override
  State<ArogyaSathiScreen> createState() => _ArogyaSathiScreenState();
}

class _ArogyaSathiScreenState extends State<ArogyaSathiScreen> {
  final ApiClient _apiClient = ApiClient();
  final _authService = AuthService();
  final SpeechService _speechService = SpeechService();
  final FallDetectionService _fallDetectionService = FallDetectionService();

  final _hrController = TextEditingController(text: '75');
  final _spo2Controller = TextEditingController(text: '98');
  final _bodyTempController = TextEditingController(text: '37.0');
  final _envTempController = TextEditingController(text: '34.5');
  final _humidityController = TextEditingController(text: '58');
  final _waterController = TextEditingController(text: '45');
  
  String _selectedActivity = 'moderate';
  bool _isLoading = false;
  bool _isFetchingWeather = false;
  Map<String, dynamic>? _latestResult;
  Map<String, dynamic>? _liveWeatherInfo;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _speechService.init();
    _fetchHistory();
    _fetchLiveWeather();

    // Start Accelerometer Fall Detection Listener
    _fallDetectionService.startMonitoring(
      onFallDetected: () {
        _triggerFallDetectionAlert();
      },
    );
  }

  @override
  void dispose() {
    _fallDetectionService.stopMonitoring();
    super.dispose();
  }

  Future<void> _fetchLiveWeather() async {
    setState(() {
      _isFetchingWeather = true;
    });

    try {
      final res = await _apiClient.get('apps/arogya/live-weather?lat=28.6139&lon=77.2090');
      setState(() {
        _liveWeatherInfo = Map<String, dynamic>.from(res);
        _envTempController.text = res['temperature_c'].toString();
        _humidityController.text = res['humidity_percent'].toString();
      });
    } catch (e) {
      debugPrint('Error fetching live weather: $e');
    } finally {
      setState(() {
        _isFetchingWeather = false;
      });
    }
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

      // Native TTS Announcement
      final recommendations = res['recommendations'] ?? 'Maintain regular fluid intake.';
      _speechService.speak("Heat stress score is ${res['heat_stress_score']}. $recommendations");

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

  void _triggerFallDetectionAlert() {
    int countdown = 5;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 1) {
                setStateDialog(() {
                  countdown--;
                });
              } else {
                t.cancel();
                Navigator.of(context).pop();
                _triggerSOS(messagePrefix: "FALL DETECTED VIA ACCELEROMETER! ");
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                  SizedBox(width: 8),
                  Text('FALL DETECTED!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'High G-force impact detected on mobile device sensors. Triggering Emergency SOS in:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$countdown',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 48, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Press CANCEL if you are safe.',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL SOS', style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                    _triggerSOS(messagePrefix: "FALL DETECTED VIA ACCELEROMETER! ");
                  },
                  child: const Text('SEND SOS NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _triggerSOS({String messagePrefix = ""}) async {
    try {
      final res = await _apiClient.post(
        'alerts/dispatch',
        body: {
          'app_context': 'arogya_sathi',
          'severity': 'CRITICAL_SOS',
          'title': 'AROGYASATHI EMERGENCY SOS',
          'message': '${messagePrefix}Critical health event. Vitals snapshot: HR ${_hrController.text} bpm, Body Temp ${_bodyTempController.text}°C, Env Temp ${_envTempController.text}°C.',
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
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('SOS Alert Dispatched', style: TextStyle(color: Colors.white)),
            content: Text('Emergency alert generated successfully! ID: ${res["alert"]["alert_id"]}', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.indigoAccent)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text('ArogyaSathi Monitor', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: _isFetchingWeather
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                : const Icon(Icons.cloud_sync_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Sync Live Weather & AQI',
            onPressed: _fetchLiveWeather,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Open-Meteo Weather Banner
              if (_liveWeatherInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🌐 LIVE WEATHER & AIR QUALITY (OPEN-METEO)', style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Temp: ${_liveWeatherInfo!["temperature_c"]}°C | Humidity: ${_liveWeatherInfo!["humidity_percent"]}%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'AQI: ${_liveWeatherInfo!["us_aqi"]} (${_liveWeatherInfo!["aqi_category"]})',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                        onPressed: () => _triggerSOS(),
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
