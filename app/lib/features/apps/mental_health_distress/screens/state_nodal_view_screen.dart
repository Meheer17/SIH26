import 'package:flutter/material.dart';
import '../services/nyaya_manas_service.dart';

class StateNodalViewScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const StateNodalViewScreen({super.key, this.onRefresh});

  @override
  State<StateNodalViewScreen> createState() => _StateNodalViewScreenState();
}

class _StateNodalViewScreenState extends State<StateNodalViewScreen> {
  final _service = NyayaManasService();

  bool _loading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await _service.fetchRoleDashboard('state');
      if (mounted) {
        setState(() {
          _dashboardData = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    final totalVictims = _dashboardData?['total_state_registered_victims'] ?? 1420;
    final criticalCases = _dashboardData?['state_critical_distress_cases'] ?? 87;
    final preventedCrises = _dashboardData?['crisis_escalations_prevented'] ?? 342;
    final totalDisbursedCr = _dashboardData?['total_rehabilitation_disbursed_crores'] ?? 14.55;
    final counsellorRatio = _dashboardData?['counsellor_to_victim_ratio'] ?? '1 : 28';
    final districtRankings = _dashboardData?['state_district_rankings'] as List<dynamic>? ?? [];
    final categoryBreakdown = _dashboardData?['atrocity_category_breakdown'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF2563EB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State Header
            _buildStateHeader(),
            const SizedBox(height: 16),

            // State KPIs
            _buildStateKpis(totalVictims, criticalCases, preventedCrises, totalDisbursedCr, counsellorRatio),
            const SizedBox(height: 16),

            // Multi-District Comparative Table
            _buildDistrictRankingsCard(districtRankings),
            const SizedBox(height: 16),

            // Atrocity Category Breakdown
            _buildAtrocityCategoryCard(categoryBreakdown),
            const SizedBox(height: 16),

            // Resource Allocation & Policy Advisory
            _buildResourceAllocationCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFF6FF),
                child: const Icon(Icons.account_balance, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'State SC/ST Welfare Department Nodal Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Government of Uttar Pradesh • Cross-District Mental Health & Relief Oversight',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
            child: const Text('STATE CELL LIVE', style: TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStateKpis(dynamic total, dynamic critical, dynamic prevented, dynamic disbursed, String ratio) {
    return Column(
      children: [
        Row(
          children: [
            _buildKpiTile('Registered Victims', '$total', 'State Total', Icons.groups_outlined, const Color(0xFF0284C7)),
            const SizedBox(width: 8),
            _buildKpiTile('Critical Distress', '$critical', 'Urgent Action', Icons.warning_amber_rounded, const Color(0xFFE11D48)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildKpiTile('Crises Prevented', '$prevented', 'Early Intervention', Icons.verified_user_outlined, const Color(0xFF059669)),
            const SizedBox(width: 8),
            _buildKpiTile('Disbursed Relief', '₹ $disbursed Cr', 'PoA Statutory Fund', Icons.monetization_on_outlined, const Color(0xFFD97706)),
            const SizedBox(width: 8),
            _buildKpiTile('Counsellor Ratio', ratio, 'Target: 1:30', Icons.psychology_outlined, const Color(0xFF7C3AED)),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiTile(String title, String val, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 12, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 14)),
            const SizedBox(height: 6),
            Text(val, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(sub, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictRankingsCard(List<dynamic> districts) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.leaderboard_outlined, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'District-Wise Comparative League & Risk Rankings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                child: const Text('ALL 75 DISTRICTS', style: TextStyle(color: Color(0xFF2563EB), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Identifies high-risk districts requiring immediate deployment of mobile trauma units & relief reallocation.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
          ),
          const SizedBox(height: 12),

          Column(
            children: districts.map((d) {
              final status = d['status'] ?? 'GREEN';
              Color statusColor = const Color(0xFF059669);
              if (status == 'RED') {
                statusColor = const Color(0xFFE11D48);
              } else if (status == 'ORANGE') {
                statusColor = const Color(0xFFEA580C);
              } else if (status == 'YELLOW') {
                statusColor = const Color(0xFFD97706);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['district'] ?? 'District', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                        Text('${d["active_cases"]} Cases • ${d["critical_cases"]} Critical Threats', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Avg DDS: ${d["avg_distress"]}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                            Text('SLA: ${d["sla_compliance"]}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
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

  Widget _buildAtrocityCategoryCard(List<dynamic> categories) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_outline, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'Atrocity Category Breakdown & Longitudinal Distress Impact',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Categorized under SC/ST (PoA) Act: Identifies highest-trauma offense groups to focus psychological rehabilitation.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
          ),
          const SizedBox(height: 12),

          Column(
            children: categories.map((cat) {
              final pct = (cat['percentage'] as num?)?.toDouble() ?? 20.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat['category'] ?? 'Category', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                        Text('${cat["case_count"]} cases ($pct%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct / 100.0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
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

  Widget _buildResourceAllocationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'AI Resource Allocation Advisory for State Nodal Officer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14532D)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Recommend re-deploying 4 Clinical Psychologists from Agra to Gorakhpur (Avg DDS 74.2).\n• Fast-track ₹2.50 Cr statutory relief replenishment for Varanasi & Lucknow DM accounts.\n• Trigger special witness protection audit across 18 high-risk clusters.',
            style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.4),
          ),
        ],
      ),
    );
  }
}
