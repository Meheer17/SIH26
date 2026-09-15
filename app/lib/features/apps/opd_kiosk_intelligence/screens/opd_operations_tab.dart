import 'package:flutter/material.dart';

class OpdOperationsTab extends StatefulWidget {
  const OpdOperationsTab({super.key});

  @override
  State<OpdOperationsTab> createState() => _OpdOperationsTabState();
}

class _OpdOperationsTabState extends State<OpdOperationsTab> {
  final List<Map<String, dynamic>> _activeRedFlags = [
    {
      'terminal': 'Kiosk #04 (Ground Floor OPD)',
      'time': '2 mins ago',
      'patient': 'Rajesh Kumar (Age 48)',
      'symptom': 'Acute Chest Tightness & Stridor',
      'action': 'Stretcher Dispatched to OPD Block A',
      'status': 'NURSING ACKNOWLEDGED',
      'color': const Color(0xFFE11D48),
    },
    {
      'terminal': 'Kiosk #12 (First Floor OPD)',
      'time': '18 mins ago',
      'patient': 'Savitri Devi (Age 64)',
      'symptom': 'Sudden Right-Side Hemiparesis',
      'action': 'Transferred to Stroke Unit',
      'status': 'RESOLVED (SLA 1.8 min)',
      'color': const Color(0xFF059669),
    },
  ];

  final List<Map<String, dynamic>> _departmentLoad = [
    {'dept': 'General Medicine OPD', 'wait': '28 min', 'load': 'HIGH (88%)', 'kiosksRouted': 142, 'color': const Color(0xFFE11D48)},
    {'dept': 'Cardiology Special OPD', 'wait': '12 min', 'load': 'MODERATE (45%)', 'kiosksRouted': 68, 'color': const Color(0xFFD97706)},
    {'dept': 'Orthopedics OPD', 'wait': '8 min', 'load': 'LOW (22%)', 'kiosksRouted': 94, 'color': const Color(0xFF059669)},
    {'dept': 'AYUSH Integrated OPD', 'wait': '5 min', 'load': 'OPTIMAL (15%)', 'kiosksRouted': 52, 'color': const Color(0xFF7C3AED)},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: OPD Superintendent & Triage Operations
          _buildOperationsHeader(),
          const SizedBox(height: 20),

          // Real-time Fleet Telemetry Metrics
          _buildFleetMetricsGrid(),
          const SizedBox(height: 20),

          // Red-Flag Emergency Dispatch Console
          _buildRedFlagDispatchConsoleCard(),
          const SizedBox(height: 20),

          // Departmental Load Balancer & Queue Optimizer
          _buildDepartmentLoadBalancerCard(),
          const SizedBox(height: 20),

          // OPD Velocity & Time-Saved Analytics
          _buildTimeSavedAnalyticsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOperationsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.local_hospital_outlined, color: Color(0xFF059669), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'OPD Operations & Triage Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Text(
                  '52 KIOSKS ONLINE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Provides OPD superintendents, nursing supervisors, and administrative staff with real-time floor telemetry, emergency red-flag dispatch, and queue balancing.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetMetricsGrid() {
    return Row(
      children: [
        _buildFleetMetricTile('Active Terminals', '52', '100% Operational', Icons.devices, const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        _buildFleetMetricTile('Avg Intake Session', '42 sec', 'Noise-Robust ASR', Icons.timer, const Color(0xFF059669)),
        const SizedBox(width: 8),
        _buildFleetMetricTile('Red-Flags Dispatched', '14', 'Avg SLA 1.8 min', Icons.warning_amber, const Color(0xFFE11D48)),
        const SizedBox(width: 8),
        _buildFleetMetricTile('Time Saved / Consult', '3.4 min', '34% Efficiency Gain', Icons.trending_up, const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _buildFleetMetricTile(String title, String value, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 12, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 14)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(subtitle, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildRedFlagDispatchConsoleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.notification_important_outlined, color: Color(0xFFE11D48)),
                  SizedBox(width: 8),
                  Text(
                    'Red-Flag Emergency Dispatch Console',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(8)),
                child: const Text('WEBHOOK AUDIO ALARM ACTIVE', style: TextStyle(color: Color(0xFFE11D48), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: _activeRedFlags.map((flag) {
              final color = flag['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(Icons.emergency, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(flag['terminal'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(width: 6),
                              Text('• ${flag["time"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                          Text('${flag["patient"]} • ${flag["symptom"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          Text('Action: ${flag["action"]}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(flag['status'] as String, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentLoadBalancerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.alt_route, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Departmental Load Balancer & Queue Router',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Predictive queue management directing completed intakes to less congested specialty OPD counters based on chief complaint acuity.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          Column(
            children: _departmentLoad.map((dept) {
              final color = dept['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dept['dept'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Row(
                      children: [
                        Text('Wait: ${dept["wait"]} • Load: ${dept["load"]}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                          child: Text('${dept["kiosksRouted"]} routed', style: const TextStyle(fontSize: 9, color: Color(0xFF0284C7))),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSavedAnalyticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.speed, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'OPD Velocity & Time-Saved Analytics (2–5 min Benchmark)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Measures time saved per doctor consultation against historical baseline, resulting in 34% faster overall hospital patient throughput.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
