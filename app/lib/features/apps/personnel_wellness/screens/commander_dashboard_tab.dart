import 'package:flutter/material.dart';

class CommanderDashboardTab extends StatefulWidget {
  const CommanderDashboardTab({super.key});

  @override
  State<CommanderDashboardTab> createState() => _CommanderDashboardTabState();
}

class _CommanderDashboardTabState extends State<CommanderDashboardTab> {
  String _selectedCompany = 'All Companies (3rd Battalion)';

  final List<Map<String, dynamic>> _companyStressIndex = [
    {
      'company': 'Alpha Company (High-Altitude Guard)',
      'usfiScore': 42,
      'status': 'MODERATE STRESS',
      'color': const Color(0xFFD97706),
      'strength': 120,
      'avgNightPatrols': '3.2 / week',
      'leaveBacklog': '14 days avg',
    },
    {
      'company': 'Bravo Company (Rapid Border Patrol)',
      'usfiScore': 78,
      'status': 'HIGH FATIGUE CRITICAL',
      'color': const Color(0xFFE11D48),
      'strength': 115,
      'avgNightPatrols': '5.8 / week',
      'leaveBacklog': '28 days avg',
    },
    {
      'company': 'Charlie Company (Reserve & Logistics)',
      'usfiScore': 24,
      'status': 'OPTIMAL READINESS',
      'color': const Color(0xFF059669),
      'strength': 130,
      'avgNightPatrols': '1.1 / week',
      'leaveBacklog': '6 days avg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Unit Commander Operational Overview
          _buildCommanderHeader(),
          const SizedBox(height: 20),

          // Unit Stress & Fatigue Index (USFI) Heatmap Grid
          _buildUsfiHeatmapCard(),
          const SizedBox(height: 20),

          // Shift & Duty Strain Forecaster & Workload Recommender
          _buildDutyStrainForecasterCard(),
          const SizedBox(height: 20),

          // De-Identified Risk Spike Alert Banner
          _buildRiskSpikeAlertCard(),
          const SizedBox(height: 20),

          // Post-Incident Operational Debrief Assistant (CISM Protocol)
          _buildPostIncidentDebriefCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCommanderHeader() {
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
                  Icon(Icons.military_tech_outlined, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Unit Commander Operational Dashboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Text(
                  'DE-IDENTIFIED METRICS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Displays aggregate platoon and company-level operational exhaustion indices. Commanders receive workload recommendations without raw individual health files.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsfiHeatmapCard() {
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
            children: const [
              Text(
                'Unit Stress & Fatigue Index (USFI) Heatmap',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              Text('3rd Battalion Summary', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 14),

          Column(
            children: _companyStressIndex.map((c) {
              final color = c['color'] as Color;
              final score = c['usfiScore'] as int;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(c['company'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(c['status'] as String, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Strength: ${c['strength']} • Night Shifts: ${c['avgNightPatrols']} • Leave Backlog: ${c['leaveBacklog']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
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

  Widget _buildDutyStrainForecasterCard() {
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
              Icon(Icons.schedule_outlined, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Shift & Duty Strain Forecaster & Rotation Recommender',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Constraint-satisfaction optimization algorithm evaluating continuous night shifts and circadian disruption to suggest squad rest days.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline, color: Color(0xFF0284C7)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recommendation: Rotate Bravo Platoon 2 to 48-hour administrative rest before next border night patrol cycle.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSpikeAlertCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'De-Identified Anomaly Risk Spike Alert',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9F1239)),
                ),
                SizedBox(height: 2),
                Text(
                  '"Platoon B shows a 38% spike in chronic fatigue indicators post-exercise; recommend 48-hour operational stand-down."',
                  style: TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostIncidentDebriefCard() {
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
              Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Post-Incident Operational Debrief Assistant (CISM Protocol)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Guides commanders through standardized Critical Incident Stress Management (CISM) debrief protocols after casualties or hostile encounters.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.play_circle_fill, size: 16),
            label: const Text('Initiate CISM Operational Debrief Session', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CISM Debrief Protocol initiated for 3rd Battalion Unit Commander.'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
