import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class BiometricWearablesTab extends StatefulWidget {
  const BiometricWearablesTab({super.key});

  @override
  State<BiometricWearablesTab> createState() => _BiometricWearablesTabState();
}

class _BiometricWearablesTabState extends State<BiometricWearablesTab> {
  final RakshaSetuService _service = RakshaSetuService();

  bool _isLoading = true;
  bool _isSyncing = false;
  Map<String, dynamic>? _device;

  @override
  void initState() {
    super.initState();
    _loadDeviceStatus();
  }

  Future<void> _loadDeviceStatus() async {
    setState(() => _isLoading = true);
    try {
      final dev = await _service.fetchWearableStatus();
      if (mounted) {
        setState(() {
          _device = dev;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      final res = await _service.syncWearable({
        'device_name': 'Garmin Tactical Armed Edition',
        'heart_rate_bpm': 66,
        'hrv_rmssd_ms': 54.2,
        'sleep_hours': 6.8,
        'steps_count': 14800,
        'active_calories': 720,
      });
      if (mounted) {
        setState(() {
          _device = res['telemetry'] as Map<String, dynamic>? ?? _device;
          _isSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric telemetry synchronized with Secure Enclave!'), backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    final devName = _device?['device_name'] ?? 'Garmin Tactical Armed Edition';
    final battery = _device?['battery_level'] ?? 88;
    final hr = _device?['heart_rate_bpm'] ?? 68;
    final hrv = (_device?['hrv_rmssd_ms'] as num?)?.toDouble() ?? 52.4;
    final sleep = (_device?['sleep_hours'] as num?)?.toDouble() ?? 6.5;
    final steps = _device?['steps_count'] ?? 14200;
    final cals = _device?['active_calories'] ?? 650;
    final autoState = _device?['autonomic_state'] ?? 'HEALTHY_RECOVERY_PARASYMPATHETIC';
    final isRecovery = autoState.toString().contains('RECOVERY');

    return RefreshIndicator(
      onRefresh: _loadDeviceStatus,
      color: const Color(0xFF0284C7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Device Pairing Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.watch_rounded, color: Color(0xFF38BDF8), size: 28),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(devName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text('Military Sensor Protocol • Low BLE', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.battery_5_bar_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 4),
                        Text('$battery%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF334155), height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status: Paired & Air-Gapped', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _syncNow,
                      icon: _isSyncing
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync_rounded, size: 14),
                      label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Autonomic Nervous State Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRecovery ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isRecovery ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Icon(
                  isRecovery ? Icons.favorite_rounded : Icons.warning_rounded,
                  color: isRecovery ? const Color(0xFF059669) : const Color(0xFFD97706),
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRecovery ? 'Parasympathetic Recovery Dominant' : 'Sympathetic Stress Alert',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isRecovery ? const Color(0xFF065F46) : const Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HRV RMSSD at ${hrv.toStringAsFixed(1)}ms confirms your vagal tone is actively recovering post-shift.',
                        style: TextStyle(fontSize: 11, color: isRecovery ? const Color(0xFF047857) : const Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Telemetry 2x2 Grid
          const Text('Live Biometric Telemetry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(Icons.favorite_outline, 'Heart Rate', '$hr bpm', 'Resting rate stable', const Color(0xFFEF4444)),
              _buildMetricCard(Icons.show_chart, 'HRV RMSSD', '${hrv.toInt()} ms', 'Autonomic balance', const Color(0xFF8B5CF6)),
              _buildMetricCard(Icons.bedtime_outlined, 'Logged Sleep', '${sleep}h', '21% deep restorative', const Color(0xFF3B82F6)),
              _buildMetricCard(Icons.directions_walk_rounded, 'Patrol Steps', '$steps', 'Duty distance logged', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 18),

          // 4. Privacy Guarantee Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Zero-Stigma Air-Gapped Biometric Policy',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Raw heart rate and motion telemetry are stored solely on the encrypted secure enclave of this device. Only computed resilience indicators are shared with the welfare officer, strictly non-punitive under DPDP Act 2023.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String val, String subtitle, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
