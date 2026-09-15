import 'package:flutter/material.dart';

class DdiAnalyticsTab extends StatefulWidget {
  const DdiAnalyticsTab({super.key});

  @override
  State<DdiAnalyticsTab> createState() => _DdiAnalyticsTabState();
}

class _DdiAnalyticsTabState extends State<DdiAnalyticsTab> {
  // Composite Dynamic Distress Index (0-100)
  final double _ddiScore = 78.4;
  final String _riskCategory = 'HIGH CRISIS DISTRESS';

  // Sub-Scores
  final double _acousticContribution = 24.0; // max 30
  final double _semanticContribution = 21.0; // max 25
  final double _behavioralContribution = 14.0; // max 20
  final double _milestoneContribution = 19.4; // max 25

  final bool _retaliationAlert = true;

  final List<Map<String, dynamic>> _milestones = const [
    {
      'date': 'Tomorrow (Sep 16)',
      'title': 'Cross-Examination testimony',
      'court': 'District & Sessions Court, Varanasi',
      'riskImpact': '+25% Distress Spike',
      'type': 'high'
    },
    {
      'date': 'Sep 22, 2026',
      'title': 'Accused Bail Hearing Review',
      'court': 'Allahabad High Court',
      'riskImpact': '+18% Threat Elevation',
      'type': 'medium'
    },
    {
      'date': 'Oct 05, 2026',
      'title': 'Charge-Sheet Filing Verification',
      'court': 'Special SC/ST (PoA) Court',
      'riskImpact': '+10% Administrative Milestone',
      'type': 'low'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Distress Index Gauge Banner
          _buildDdiGaugeCard(),
          const SizedBox(height: 20),

          // Sub-Radar Retaliation Alarm Banner
          if (_retaliationAlert) _buildRetaliationAlarmCard(),
          if (_retaliationAlert) const SizedBox(height: 20),

          // Acoustic Vocal Biomarker Engine Breakdown
          _buildAcousticBiomarkerSection(),
          const SizedBox(height: 20),

          // Contextual Semantic Drift Detector Section
          _buildSemanticDriftSection(),
          const SizedBox(height: 20),

          // Chronological Milestone Predictor (e-Courts & CCTNS Sync)
          _buildMilestonePredictorSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDdiGaugeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 12,
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
                  Icon(Icons.speed, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'DYNAMIC DISTRESS INDEX (DDI)',
                    style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF43F5E)),
                ),
                child: Text(
                  _riskCategory,
                  style: const TextStyle(color: Color(0xFFE11D48), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Score Gauge Row
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: _ddiScore / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _ddiScore.toStringAsFixed(1),
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                      const Text(
                        '/ 100',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildSubScoreBar('Acoustic Tremors (30%)', _acousticContribution, 30.0, const Color(0xFF7C3AED)),
                    const SizedBox(height: 8),
                    _buildSubScoreBar('Semantic Hopelessness (25%)', _semanticContribution, 25.0, const Color(0xFF0284C7)),
                    const SizedBox(height: 8),
                    _buildSubScoreBar('Behavioral Latency (20%)', _behavioralContribution, 20.0, const Color(0xFFDB2777)),
                    const SizedBox(height: 8),
                    _buildSubScoreBar('Legal Milestone Sync (25%)', _milestoneContribution, 25.0, const Color(0xFFD97706)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubScoreBar(String title, double score, double maxScore, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF334155), fontSize: 10, fontWeight: FontWeight.w600)),
            Text('${score.toStringAsFixed(1)} / $maxScore',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: score / maxScore,
          backgroundColor: Colors.white,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildRetaliationAlarmCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_moon, color: Color(0xFFE11D48), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'SUB-RADAR RETALIATION ALARM TRIGGERED',
                  style: TextStyle(color: Color(0xFF9F1239), fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  'Sudden 65% drop in victim app engagement following suspect bail order (Sep 14). Covert intimidation flagged.',
                  style: TextStyle(color: Color(0xFFBE185D), fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('VIEW', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildAcousticBiomarkerSection() {
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
              Icon(Icons.graphic_eq, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'Acoustic Vocal Biomarker Engine',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Evaluates micro-tremors, flattened fundamental frequency (f₀), jitter/shimmer variability, and hyperventilation.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBiomarkerMetricCard('Pitch Jitter (f₀)', '0.48 %', 'High Tremor', const Color(0xFFD97706)),
              const SizedBox(width: 10),
              _buildBiomarkerMetricCard('Glottal Tension', '84.2 dB', 'Acute Tension', const Color(0xFFE11D48)),
              const SizedBox(width: 10),
              _buildBiomarkerMetricCard('Speech Rate', '168 WPM', 'Hyperventilation', const Color(0xFF7C3AED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiomarkerMetricCard(String label, String value, String status, Color statusColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSemanticDriftSection() {
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
              Icon(Icons.psychology_alt, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Contextual Semantic Drift Detector',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Transformer sentiment model detecting shifts toward hopelessness, trauma reactivation, or coded fear of retaliation.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sample Text Ingested (IVRS Transcript):',
                  style: TextStyle(color: Color(0xFF0369A1), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '"I am feeling very tired of going to court again and again... what if they harm my children?"',
                  style: TextStyle(color: Color(0xFF0F172A), fontStyle: FontStyle.italic, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTag('Hopelessness Index: 82%', const Color(0xFFD97706)),
                    _buildTag('Retaliation Fear: 94%', const Color(0xFFE11D48)),
                    _buildTag('Trauma Reactivation: High', const Color(0xFF7C3AED)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMilestonePredictorSection() {
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
              Icon(Icons.timeline, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Chronological Milestone Predictor',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Synchronized with e-Courts & CCTNS databases to forecast distress spikes prior to sensitive judicial milestones.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          Column(
            children: _milestones.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFEF3C7),
                      child: const Icon(Icons.event, color: Color(0xFFD97706), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['title']!, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('${m["date"]} • ${m["court"]}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                      child: Text(m['riskImpact']!, style: const TextStyle(color: Color(0xFFB45309), fontSize: 9, fontWeight: FontWeight.bold)),
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
