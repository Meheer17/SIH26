import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/alerts/alert_notification_engine.dart';
import '../../core/sos/sos_emergency_module.dart';

class SosDemoScreen extends StatefulWidget {
  const SosDemoScreen({super.key});

  @override
  State<SosDemoScreen> createState() => _SosDemoScreenState();
}

class _SosDemoScreenState extends State<SosDemoScreen> {
  String _selectedAppContext = 'arogya_sathi';
  bool _isCountdownActive = false;
  int _countdownSeconds = 5;
  StreamSubscription<int>? _countdownSub;
  String _statusConsole = 'System Ready. Tap big SOS button or dispatch alerts below.';

  final List<AppAlertRecord> _localAlerts = [];

  final Map<String, String> _appsMap = {
    'arogya_sathi': '🫀 ArogyaSathi (Heatstroke / Fall Alert)',
    'medikiosk': '🏥 MediKiosk (OPD Triage Red-Flag)',
    'rakshak_mitra': '🎖️ RakshakMitra (Personnel Crisis)',
    'nyaya_sahay': '⚖️ NyayaSahay (Victim Threat Intimidation)',
  };

  @override
  void initState() {
    super.initState();
    AlertNotificationEngine.alertStream.listen((alert) {
      setState(() {
        _localAlerts.insert(0, alert);
        _statusConsole = '🚨 New Alert Dispatched!\n[${alert.severity.name.toUpperCase()}] ${alert.title}\nChannels: ${alert.channels.join(", ")}';
      });
    });
  }

  @override
  void dispose() {
    _countdownSub?.cancel();
    super.dispose();
  }

  void _triggerOneTapSos() async {
    setState(() {
      _isCountdownActive = true;
      _statusConsole = '🚨 ONE-TAP SOS ACTIVATED! Siren pulsing. 5-second cancel window active...';
    });

    _countdownSub?.cancel();
    _countdownSub = SosEmergencyModule.countdownStream.listen((sec) {
      setState(() {
        _countdownSeconds = sec;
      });
    });

    await SosEmergencyModule.triggerSos(
      appContext: _selectedAppContext,
      userId: 'P-1004',
      userName: 'Rahul Verma',
      location: SosLocation(
        latitude: 32.2432,
        longitude: 77.1892,
        addressName: 'Lahaul Spiti High Altitude Outpost',
      ),
      healthSnapshot: SosHealthSnapshot(
        heartRate: 115,
        bodyTempC: 38.9,
        heatIndex: 52.4,
        triageStatus: 'CRITICAL_EMERGENCY',
      ),
      emergencyContacts: ['+919876543210', '+919123456789'],
      emergencyReason: 'Extreme Heatstroke & Respiratory Distress Emergency',
      onConfirmed: (event) {
        setState(() {
          _isCountdownActive = false;
          _statusConsole = '🚨 EMERGENCY SOS CONFIRMED & DISPATCHED!\nResponders Notified: Ambulance (108), Emergency Cell, Caregiver SMS.';
        });
      },
    );
  }

  void _cancelSos() async {
    await SosEmergencyModule.cancelSos('User pressed cancel button');
    setState(() {
      _isCountdownActive = false;
      _statusConsole = '✅ Emergency SOS cancelled by user during countdown.';
    });
  }

  void _dispatchTierAlert(AlertSeverity severity) async {
    final record = await AlertNotificationEngine.dispatchAlert(
      appContext: _selectedAppContext,
      severity: severity,
      title: 'Health Threshold Warning',
      message: 'Vitals crossed risk limit for $_selectedAppContext context.',
      recipients: ['+919876543210'],
      escalationTimeoutSeconds: 10, // Short timer for demo
    );

    setState(() {
      _statusConsole = 'Dispatched [${severity.name.toUpperCase()}] Alert ID: ${record.alertId}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('SOS & Multi-Tier Alert Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Picker
                DropdownButtonFormField<String>(
                  initialValue: _selectedAppContext,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Select Application Context',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: _appsMap.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAppContext = val);
                  },
                ),
                const SizedBox(height: 24),

                // Big One-Tap Red SOS Button
                Center(
                  child: GestureDetector(
                    onTap: _isCountdownActive ? null : _triggerOneTapSos,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 8,
                          )
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sos_rounded, size: 64, color: Colors.white),
                          SizedBox(height: 4),
                          Text(
                            'ONE-TAP SOS',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Multi-Tier Alert Dispatchers
                const Text(
                  'DISPATCH MULTI-TIER ALERTS',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _dispatchTierAlert(AlertSeverity.low),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                      child: const Text('LOW (Banner)'),
                    ),
                    ElevatedButton(
                      onPressed: () => _dispatchTierAlert(AlertSeverity.moderate),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                      child: const Text('MODERATE (Push)'),
                    ),
                    ElevatedButton(
                      onPressed: () => _dispatchTierAlert(AlertSeverity.high),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                      child: const Text('HIGH (Push+SMS)'),
                    ),
                    ElevatedButton(
                      onPressed: () => _dispatchTierAlert(AlertSeverity.criticalSos),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      child: const Text('CRITICAL (All+Call)'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Console Output Display
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    _statusConsole,
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontFamily: 'monospace', height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),

                // Active Banners List
                const Text(
                  'ACTIVE IN-APP BANNERS',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 10),

                if (_localAlerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No active alert banners.', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _localAlerts.length,
                    itemBuilder: (context, idx) {
                      final alert = _localAlerts[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: alert.severity == AlertSeverity.criticalSos ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(alert.message, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ),
                            if (!alert.isAcknowledged)
                              TextButton(
                                onPressed: () {
                                  AlertNotificationEngine.acknowledgeAlert(alert.alertId);
                                  setState(() {});
                                },
                                child: const Text('ACK', style: TextStyle(color: Color(0xFF34D399))),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // 5-Second Cancel Countdown Fullscreen Overlay
          if (_isCountdownActive)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_rounded, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    const Text(
                      'DISPATCHING EMERGENCY SOS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_countdownSeconds',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 72),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _cancelSos,
                      icon: const Icon(Icons.cancel, size: 24),
                      label: const Text('CANCEL SOS (5s Window)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
