import 'package:flutter/material.dart';
import '../services/phc_service.dart';

class VitalsCompanionTab extends StatefulWidget {
  const VitalsCompanionTab({super.key});

  @override
  State<VitalsCompanionTab> createState() => _VitalsCompanionTabState();
}

class _VitalsCompanionTabState extends State<VitalsCompanionTab> with SingleTickerProviderStateMixin {
  final PhcService _phcService = PhcService();

  bool _isLoading = true;
  bool _isSyncing = false;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _healthProfile;
  Map<String, dynamic>? _latestVitals;
  Map<String, dynamic>? _riskScoreData;
  Map<String, dynamic>? _hydrationData;
  Map<String, dynamic>? _trendsData;
  List<dynamic> _vitalsHistory = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _loadAllVitalsData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAllVitalsData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _phcService.getUserProfile(),
        _phcService.getHealthProfile(),
        _phcService.getLatestVitals(),
        _phcService.getHealthRiskScore(),
        _phcService.getHydrationToday(),
        _phcService.getVitalsTrends(),
        _phcService.getVitalsHistory(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as Map<String, dynamic>?;
          _healthProfile = results[1] as Map<String, dynamic>?;
          _latestVitals = results[2] as Map<String, dynamic>?;
          _riskScoreData = results[3] as Map<String, dynamic>?;
          _hydrationData = results[4] as Map<String, dynamic>?;
          _trendsData = results[5] as Map<String, dynamic>?;
          _vitalsHistory = results[6] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vitals: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLogVitalsDialog() async {
    final hrCtrl = TextEditingController(text: '${_latestVitals?['heart_rate']?.toInt() ?? 76}');
    final spo2Ctrl = TextEditingController(text: '${_latestVitals?['spo2'] ?? 98.0}');
    final tempCtrl = TextEditingController(text: '${_latestVitals?['body_temp_c'] ?? 37.0}');
    final sysCtrl = TextEditingController(text: '${_latestVitals?['systolic_bp']?.toInt() ?? 120}');
    final diaCtrl = TextEditingController(text: '${_latestVitals?['diastolic_bp']?.toInt() ?? 80}');
    String activity = 'moderate';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.monitor_heart, color: Color(0xFFDB2777)),
              SizedBox(width: 8),
              Text('Log / Sync Vital Signs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Record fresh wearable PPG/BLE readings or manual measurements to update your health risk model.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: hrCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Heart Rate (BPM)',
                    prefixIcon: Icon(Icons.favorite, color: Color(0xFFE11D48)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: spo2Ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Blood Oxygen SpO2 (%)',
                    prefixIcon: Icon(Icons.water_drop, color: Color(0xFF0284C7)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tempCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Body Temperature (°C)',
                    prefixIcon: Icon(Icons.thermostat, color: Color(0xFFD97706)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Systolic BP', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: diaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Diastolic BP', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: activity,
                  decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'resting', child: Text('Resting / Sedentary')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderate (Walking / Field Duty)')),
                    DropdownMenuItem(value: 'strenuous', child: Text('Strenuous Labor / High Sun')),
                  ],
                  onChanged: (val) => setDialogState(() => activity = val ?? 'moderate'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isSyncing = true);
                final res = await _phcService.syncVitals({
                  'heart_rate': double.tryParse(hrCtrl.text) ?? 75.0,
                  'spo2': double.tryParse(spo2Ctrl.text) ?? 98.0,
                  'body_temp_c': double.tryParse(tempCtrl.text) ?? 37.0,
                  'systolic_bp': double.tryParse(sysCtrl.text) ?? 120.0,
                  'diastolic_bp': double.tryParse(diaCtrl.text) ?? 80.0,
                  'activity_level': activity,
                  'ambient_temp_c': 41.5,
                  'humidity_pct': 64.0,
                });
                if (!mounted) return;
                setState(() => _isSyncing = false);
                if (res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Vital signs synced successfully to backend and evaluated.'), backgroundColor: Color(0xFF059669)),
                  );
                  _loadAllVitalsData();
                }
              },
              child: const Text('Sync to Edge Engine'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _quickAddHydration(int ml, String type) async {
    final res = await _phcService.logHydration(ml, beverageType: type);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💧 Logged +${ml}ml $type. Today: ${res['today_total_ml']} / 3500 ml (${res['progress_pct']}%)'),
          backgroundColor: const Color(0xFF0284C7),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadAllVitalsData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDB2777)));
    }

    final hr = _latestVitals?['heart_rate']?.toDouble() ?? 72.0;
    final spo2 = _latestVitals?['spo2']?.toDouble() ?? 98.0;
    final temp = _latestVitals?['body_temp_c']?.toDouble() ?? 37.0;
    final sys = _latestVitals?['systolic_bp']?.toDouble() ?? 122.0;
    final dia = _latestVitals?['diastolic_bp']?.toDouble() ?? 80.0;
    final heatIndex = _latestVitals?['heat_index_c']?.toDouble() ?? 46.8;
    final riskScore = _riskScoreData?['composite_risk_score'] ?? 38;
    final riskTier = _riskScoreData?['risk_tier'] ?? 'Moderate';
    final dominantHazard = _riskScoreData?['dominant_hazard'] ?? 'Extreme Heat Index';
    final userName = _userProfile?['full_name'] ?? 'Ramesh Chandra Patel';
    final userOccupation = _userProfile?['occupation'] ?? 'Field Officer';
    final hydrationMl = _hydrationData?['today_total_ml'] ?? 2250;
    final hydrationPct = (_hydrationData?['progress_pct'] ?? 64.2).toDouble();

    return RefreshIndicator(
      onRefresh: _loadAllVitalsData,
      color: const Color(0xFFDB2777),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header & Live Status
            _buildUserHeader(userName, userOccupation),
            const SizedBox(height: 16),

            // Health Risk Score Gauge
            _buildCompositeRiskScoreCard(riskScore, riskTier, dominantHazard),
            const SizedBox(height: 16),

            // Quick Actions & Vitals Logging
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSyncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.bluetooth_searching, size: 18),
                    label: Text(_isSyncing ? 'Syncing...' : 'Sync BLE Wearable', style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _isSyncing ? null : _showLogVitalsDialog,
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_chart_rounded, size: 18),
                  label: const Text('Manual Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showLogVitalsDialog,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Section: Current Physiological Vitals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONTINUOUS PHYSIOLOGICAL VITALS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
                ),
                Row(
                  children: [
                    FadeTransition(
                      opacity: _pulseController,
                      child: const CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 6),
                    const Text('Live Edge PPG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4 Core Vitals Grid Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildVitalCard(
                  title: 'Heart Rate (PPG)',
                  value: '${hr.toInt()} bpm',
                  status: hr > 100 ? 'Exertional Tachycardia' : 'Stable Resting Range',
                  icon: Icons.favorite,
                  color: const Color(0xFFE11D48),
                  badge: 'Baseline 70 bpm',
                ),
                _buildVitalCard(
                  title: 'Blood Oxygen (SpO2)',
                  value: '${spo2.toStringAsFixed(1)}%',
                  status: spo2 < 95 ? 'Hypoxia Warning' : 'Optimal Saturation',
                  icon: Icons.air,
                  color: const Color(0xFF0284C7),
                  badge: 'Target > 95%',
                ),
                _buildVitalCard(
                  title: 'Skin Temperature',
                  value: '${temp.toStringAsFixed(1)} °C',
                  status: 'Heat Index ${heatIndex.toStringAsFixed(1)}°C',
                  icon: Icons.thermostat,
                  color: const Color(0xFFD97706),
                  badge: '98.6 °F Equiv',
                ),
                _buildVitalCard(
                  title: 'Blood Pressure',
                  value: '${sys.toInt()}/${dia.toInt()} mmHg',
                  status: 'Stage-1 Hypertensive',
                  icon: Icons.speed,
                  color: const Color(0xFF7C3AED),
                  badge: 'Omron BLE Sync',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hydration Intelligence Card
            _buildHydrationCard(hydrationMl, hydrationPct),
            const SizedBox(height: 20),

            // Daily Activity & Sleep Recovery Card
            _buildActivityAndSleepCard(),
            const SizedBox(height: 20),

            // Vitals History Timeline
            _buildVitalsHistoryTimeline(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(String name, String occupation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFFCE7F3),
            child: const Icon(Icons.person, color: Color(0xFFDB2777), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('$occupation • Varanasi, UP', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ABHA: 91-4829-5710', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('PM-JAY Golden Card', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                    ),
                    if (_trendsData != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _trendsData?['heart_rate_trend']?['status'] ?? 'Baseline Steady',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_healthProfile != null && (_healthProfile?['chronic_conditions'] as List?)?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Monitored: ${(_healthProfile?['chronic_conditions'] as List).join(' • ')}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompositeRiskScoreCard(int score, String tier, String hazard) {
    Color tierColor = const Color(0xFF10B981);
    if (score >= 60) {
      tierColor = const Color(0xFFE11D48);
    } else if (score >= 30) {
      tierColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1.5),
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
                  Text('COMPOSITE HEALTH RISK SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
                  Text('Calculated via Edge AI Multi-Signal Fusion', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tierColor, borderRadius: BorderRadius.circular(20)),
                child: Text('$tier Risk', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('$score', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: tierColor, height: 1)),
              const Text(' / 100', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const Spacer(),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Dominant Hazard:', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    Text(hazard, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), textAlign: TextAlign.end),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Vitals (35%)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('Environment (25%)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('Hydration/Rest (20%)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              Text('Personal (20%)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard({
    required String title,
    required String value,
    required String status,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(badge, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
          Text(status, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildHydrationCard(int currentMl, double pct) {
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
              Row(
                children: const [
                  Icon(Icons.water_drop, color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 8),
                  Text('HYDRATION & HEAT STRESS SENTINEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                child: Text('$currentMl / 3500 ml', style: const TextStyle(color: Color(0xFF0369A1), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100.0).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'High heat index active (41.5°C). Replenish electrolytes every 45 minutes to prevent heat cramps.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: Color(0xFF0284C7)),
                label: const Text('+250ml Water', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFFF0F9FF),
                onPressed: () => _quickAddHydration(250, 'water'),
              ),
              ActionChip(
                avatar: const Icon(Icons.local_drink, size: 16, color: Color(0xFFD97706)),
                label: const Text('+500ml ORS Solution', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFFFFFBEB),
                onPressed: () => _quickAddHydration(500, 'ors_solution'),
              ),
              ActionChip(
                avatar: const Icon(Icons.nature, size: 16, color: Color(0xFF059669)),
                label: const Text('+300ml Coconut Water', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFFECFDF5),
                onPressed: () => _quickAddHydration(300, 'coconut_water'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityAndSleepCard() {
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
            children: const [
              Text('ACTIVITY & SLEEP RECOVERY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('Past 24 Hours', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.directions_walk, color: Color(0xFF059669), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('6,420 steps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('4.8 km • 380 kcal', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.bedtime, color: Color(0xFF7C3AED), size: 24),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('7h 25m Rest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('24% Deep • Score 82', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsHistoryTimeline() {
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
              const Text('VITALS SYNC LOGS (BACKEND)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('${_vitalsHistory.length} readings recorded', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 12),
          if (_vitalsHistory.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: Text('No historical logs recorded.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vitalsHistory.length > 5 ? 5 : _vitalsHistory.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final item = _vitalsHistory[idx];
                final hrVal = item['heart_rate'] ?? 72;
                final spo2Val = item['spo2'] ?? 98;
                final tempVal = item['body_temp_c'] ?? 37.0;
                final timeStr = item['timestamp'] != null ? item['timestamp'].toString().substring(11, 16) : '--:--';
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      ],
                    ),
                    Text('HR $hrVal bpm', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE11D48))),
                    Text('SpO2 $spo2Val%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    Text('$tempVal°C', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                      child: Text(item['hydration_status'] ?? 'Adequate', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
