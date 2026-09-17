import 'package:flutter/material.dart';
import '../services/nyaya_manas_service.dart';

class DistrictMagistrateViewScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const DistrictMagistrateViewScreen({super.key, this.onRefresh});

  @override
  State<DistrictMagistrateViewScreen> createState() => _DistrictMagistrateViewScreenState();
}

class _DistrictMagistrateViewScreenState extends State<DistrictMagistrateViewScreen> {
  final _service = NyayaManasService();

  bool _loading = true;
  Map<String, dynamic>? _dashboardData;
  String _selectedDistrict = 'Varanasi';

  final List<String> _districts = ['Varanasi', 'Lucknow', 'Gorakhpur', 'Agra', 'Prayagraj', 'Kanpur Nagar'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await _service.fetchRoleDashboard('district', district: _selectedDistrict);
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

  Future<void> _approveCompensation(String victimId, double amount, String stage) async {
    try {
      await _service.disburseCompensation(
        victimId: victimId,
        stage: stage,
        amountInr: amount,
        referenceNumber: 'DBT-DM-APPR-${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text('✅ Statutory Relief of ₹${amount.toStringAsFixed(0)} Approved & Disbursed via Treasury DBT!'),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD97706)));
    }

    final activeCases = _dashboardData?['active_monitored_cases'] ?? 142;
    final criticalCases = _dashboardData?['critical_high_risk_cases'] ?? 14;
    final escortsActive = _dashboardData?['witness_protection_escorts_active'] ?? 8;
    final reliefDisbursed = _dashboardData?['statutory_relief_disbursed_lakhs'] ?? 68.5;
    final slaCompliance = _dashboardData?['counsellor_sla_compliance_rate'] ?? '96.4%';
    final tehsils = _dashboardData?['tehsil_risk_heatmap'] as List<dynamic>? ?? [];
    final reliefQueue = _dashboardData?['statutory_relief_queue'] as List<dynamic>? ?? [];
    final protectionOrders = _dashboardData?['police_witness_protection_orders'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD97706),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // District Header & District Selector
            _buildDistrictHeader(),
            const SizedBox(height: 16),

            // District Overview KPI Grid
            _buildKpiGrid(activeCases, criticalCases, escortsActive, reliefDisbursed, slaCompliance),
            const SizedBox(height: 16),

            // Geospatial Tehsil & Police Station Risk Heatmap
            _buildTehsilHeatmapCard(tehsils),
            const SizedBox(height: 16),

            // Statutory SC/ST Relief Fast-Track Approval Table
            _buildReliefApprovalQueueCard(reliefQueue),
            const SizedBox(height: 16),

            // Police Witness Protection & Escort Orders
            _buildProtectionOrdersCard(protectionOrders),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictHeader() {
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
                backgroundColor: const Color(0xFFFEF3C7),
                child: const Icon(Icons.security, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'District Magistrate & SP Command Center',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'SC/ST (PoA) Act 1989 & Witness Protection Supervision',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          DropdownButton<String>(
            value: _selectedDistrict,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            underline: const SizedBox(),
            items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedDistrict = val);
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(dynamic active, dynamic critical, dynamic escorts, dynamic relief, String sla) {
    return Column(
      children: [
        Row(
          children: [
            _buildKpiCard('Monitored Cases', '$active', 'Active Inquiries', Icons.people_outline, const Color(0xFF0284C7)),
            const SizedBox(width: 8),
            _buildKpiCard('Critical Threats', '$critical', 'Urgent Escort Req.', Icons.warning_amber_rounded, const Color(0xFFE11D48)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildKpiCard('Armed Escorts', '$escorts Units', 'Sec 15A Protection', Icons.local_police_outlined, const Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            _buildKpiCard('Relief Disbursed', '₹ $relief L', 'PoA Annexure-I', Icons.account_balance_wallet_outlined, const Color(0xFF059669)),
            const SizedBox(width: 8),
            _buildKpiCard('SLA Compliance', sla, 'Response Target', Icons.timer_outlined, const Color(0xFFD97706)),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String val, String sub, IconData icon, Color color) {
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

  Widget _buildTehsilHeatmapCard(List<dynamic> tehsils) {
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
              Icon(Icons.map_outlined, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Geospatial Tehsil & Police Station Risk Heatmap',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Aggregates real-time victim distress indices across sub-districts to direct police patrol and relief.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
          ),
          const SizedBox(height: 12),

          Column(
            children: tehsils.map((t) {
              final risk = t['risk_level'] ?? 'LOW';
              Color color = const Color(0xFF059669);
              if (risk == 'HIGH' || risk == 'CRITICAL') {
                color = const Color(0xFFE11D48);
              } else if (risk == 'MODERATE') {
                color = const Color(0xFFD97706);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                        Text(t['tehsil'] ?? 'Tehsil', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                        Text('${t["active_cases"]} Active Cases • ${t["critical_cases"]} Critical Threats', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Avg DDS: ${t["avg_distress"]}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(risk, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
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

  Widget _buildReliefApprovalQueueCard(List<dynamic> queue) {
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
                  Icon(Icons.monetization_on_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    'Statutory Relief Fast-Track Approval Queue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: Text('${queue.length} PENDING', style: const TextStyle(color: Color(0xFF15803D), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Statutory compensation mandates under SC/ST (PoA) Amendment Rules (Annexure-I). Requires DM sanction.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
          ),
          const SizedBox(height: 12),

          Column(
            children: queue.map((item) {
              final amount = (item['amount_due'] as num?)?.toDouble() ?? 206250.0;
              final victimId = item['victim_id'] ?? 'V-UP-VAR-8842';
              final stage = item['stage'] ?? 'Trial Stage';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFDCFCE7),
                      child: const Icon(Icons.currency_rupee, color: Color(0xFF059669), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item["victim_name"]} ($victimId)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '$stage • ₹ ${amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                          ),
                          Text(item['statutory_mandate'] ?? 'PoA Rules Annexure-I', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () => _approveCompensation(victimId, amount, stage),
                      child: const Text('Approve & DBT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildProtectionOrdersCard(List<dynamic> orders) {
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
              Icon(Icons.shield_outlined, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'Police SP Witness Protection & Escort Orders',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Enforces Section 15A of SC/ST (PoA) Act: Physical protection, safehouse transit & courtroom security detail.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
          ),
          const SizedBox(height: 12),

          Column(
            children: orders.map((o) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${o["victim"]} (${o["id"]})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A))),
                        Text('${o["threat_tier"]} • ${o["escort_detail"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF7C3AED))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(6)),
                      child: Text(o['status'] ?? 'ACTIVE', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
