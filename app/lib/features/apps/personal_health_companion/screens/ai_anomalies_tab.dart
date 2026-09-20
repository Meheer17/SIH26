import 'package:flutter/material.dart';
import '../services/phc_service.dart';

class AiAnomaliesTab extends StatefulWidget {
  const AiAnomaliesTab({super.key});

  @override
  State<AiAnomaliesTab> createState() => _AiAnomaliesTabState();
}

class _AiAnomaliesTabState extends State<AiAnomaliesTab> {
  final PhcService _phcService = PhcService();

  bool _isLoading = true;
  bool _isScanning = false;
  List<dynamic> _anomalies = [];
  Map<String, dynamic>? _edgeAiStatus;
  Map<String, dynamic>? _lastScanResult;

  @override
  void initState() {
    super.initState();
    _loadAnomaliesData();
  }

  Future<void> _loadAnomaliesData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _phcService.getAnomalies(),
        _phcService.getEdgeAiStatus(),
      ]);

      if (mounted) {
        setState(() {
          _anomalies = results[0] as List<dynamic>? ?? [];
          _edgeAiStatus = results[1] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading anomalies: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runEdgeAiScan() async {
    setState(() => _isScanning = true);
    try {
      final scan = await _phcService.detectEdgeAiAnomalies({
        'heart_rate': 98.0,
        'spo2': 97.2,
        'body_temp_c': 37.6,
        'ambient_temp_c': 42.0,
        'humidity_pct': 65.0,
        'hydration_ml_today': 1400,
        'has_copd_asthma': false,
      });

      if (mounted) {
        setState(() {
          _lastScanResult = scan;
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚡ Edge AI Inference complete in ${scan?['latency_ms'] ?? 14} ms. ${scan?['anomalies_detected']?.length ?? 0} anomaly alerts found.'),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
        _loadAnomaliesData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edge AI scan error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dismissAnomaly(String id) async {
    final res = await _phcService.dismissAnomaly(id);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Anomaly dismissed by user.'), backgroundColor: Color(0xFF059669)),
      );
      _loadAnomaliesData();
    }
  }

  Future<void> _escalateAnomaly(String id) async {
    final res = await _phcService.escalateAnomaly(id);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Alert escalated to caregiver Sunita Patel & on-duty tele-physician.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      _loadAnomaliesData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
    }

    final latency = _edgeAiStatus?['on_device_inference_latency_ms'] ?? 34.2;
    final modelVer = _edgeAiStatus?['model_version'] ?? 'v3.2.1-quantized-int8';
    final framework = _edgeAiStatus?['framework'] ?? 'TensorFlow Lite Micro';

    return RefreshIndicator(
      onRefresh: _loadAnomaliesData,
      color: const Color(0xFF7C3AED),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Edge AI Status Banner
            _buildEdgeAiBanner(framework, modelVer, latency),
            const SizedBox(height: 16),

            // Scan Action Button & Result
            _buildScanTriggerCard(),
            const SizedBox(height: 20),

            // Anomalies List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DETECTED HEALTH ANOMALIES (AI ENGINE)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: Text('${_anomalies.length} Records', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of Detected Anomalies
            if (_anomalies.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 40),
                      SizedBox(height: 8),
                      Text('No Active Health Anomalies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Your continuous physiological readings match your personal baseline.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _anomalies.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final anom = _anomalies[idx];
                  return _buildAnomalyCard(anom);
                },
              ),
            const SizedBox(height: 20),

            // Explainable AI (XAI) Model Insight
            _buildXaiInspectorCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeAiBanner(String framework, String modelVer, dynamic latency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8B4FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.memory, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('Edge AI On-Device Sentinel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF581C87))),
                        SizedBox(width: 6),
                        Icon(Icons.lock, size: 13, color: Color(0xFF7C3AED)),
                      ],
                    ),
                    Text('$framework • $modelVer', style: const TextStyle(fontSize: 11, color: Color(0xFF7E22CE))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                child: Text('$latency ms', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6B21A8))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Zero Cloud Dependency: Raw biometric telemetry stays encrypted on-device. Multi-signal inference correlates PPG, SpO2, and IMU in real-time.',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B21A8), height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTriggerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Trigger Instant Anomaly Scan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text('Runs simulated TFLite model over latest sensor buffer', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isScanning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.bolt, size: 16),
                label: Text(_isScanning ? 'Evaluating...' : 'Run Scan'),
                onPressed: _isScanning ? null : _runEdgeAiScan,
              ),
            ],
          ),
          if (_lastScanResult != null) ...[
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.insights, size: 20, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Scan Result: ${_lastScanResult!['advice']} (Latency: ${_lastScanResult!['latency_ms']} ms)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(dynamic anom) {
    final severity = anom['severity'] ?? 'Warning';
    final isCritical = severity == 'Critical';
    final color = isCritical ? const Color(0xFFE11D48) : const Color(0xFFD97706);
    final conf = anom['confidence_pct'] ?? 88.0;
    final id = anom['id'] ?? '';
    final signals = anom['signals_correlated'] as List<dynamic>? ?? [];
    final escalated = anom['escalated'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isCritical ? Icons.crisis_alert : Icons.warning_amber_rounded, color: color, size: 20),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('$severity ($conf% Confidence)', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                child: Text(anom['status'] ?? 'Active', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(anom['anomaly_type'] ?? 'Health Deviation', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text(anom['explanation'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3)),
          const SizedBox(height: 10),

          // Correlated Signals Chips
          if (signals.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: signals.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                child: Text('• $s', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
              )).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Recommended Action Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Field Protocol: ${anom['recommended_action'] ?? 'Rest and hydrate.'}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Dismiss & Escalate
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _dismissAnomaly(id),
                  child: const Text('Dismiss', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: escalated ? const Color(0xFF94A3B8) : const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.send, size: 12),
                  label: Text(escalated ? 'Escalated' : 'Escalate Alert', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: escalated ? null : () => _escalateAnomaly(id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXaiInspectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text('EXPLAINABLE AI (XAI) DECISION BREAKDOWN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Why was the recent heat-stress anomaly flagged? Feature weight attribution:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          _buildFeatureWeightRow('Resting Heart Rate Deviation (+28%)', 0.38, const Color(0xFFE11D48)),
          const SizedBox(height: 8),
          _buildFeatureWeightRow('Ambient Thermal Index (41.5°C & WBGT 33°C)', 0.32, const Color(0xFFD97706)),
          const SizedBox(height: 8),
          _buildFeatureWeightRow('Local Air Pollutants (PM2.5: 198 µg/m³)', 0.18, const Color(0xFF0284C7)),
          const SizedBox(height: 8),
          _buildFeatureWeightRow('Fluid Intake Deficit (<1500ml today)', 0.12, const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildFeatureWeightRow(String label, double weight, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)))),
            Text('${(weight * 100).toInt()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: weight,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
