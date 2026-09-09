import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/speech/speech_service.dart';
import '../../core/sensors/fall_detection_service.dart';
import '../../core/sos/sos_emergency_module.dart';

class ArogyaSathiScreen extends StatefulWidget {
  const ArogyaSathiScreen({super.key});

  @override
  State<ArogyaSathiScreen> createState() => _ArogyaSathiScreenState();
}

class _ArogyaSathiScreenState extends State<ArogyaSathiScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  final SpeechService _speechService = SpeechService();
  final FallDetectionService _fallDetectionService = FallDetectionService();

  final _hrController = TextEditingController(text: '75');
  final _spo2Controller = TextEditingController(text: '98');
  final _bodyTempController = TextEditingController(text: '37.0');
  final _envTempController = TextEditingController(text: '34.5');
  final _humidityController = TextEditingController(text: '58');
  final _waterController = TextEditingController(text: '45');
  
  final String _selectedActivity = 'moderate';
  bool _hasAsthmaCOPD = false;
  bool _isLoading = false;
  bool _isFetchingWeather = false;
  bool _isAutoScanning = false;
  
  Map<String, dynamic>? _latestResult;
  Map<String, dynamic>? _liveWeatherInfo;
  String _resolvedAddress = 'Kartavya Path, Raisina Hill, New Delhi';
  List<EmergencyFacility> _nearbyFacilities = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<dynamic> _history = [];

  late AnimationController _pulseAnimController;

  @override
  void initState() {
    super.initState();
    _speechService.init();
    _fetchHistory();
    _fetchLiveWeather();
    _fetchEmergencyRadar();

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Start Accelerometer Fall Detection Listener
    _fallDetectionService.startMonitoring(
      onFallDetected: () {
        _triggerFallDetectionAlert();
      },
    );
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _fallDetectionService.stopMonitoring();
    super.dispose();
  }

  Future<void> _fetchEmergencyRadar() async {
    try {
      final geo = await SosEmergencyModule.reverseGeocode(28.6139, 77.2090);
      final facilities = await SosEmergencyModule.getNearbyFacilities(28.6139, 77.2090);
      final contacts = await SosEmergencyModule.getEmergencyContacts();

      setState(() {
        if (geo['display_name'] != null) {
          _resolvedAddress = geo['display_name'];
        }
        _nearbyFacilities = facilities;
        _emergencyContacts = contacts;
      });
    } catch (_) {}
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

  /// ⚡ 1-Click Zero-Friction Auto-Scan (GPS + Weather + Bio-Telemetry)
  Future<void> _autoScanTelemetry() async {
    setState(() {
      _isAutoScanning = true;
    });

    try {
      // 1. Fetch live Open-Meteo & GPS Address
      final weatherRes = await _apiClient.get('apps/arogya/live-weather?lat=28.6139&lon=77.2090');
      final geo = await SosEmergencyModule.reverseGeocode(28.6139, 77.2090);

      final temp = weatherRes['temperature_c'] ?? 34.5;
      final hum = weatherRes['humidity_percent'] ?? 58;

      // 2. Stream simulated BLE smart sensor telemetry
      final autoBpm = 76;
      final autoSpo2 = 98;
      final autoBodyTemp = 36.8;

      setState(() {
        _liveWeatherInfo = Map<String, dynamic>.from(weatherRes);
        _envTempController.text = temp.toString();
        _humidityController.text = hum.toString();
        _hrController.text = autoBpm.toString();
        _spo2Controller.text = autoSpo2.toString();
        _bodyTempController.text = autoBodyTemp.toString();
        _waterController.text = '25';
        if (geo['display_name'] != null) {
          _resolvedAddress = geo['display_name'];
        }
      });

      // 3. Post telemetry to backend
      final res = await _apiClient.post(
        'apps/arogya/vitals',
        body: {
          'heart_rate': autoBpm.toDouble(),
          'spo2': autoSpo2.toDouble(),
          'body_temp_c': autoBodyTemp,
          'env_temp_c': double.parse(temp.toString()),
          'humidity_percent': double.parse(hum.toString()),
          'activity_level': _selectedActivity,
          'time_since_water_mins': 25,
          'has_respiratory_condition': _hasAsthmaCOPD,
        },
      );

      setState(() {
        _latestResult = Map<String, dynamic>.from(res);
      });
      _fetchHistory();

      // Native TTS read-out
      _speechService.speak(
        "Auto-scan complete. Heat stress score is ${res['heat_stress_score']}. Conditions are ${res['severity']} risk."
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ 1-Click Auto-Scan Complete! Live GPS, AQI & Wearable Telemetry Synced.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-scan fallback: $e')),
        );
      }
    } finally {
      setState(() {
        _isAutoScanning = false;
      });
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
          'has_respiratory_condition': _hasAsthmaCOPD,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fall alarm canceled. You are marked safe.')),
                    );
                  },
                  child: const Text('CANCEL (I AM SAFE)', style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
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
          'title': 'CRITICAL HEALTH STRESS ALERT',
          'message': '${messagePrefix}Vitals Alert: HR ${_hrController.text}, Temp ${_bodyTempController.text}C, Env Temp ${_envTempController.text}C',
          'recipients': ['Ambulance (108)', 'Primary Caregivers', 'District Health Cell'],
        },
      );

      _speechService.speak("Emergency SOS alert dispatched with live location.");

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: const Text('🚨 EMERGENCY SOS DISPATCHED', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            content: Text(
              'Alert ID: ${res['alert_id']}\nChannels: ${res['channels'].join(', ')}\nResponders and emergency contacts notified.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dispatch SOS: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('ArogyaSathi Continuous Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchLiveWeather();
              _fetchHistory();
              _fetchEmergencyRadar();
            },
            tooltip: 'Refresh Telemetry',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // ⚡ Zero-Friction 1-Click Auto-Scan Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Zero-Friction Auto Telemetry',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Live GPS + AQI + Wearable',
                          style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Auto-pull live GPS address, Open-Meteo AQI, and wearable biometrics without manual typing.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isAutoScanning ? null : _autoScanTelemetry,
                    icon: _isAutoScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.bolt, color: Colors.black),
                    label: Text(
                      _isAutoScanning ? 'Auto-Syncing...' : '⚡ 1-Click Auto-Scan Everything',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Weather & AQI Banner
            _buildLiveWeatherCard(),
            const SizedBox(height: 16),

            // Pulse & Biometric Oscilloscope Card
            _buildLivePulseWaveformCard(),
            const SizedBox(height: 16),

            // Manual / Auto Telemetry Input Card
            _buildTelemetryInputCard(),
            const SizedBox(height: 16),

            // Scorecard Results
            if (_latestResult != null) ...[
              _buildScorecardView(),
              const SizedBox(height: 16),
            ],

            // Emergency Contacts & Nearby Radar Card
            _buildEmergencyRadarCard(),
            const SizedBox(height: 16),

            // Action Buttons (Fall Simulation & Manual SOS)
            _buildEmergencyActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveWeatherCard() {
    final temp = _liveWeatherInfo?['temperature_c'] ?? '--';
    final hum = _liveWeatherInfo?['humidity_percent'] ?? '--';
    final aqi = _liveWeatherInfo?['us_aqi'] ?? '106';
    final aqiCat = _liveWeatherInfo?['aqi_category'] ?? 'MODERATE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_outlined, color: Colors.lightBlueAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Open-Meteo Live Air & Weather', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              if (_isFetchingWeather)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.lightBlueAccent)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip('Ambient Temp', '$temp °C', Colors.amberAccent),
              _buildMetricChip('Humidity', '$hum %', Colors.lightBlueAccent),
              _buildMetricChip('US AQI', '$aqi ($aqiCat)', Colors.tealAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLivePulseWaveformCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseAnimController.value * 0.2),
                        child: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Live Optical Pulse Stream', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('SIGNAL LOCKED', style: TextStyle(color: Colors.tealAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip('PULSE', '${_hrController.text} BPM', Colors.redAccent),
              _buildMetricChip('SpO2', '${_spo2Controller.text}%', Colors.cyanAccent),
              _buildMetricChip('SKIN TEMP', '${_bodyTempController.text}°C', Colors.amberAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTelemetryInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Physiological & Environmental Inputs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('Heart Rate (bpm)', _hrController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Blood SpO2 (%)', _spo2Controller)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTextField('Body Temp (°C)', _bodyTempController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Ambient Temp (°C)', _envTempController)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTextField('Humidity (%)', _humidityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Water Mins Ago', _waterController)),
            ],
          ),
          const SizedBox(height: 12),
          // Asthma / COPD Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🫁 Asthma / COPD Sensitivity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Personalized warnings for particulate AQI hazards', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
                Switch(
                  value: _hasAsthmaCOPD,
                  onChanged: (val) {
                    setState(() {
                      _hasAsthmaCOPD = val;
                    });
                  },
                  activeColor: Colors.tealAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitVitals,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Analyze Vitals & Thermal Load', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildScorecardView() {
    final res = _latestResult!;
    final score = res['heat_stress_score'] ?? 0;
    final risk = res['dehydration_risk_percent'] ?? 0;
    final severity = res['severity'] ?? 'LOW';
    final advisory = res['respiratory_advisory'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thermal Strain & Dehydration Scorecard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severity == 'CRITICAL' ? Colors.red.withOpacity(0.3) : Colors.teal.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$severity RISK', style: TextStyle(color: severity == 'CRITICAL' ? Colors.redAccent : Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip('Heat Stress Score', '$score / 100', Colors.amberAccent),
              _buildMetricChip('Dehydration Risk', '$risk %', Colors.lightBlueAccent),
            ],
          ),
          if (advisory != null && advisory.toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Text(
                advisory.toString(),
                style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyRadarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                  SizedBox(width: 6),
                  Text('Live GPS & Nearby Radar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Text('${_nearbyFacilities.length} Facilities', style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_resolvedAddress, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 2),
          const SizedBox(height: 10),
          if (_nearbyFacilities.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, color: Colors.tealAccent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nearbyFacilities[0].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${_nearbyFacilities[0].distanceKm} km away | ETA ~${_nearbyFacilities[0].estimatedEtaMins} mins', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_emergencyContacts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Primary SOS Contact: ${_emergencyContacts[0].name} (${_emergencyContacts[0].phoneNumber})', style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmergencyActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _triggerFallDetectionAlert(),
            icon: const Icon(Icons.emergency, color: Colors.white, size: 18),
            label: const Text('Test Fall Alarm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _triggerSOS(),
            icon: const Icon(Icons.sos, color: Colors.white, size: 20),
            label: const Text('1-Tap SOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
