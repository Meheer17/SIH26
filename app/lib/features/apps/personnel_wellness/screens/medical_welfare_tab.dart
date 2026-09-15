import 'package:flutter/material.dart';

class MedicalWelfareTab extends StatefulWidget {
  const MedicalWelfareTab({super.key});

  @override
  State<MedicalWelfareTab> createState() => _MedicalWelfareTabState();
}

class _MedicalWelfareTabState extends State<MedicalWelfareTab> {
  int _selectedTriageIndex = 0;

  final List<Map<String, dynamic>> _triageCases = [
    {
      'id': 'P-8841-MED',
      'rank': 'Havildar (Alpha Platoon)',
      'tier': 'TIER 3: CRITICAL',
      'tierColor': const Color(0xFFE11D48),
      'riskScore': 81,
      'status': 'Severe Insomnia & High-Altitude Strain',
      'lastCheckin': '30 mins ago',
      'xaiBreakdown': [
        {'factor': 'HRV Deterioration (Drop below 32ms)', 'weight': '45%', 'color': const Color(0xFFE11D48)},
        {'factor': 'Leave Rejection History (180 days no leave)', 'weight': '30%', 'color': const Color(0xFFD97706)},
        {'factor': 'Severe Insomnia & Shift Strain Patterns', 'weight': '25%', 'color': const Color(0xFF7C3AED)},
      ],
      'trajectory': [55, 62, 70, 78, 81],
    },
    {
      'id': 'P-4102-MED',
      'rank': 'Naik (Bravo Platoon)',
      'tier': 'TIER 2: MODERATE',
      'tierColor': const Color(0xFFD97706),
      'riskScore': 64,
      'status': 'Family Emergency & Financial Stress',
      'lastCheckin': '2 hours ago',
      'xaiBreakdown': [
        {'factor': 'Family Emergency Request Pending', 'weight': '50%', 'color': const Color(0xFFD97706)},
        {'factor': 'Vocal Anxiety Index', 'weight': '30%', 'color': const Color(0xFF7C3AED)},
        {'factor': 'Resting Heart Rate Spike', 'weight': '20%', 'color': const Color(0xFF0284C7)},
      ],
      'trajectory': [40, 48, 55, 60, 64],
    },
    {
      'id': 'P-9915-MED',
      'rank': 'Lance Naik (Charlie Platoon)',
      'tier': 'TIER 1: MILD',
      'tierColor': const Color(0xFF059669),
      'riskScore': 32,
      'status': 'Routine Wellness Monitoring',
      'lastCheckin': '5 hours ago',
      'xaiBreakdown': [
        {'factor': 'Post-Exercise Physical Fatigue', 'weight': '60%', 'color': const Color(0xFF059669)},
        {'factor': 'Mild Sleep Debt', 'weight': '40%', 'color': const Color(0xFF0284C7)},
      ],
      'trajectory': [38, 36, 35, 33, 32],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeCase = _triageCases[_selectedTriageIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Medical Officer & Welfare Dashboard
          _buildMedicalHeader(),
          const SizedBox(height: 20),

          // Clinical Risk Triage Queue (Tier 1, Tier 2, Tier 3)
          _buildTriageQueueCard(),
          const SizedBox(height: 20),

          // SHAP / LIME XAI Risk Breakdown for Selected Soldier
          _buildXaiRiskBreakdownCard(activeCase),
          const SizedBox(height: 20),

          // 6-Month Longitudinal Stress Trajectory
          _buildLongitudinalTrajectoryCard(activeCase),
          const SizedBox(height: 20),

          // Welfare Support Prescription Engine & Red-Flag Escalation
          _buildInterventionPrescriptionCard(activeCase),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMedicalHeader() {
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
                  Icon(Icons.medical_services_outlined, color: Color(0xFF059669), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Unit Medical Officer & Welfare Dashboard',
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
                  'DOCTOR-PATIENT CONFIDENTIAL',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Dedicated exclusively to Unit Medical Officers (MOs) and Clinical Psychologists. Handles identifiable risk notifications and orchestrates clinical interventions.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageQueueCard() {
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
              Icon(Icons.format_list_bulleted, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text(
                'Personnel Risk Triage Queue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _triageCases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final item = _triageCases[idx];
              final isSelected = _selectedTriageIndex == idx;
              final color = item['tierColor'] as Color;

              return InkWell(
                onTap: () => setState(() => _selectedTriageIndex = idx),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.15),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${item['riskScore']}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(item['id'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(item['tier'] as String, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${item['rank']} • ${item['status']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? const Color(0xFF059669) : Colors.white,
                          foregroundColor: isSelected ? Colors.white : const Color(0xFF059669),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => setState(() => _selectedTriageIndex = idx),
                        child: Text(isSelected ? 'Selected' : 'Triage', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildXaiRiskBreakdownCard(Map<String, dynamic> item) {
    final xaiList = item['xaiBreakdown'] as List<Map<String, dynamic>>;

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
            children: [
              const Icon(Icons.psychology, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(
                'Explainable AI (SHAP/LIME) Risk Attribution — ${item['id']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Clinical Risk Calculation: Score ${item['riskScore']}/100 based on multi-source biometric and HRMS data fusion.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          Column(
            children: xaiList.map((f) {
              final color = f['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(f['weight'] as String, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(f['factor'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
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

  Widget _buildLongitudinalTrajectoryCard(Map<String, dynamic> item) {
    final trajectory = item['trajectory'] as List<int>;

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
              Icon(Icons.show_chart, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Longitudinal Stress Profile Tracker (6-Month Trajectory)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Multi-source time-series tracking across postings, high-altitude rotations, and family emergency timelines.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(trajectory.length, (idx) {
              final score = trajectory[idx];
              final isHigh = score > 70;
              final color = isHigh ? const Color(0xFFE11D48) : (score > 45 ? const Color(0xFFD97706) : const Color(0xFF059669));

              return Column(
                children: [
                  Text('$score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 4),
                  Container(
                    width: 26,
                    height: (score * 0.7).toDouble(),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 6),
                  Text('M${idx + 1}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionPrescriptionCard(Map<String, dynamic> item) {
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
              Icon(Icons.health_and_safety, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Welfare Support Prescription Engine',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.send, size: 14),
            label: const Text('Prescribe Light-Duty & 14-Day Compassionate Leave', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welfare prescription dispatched for ${item['id']}. Light-duty allocation updated in HRMS.'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
