import 'package:flutter/material.dart';

class VitalsAnomalyTab extends StatefulWidget {
  const VitalsAnomalyTab({super.key});

  @override
  State<VitalsAnomalyTab> createState() => _VitalsAnomalyTabState();
}

class _VitalsAnomalyTabState extends State<VitalsAnomalyTab> {
  bool _isEdgeAiScanning = false;
  String _aiScanResult = 'Edge AI Status: Baseline Normal. No acute arrhythmia or respiratory distress detected.';

  final List<Map<String, dynamic>> _vitals = [
    {
      'title': 'Heart Rate (RHR)',
      'value': '72 bpm',
      'status': 'Normal Baseline',
      'icon': Icons.favorite,
      'color': const Color(0xFFE11D48),
      'trend': 'Steady (±3 bpm)',
    },
    {
      'title': 'Blood Oxygen (SpO₂)',
      'value': '98%',
      'status': 'Optimal Oxygenation',
      'icon': Icons.bloodtype,
      'color': const Color(0xFF0284C7),
      'trend': 'Optimal Range',
    },
    {
      'title': 'Body Temperature',
      'value': '98.8 °F',
      'status': '37.1 °C Normal',
      'icon': Icons.thermostat,
      'color': const Color(0xFFD97706),
      'trend': '+0.2° Ambient Rise',
    },
    {
      'title': 'Sleep Quality',
      'value': '7.4 hrs',
      'status': '24% Deep Rest',
      'icon': Icons.bedtime,
      'color': const Color(0xFF7C3AED),
      'trend': 'Sufficient Recovery',
    },
  ];

  final List<Map<String, dynamic>> _aiRiskAssessments = [
    {
      'risk': 'Heat Stress & Dehydration Risk',
      'score': 'MODERATE (42%)',
      'color': const Color(0xFFD97706),
      'desc': 'Elevated ambient temperature (41°C) combined with moderate activity.',
      'action': 'Recommended: Hydrate with 500ml ORS electrolyte solution.',
    },
    {
      'risk': 'Cardiovascular Stress',
      'score': 'LOW (18%)',
      'color': const Color(0xFF059669),
      'desc': 'RHR and HRV metrics within normal age-adjusted range.',
      'action': 'No immediate cardiovascular alert.',
    },
    {
      'risk': 'Respiratory Distress Risk',
      'score': 'LOW (22%)',
      'color': const Color(0xFF0284C7),
      'desc': 'SpO₂ 98%, no shallow breathing or acoustic cough detected.',
      'action': 'AQI warning active; wear N95 when outdoors.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: On-Device Edge AI Vitals Monitoring
          _buildVitalsHeader(),
          const SizedBox(height: 20),

          // Vitals Grid (HR, SpO2, Temp, Sleep)
          _buildVitalsGrid(),
          const SizedBox(height: 20),

          // Edge AI Health Anomaly Detection Card
          _buildAnomalyDetectionCard(),
          const SizedBox(height: 20),

          // AI Risk Assessment Scores (Heat, Cardio, Respiratory)
          _buildRiskAssessmentsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVitalsHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.monitor_heart_outlined, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Continuous Vitals & Edge AI',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('ON-DEVICE INFERENCE', style: TextStyle(color: Color(0xFF16A34A), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Privacy-preserving continuous health monitoring. Analyzes physiological signals locally without cloud dependency.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: _vitals.length,
      itemBuilder: (context, idx) {
        final item = _vitals[idx];
        final color = item['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  CircleAvatar(radius: 12, backgroundColor: color.withValues(alpha: 0.12), child: Icon(item['icon'] as IconData, color: color, size: 14)),
                ],
              ),
              Text(item['value'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['status'] as String, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text(item['trend'] as String, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnomalyDetectionCard() {
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
                  Icon(Icons.psychology, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text(
                    'AI-Based Health Anomaly Detection',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.memory, size: 14),
                label: const Text('Run Edge AI Diagnosis', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    _isEdgeAiScanning = true;
                  });
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      setState(() {
                        _isEdgeAiScanning = false;
                        _aiScanResult = 'Edge AI Scan Complete: Heat Index 42°C detected. Micro-dehydration risk flagged (+8% RHR elevation).';
                      });
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4F46E5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isEdgeAiScanning ? 'Running on-device neural model inference...' : _aiScanResult,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3730A3)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentsCard() {
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
              Icon(Icons.assessment_outlined, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Personalized Health Risk Assessments',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: _aiRiskAssessments.map((r) {
              final color = r['color'] as Color;

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(r['score'] as String, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['risk'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(r['desc'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(r['action'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                        ],
                      ),
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
}
