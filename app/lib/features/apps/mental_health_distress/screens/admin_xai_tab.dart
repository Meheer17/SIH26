import 'package:flutter/material.dart';

class AdminXaiTab extends StatefulWidget {
  const AdminXaiTab({super.key});

  @override
  State<AdminXaiTab> createState() => _AdminXaiTabState();
}

class _AdminXaiTabState extends State<AdminXaiTab> {
  // Jurisdiction Level: 0 = National, 1 = State, 2 = District
  int _selectedJurisdictionLevel = 0; 
  String _selectedDistrictFilter = 'All Districts (UP)';
  String _selectedRiskFilter = 'All Risk Levels';

  bool _zeroKnowledgeShieldActive = true;
  bool _traumaFilterActive = true;
  bool _differentialPrivacyActive = true;

  // Selected victim for XAI / Intervention dispatch
  int _selectedVictimIndex = 0;

  final List<Map<String, String>> _jurisdictions = [
    {'name': 'National Level (NHAA 14566)', 'badge': 'Central Cell', 'code': 'NAT-14566'},
    {'name': 'State Level (Uttar Pradesh)', 'badge': 'Social Justice Dept', 'code': 'UP-SJD-01'},
    {'name': 'District Level (Varanasi)', 'badge': 'DM & SP Oversight', 'code': 'VAR-DM-05'},
  ];

  final List<Map<String, dynamic>> _monitoredVictims = [
    {
      'id': 'V-UP-VAR-8842',
      'name': 'Anonymized Victim #8842',
      'district': 'Varanasi',
      'state': 'Uttar Pradesh',
      'ddiScore': 89,
      'riskLevel': 'CRITICAL HIGH',
      'riskColor': const Color(0xFFE11D48),
      'status': 'Retaliation Threat - Pre-Bail Hearing',
      'lastCheckin': '12 mins ago (Voice IVRS)',
      'interventions': ['Counselling', 'Witness Protection', 'Legal Aid'],
      'shapData': [
        {'feature': 'Acoustic Vocal Tremor & Pitch Jitter', 'weight': '+32.4%', 'color': const Color(0xFF7C3AED)},
        {'feature': 'Semantic Threat & Hopelessness Drift', 'weight': '+28.1%', 'color': const Color(0xFF0284C7)},
        {'feature': 'e-Courts Bail Hearing Milestone (<24h)', 'weight': '+24.5%', 'color': const Color(0xFFD97706)},
        {'feature': 'Unusual 36h Interaction Silence', 'weight': '+15.0%', 'color': const Color(0xFFDB2777)},
      ],
      'wellbeingHistory': [72, 75, 78, 84, 89],
    },
    {
      'id': 'V-UP-LKO-4109',
      'name': 'Anonymized Victim #4109',
      'district': 'Lucknow',
      'state': 'Uttar Pradesh',
      'ddiScore': 78,
      'riskLevel': 'HIGH DISTRESS',
      'riskColor': const Color(0xFFEA580C),
      'status': 'Social Ostracism & Economic Pressure',
      'lastCheckin': '1 hour ago (Disguised App)',
      'interventions': ['Financial Relief', 'Relocation Support'],
      'shapData': [
        {'feature': 'Economic Compensation Delay', 'weight': '+35.2%', 'color': const Color(0xFFD97706)},
        {'feature': 'Acoustic Fatigue & Flat Affect', 'weight': '+29.0%', 'color': const Color(0xFF7C3AED)},
        {'feature': 'High-Frequency Stress Keywords', 'weight': '+22.4%', 'color': const Color(0xFF0284C7)},
        {'feature': 'Social Isolation Score', 'weight': '+13.4%', 'color': const Color(0xFF059669)},
      ],
      'wellbeingHistory': [65, 68, 70, 75, 78],
    },
    {
      'id': 'V-UP-GZP-9912',
      'name': 'Anonymized Victim #9912',
      'district': 'Ghazipur',
      'state': 'Uttar Pradesh',
      'ddiScore': 42,
      'riskLevel': 'MODERATE',
      'riskColor': const Color(0xFFD97706),
      'status': 'Routine Weekly Check-in Active',
      'lastCheckin': '4 hours ago (SMS Bot)',
      'interventions': ['Counselling', 'Medical Support'],
      'shapData': [
        {'feature': 'Court Procedure Confusion', 'weight': '+40.1%', 'color': const Color(0xFF0284C7)},
        {'feature': 'Mild Vocal Anxiety', 'weight': '+25.3%', 'color': const Color(0xFF7C3AED)},
        {'feature': 'Intermittent Response Delay', 'weight': '+20.6%', 'color': const Color(0xFFDB2777)},
        {'feature': 'Baseline Trauma Memory', 'weight': '+14.0%', 'color': const Color(0xFF059669)},
      ],
      'wellbeingHistory': [55, 52, 48, 45, 42],
    },
    {
      'id': 'V-UP-KNP-1044',
      'name': 'Anonymized Victim #1044',
      'district': 'Kanpur Nagar',
      'state': 'Uttar Pradesh',
      'ddiScore': 18,
      'riskLevel': 'STABLE / LOW',
      'riskColor': const Color(0xFF059669),
      'status': 'Rehabilitation & Skill Support Phase',
      'lastCheckin': '1 day ago (IVRS 14566)',
      'interventions': ['Rehabilitation', 'Financial Relief'],
      'shapData': [
        {'feature': 'Positive Sentiment Score', 'weight': '-30.5%', 'color': const Color(0xFF059669)},
        {'feature': 'Stable Speech Tempo', 'weight': '-25.0%', 'color': const Color(0xFF0284C7)},
        {'feature': 'Regular Counselor Contact', 'weight': '-24.5%', 'color': const Color(0xFF7C3AED)},
        {'feature': 'Relocation Secured', 'weight': '-20.0%', 'color': const Color(0xFFD97706)},
      ],
      'wellbeingHistory': [40, 35, 28, 22, 18],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeVictim = _monitoredVictims[_selectedVictimIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Multi-Level Selector
          _buildMultiLevelJurisdictionHeader(),
          const SizedBox(height: 20),

          // National/State/District KPI Overview Cards
          _buildKpiOverviewGrid(),
          const SizedBox(height: 20),

          // High-Risk & Vulnerable Victims Monitoring Table
          _buildVictimsMonitoringCard(),
          const SizedBox(height: 20),

          // Explainable AI (XAI) & SHAP Inspector for Selected Victim
          _buildXaiInspectorCard(activeVictim),
          const SizedBox(height: 20),

          // 7-Point Intervention Matcher & Dispatcher
          _buildInterventionMatcherCard(activeVictim),
          const SizedBox(height: 20),

          // Continuous Monitoring & Crisis Prevention Outcomes
          _buildOutcomesAndTrendCard(activeVictim),
          const SizedBox(height: 20),

          // Zero-Knowledge Privacy & Ethics Layer
          _buildPrivacyEthicsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMultiLevelJurisdictionHeader() {
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
                  Icon(Icons.dashboard_customize, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Administrative Oversight Dashboard',
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
                child: Row(
                  children: const [
                    CircleAvatar(radius: 4, backgroundColor: Color(0xFF4F46E5)),
                    SizedBox(width: 6),
                    Text(
                      'NHAA 14566 LIVE SYNC',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Multi-tiered monitoring of vulnerable victims, early distress crisis prediction, and automated intervention dispatching across District, State, and National levels.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Jurisdiction Level Switcher (National / State / District)
          Row(
            children: List.generate(_jurisdictions.length, (idx) {
              final item = _jurisdictions[idx];
              final isSelected = _selectedJurisdictionLevel == idx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedJurisdictionLevel = idx),
                  child: Container(
                    margin: EdgeInsets.only(right: idx == 2 ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item['badge']!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFFC7D2FE) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['name']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiOverviewGrid() {
    return Row(
      children: [
        _buildKpiCard('Vulnerable Monitored', '1,420', 'Victims & Witnesses', Icons.people_outline, const Color(0xFF0284C7)),
        const SizedBox(width: 10),
        _buildKpiCard('Critical High-Risk', '48', 'DDI Score > 75', Icons.warning_amber_rounded, const Color(0xFFE11D48)),
        const SizedBox(width: 10),
        _buildKpiCard('Interventions Active', '312', '7 Statutory Categories', Icons.health_and_safety_outlined, const Color(0xFF059669)),
        const SizedBox(width: 10),
        _buildKpiCard('Avg SLA Response', '14.2 min', 'Closed-Loop Response', Icons.timer_outlined, const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: accentColor)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildVictimsMonitoringCard() {
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
                  Icon(Icons.remove_red_eye_outlined, color: Color(0xFFE11D48)),
                  SizedBox(width: 8),
                  Text(
                    'Vulnerable Victims & High-Risk Case Feed',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedRiskFilter,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                    underline: const SizedBox(),
                    items: ['All Risk Levels', 'Critical High', 'High Distress', 'Moderate', 'Stable']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRiskFilter = val!),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _monitoredVictims.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final v = _monitoredVictims[idx];
              final isSelected = _selectedVictimIndex == idx;

              return InkWell(
                onTap: () => setState(() => _selectedVictimIndex = idx),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Dynamic Distress Index (DDI) Gauge Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (v['riskColor'] as Color).withValues(alpha: 0.15),
                          border: Border.all(color: v['riskColor'] as Color, width: 2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${v['ddiScore']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: v['riskColor'] as Color,
                                ),
                              ),
                              const Text('DDI', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                            ],
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
                                Text(
                                  v['id'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (v['riskColor'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    v['riskLevel'] as String,
                                    style: TextStyle(color: v['riskColor'] as Color, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${v['district']}, ${v['state']} • ${v['status']}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              children: (v['interventions'] as List<String>).map((i) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(i, style: const TextStyle(fontSize: 9, color: Color(0xFF334155))),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(v['lastCheckin'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                              foregroundColor: isSelected ? Colors.white : const Color(0xFF4F46E5),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFC7D2FE)),
                              ),
                            ),
                            icon: Icon(isSelected ? Icons.check_circle : Icons.query_stats, size: 14),
                            label: Text(isSelected ? 'Selected' : 'Inspect XAI', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            onPressed: () => setState(() => _selectedVictimIndex = idx),
                          ),
                        ],
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

  Widget _buildXaiInspectorCard(Map<String, dynamic> victim) {
    final shapList = victim['shapData'] as List<Map<String, dynamic>>;

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
                children: [
                  const Icon(Icons.psychology_outlined, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Text(
                    'SHAP / LIME Explainable AI (XAI) Inspector — ${victim['id']}',
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                child: const Text('HUMAN-AUDITABLE', style: TextStyle(color: Color(0xFF7C3AED), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Deconstructs Dynamic Distress Index (DDI ${victim['ddiScore']}/100) into explainable risk weights, eliminating opaque AI bias.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          Column(
            children: shapList.map((item) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['weight'] as String,
                        style: TextStyle(color: item['color'] as Color, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['feature'] as String,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                    ),
                    const Icon(Icons.analytics_outlined, color: Color(0xFF94A3B8), size: 16),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionMatcherCard(Map<String, dynamic> victim) {
    final interventions = [
      {'title': '1. Tele-Counseling & Mental Health', 'desc': 'Tele-MANAS 14416 & Dialect IVRS Therapist', 'icon': Icons.support_agent, 'color': const Color(0xFF4F46E5), 'active': true},
      {'title': '2. Emergency Medical Treatment', 'desc': 'Distress Psychiatric & Trauma Mobile Unit', 'icon': Icons.medical_services_outlined, 'color': const Color(0xFFE11D48), 'active': true},
      {'title': '3. Armed Witness Protection', 'desc': 'SC/ST Witness Protection Scheme Escort Detail', 'icon': Icons.shield_outlined, 'color': const Color(0xFF0284C7), 'active': true},
      {'title': '4. Safe Relocation Support', 'desc': 'Inter-District Safehouse & Housing Transit', 'icon': Icons.home_work_outlined, 'color': const Color(0xFFD97706), 'active': false},
      {'title': '5. Statutory Financial Assistance', 'desc': 'SC/ST PoA Rule 12(4) Relief Compensation Disbursement', 'icon': Icons.account_balance_wallet_outlined, 'color': const Color(0xFF059669), 'active': true},
      {'title': '6. Free Legal Aid & DLSA Advocate', 'desc': 'District Legal Services Authority Assigned Defense', 'icon': Icons.gavel_outlined, 'color': const Color(0xFF7C3AED), 'active': true},
      {'title': '7. Rehabilitation & Skill Grant', 'desc': 'Vocational Training & Educational Stipend', 'icon': Icons.school_outlined, 'color': const Color(0xFFDB2777), 'active': false},
    ];

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
                  Icon(Icons.health_and_safety, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    '7-Point Prescriptive Intervention Matcher & Dispatcher',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.send, size: 14),
                label: const Text('DISPATCH ALL MATCHED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Intervention Package Dispatched for ${victim['id']} to District Magistrate & DLSA!'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Recommends and dispatches statutory relief measures mandated under SC/ST (Prevention of Atrocities) Act & Witness Protection Scheme.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          Column(
            children: interventions.map((item) {
              final isActive = item['active'] as bool;
              final color = item['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(item['icon'] as IconData, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            item['desc'] as String,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeTrackColor: color,
                      onChanged: (val) {
                        setState(() {
                          item['active'] = val;
                        });
                      },
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

  Widget _buildOutcomesAndTrendCard(Map<String, dynamic> victim) {
    final history = victim['wellbeingHistory'] as List<int>;

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
              Icon(Icons.trending_up, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'Continuous Well-being Monitoring & Early Crisis Detection',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Expected Outcome: Early detection and prevention of mental health crises before retaliation or self-harm.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          // Well-being trend visualization bars
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('5-Week Distress Index (DDI) Trajectory:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(history.length, (idx) {
                    final val = history[idx];
                    final isHigh = val > 75;
                    final barColor = isHigh ? const Color(0xFFE11D48) : (val > 40 ? const Color(0xFFD97706) : const Color(0xFF059669));

                    return Column(
                      children: [
                        Text('$val', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: barColor)),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: (val * 0.8).toDouble(),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('W${idx + 1}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyEthicsCard() {
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
              Icon(Icons.security, color: Color(0xFF475569)),
              SizedBox(width: 8),
              Text(
                'Explainable AI, Privacy Protection & Ethical Standards Layer',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Guarantees strict compliance with SC/ST Act confidentiality, Zero-Knowledge encryption, and HIPAA data isolation standards.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Zero-Knowledge Consent & Legal Subpoena Isolation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Protects mental health therapy logs from being subpoenaed in adversarial cross-examinations.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _zeroKnowledgeShieldActive,
            activeTrackColor: const Color(0xFF059669),
            onChanged: (val) => setState(() => _zeroKnowledgeShieldActive = val),
          ),
          const Divider(color: Color(0xFFE2E8F0)),
          SwitchListTile(
            title: const Text('Differential Privacy & Anonymized Aggregation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Ensures district/state dashboards cannot be reverse-engineered to identify individual victims.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _differentialPrivacyActive,
            activeTrackColor: const Color(0xFF0284C7),
            onChanged: (val) => setState(() => _differentialPrivacyActive = val),
          ),
          const Divider(color: Color(0xFFE2E8F0)),
          SwitchListTile(
            title: const Text('Trauma-Informed Ethics & Phrasing Guardrails', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Filters out insensitive algorithmic outputs to prevent re-traumatization during interactions.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _traumaFilterActive,
            activeTrackColor: const Color(0xFF4F46E5),
            onChanged: (val) => setState(() => _traumaFilterActive = val),
          ),
        ],
      ),
    );
  }
}
