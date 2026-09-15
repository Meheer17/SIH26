import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class AuthorityDashboardScreen extends StatefulWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  State<AuthorityDashboardScreen> createState() => _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState extends State<AuthorityDashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  String _selectedTier = 'district'; // 'district', 'state', 'national'
  bool _isLoading = false;

  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? _xaiData;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchXaiBreakdown();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiClient.get('apps/nyaya/dashboard-stats?tier=$_selectedTier');
      setState(() {
        _dashboardStats = Map<String, dynamic>.from(res);
      });
    } catch (e) {
      // Offline fallback stats
      setState(() {
        _dashboardStats = {
          "tier": _selectedTier,
          "active_monitored_cases": 1420,
          "high_risk_cases_count": 87,
          "crisis_escalations_prevented": 342,
          "average_distress_score": 42.8,
          "rehabilitation_disbursements_lakhs": 145.5,
          "legal_aid_attorneys_allocated": 128,
          "district_risk_heatmap": [
            {"district": "Varanasi", "risk_level": "HIGH", "active_cases": 18, "avg_distress": 68.4},
            {"district": "Lucknow", "risk_level": "MODERATE", "active_cases": 24, "avg_distress": 45.2},
            {"district": "Gorakhpur", "risk_level": "CRITICAL", "active_cases": 12, "avg_distress": 78.9},
            {"district": "Agra", "risk_level": "LOW", "active_cases": 9, "avg_distress": 28.1}
          ],
          "longitudinal_stage_breakdown": {
            "fir_stage_count": 420,
            "chargesheet_stage_count": 510,
            "special_court_trial_count": 380,
            "conviction_rehabilitation_count": 110
          }
        };
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchXaiBreakdown() async {
    try {
      final res = await _apiClient.post(
        'apps/nyaya/xai-breakdown',
        body: {'victim_id': 'VICTIM-8842', 'distress_score': 72},
      );
      setState(() {
        _xaiData = res['xai_breakdown'] ?? res;
      });
    } catch (e) {
      setState(() {
        _xaiData = {
          "victim_id": "VICTIM-8842",
          "distress_score": 72,
          "xai_model_version": "NyayaXAI-LIME-v2.1",
          "primary_trigger": "Court Date Proximity",
          "feature_contributions": [
            {"feature": "Court Hearing Date Proximity", "weight_percent": 35, "impact": "HIGH_STRESS_FACTOR"},
            {"feature": "Voice Tremor & Acoustic Pitch Jitter", "weight_percent": 25, "impact": "BIOMETRIC_DISTRESS"},
            {"feature": "NLP Text Sentiment Polarity", "weight_percent": 20, "impact": "PSYCHOLOGICAL_DEPRESSION"},
            {"feature": "Engagement Delay / Missed Check-in", "weight_percent": 20, "impact": "ISOLATION_RISK"}
          ],
          "compliance": "SC/ST (PoA) Act 1989 Section 15A & DPDP Act 2023 Compliant"
        };
      });
    }
  }

  void _switchTier(String tier) {
    setState(() {
      _selectedTier = tier;
    });
    _fetchStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Row(
          children: [
            Icon(Icons.query_stats_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Text(
              'Multi-Tier Authority Dashboard',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tier Switcher Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTierTab('district', 'District (DM/SP)'),
                    _buildTierTab('state', 'State Nodal'),
                    _buildTierTab('national', 'National 14566'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Overview Key Performance Metrics
              if (_dashboardStats != null) ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      label: 'Monitored Victims',
                      value: '${_dashboardStats!["active_monitored_cases"]}',
                      subtitle: 'Active Cases',
                      color: const Color(0xFF0D9488),
                      icon: Icons.groups_rounded,
                    ),
                    _buildStatCard(
                      label: 'High-Risk Alerts',
                      value: '${_dashboardStats!["high_risk_cases_count"]}',
                      subtitle: 'Escalation Dispatched',
                      color: const Color(0xFFE11D48),
                      icon: Icons.warning_rounded,
                    ),
                    _buildStatCard(
                      label: 'Crises Prevented',
                      value: '${_dashboardStats!["crisis_escalations_prevented"]}',
                      subtitle: 'Early Detection',
                      color: const Color(0xFF10B981),
                      icon: Icons.shield_rounded,
                    ),
                    _buildStatCard(
                      label: 'Rehabilitation DBT',
                      value: '₹${_dashboardStats!["rehabilitation_disbursements_lakhs"]} L',
                      subtitle: 'Direct Disbursal',
                      color: const Color(0xFFD97706),
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // District Risk Heatmap List
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'District Vulnerability Heatmap',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Text('SC/ST PoA Cells', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ...(_dashboardStats!['district_risk_heatmap'] as List? ?? []).map((item) {
                        final isCritical = item['risk_level'] == 'CRITICAL';
                        final isHigh = item['risk_level'] == 'HIGH';
                        final color = isCritical ? const Color(0xFFE11D48) : (isHigh ? const Color(0xFFD97706) : const Color(0xFF10B981));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'District ${item["district"]}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                                ),
                              ),
                              Text(
                                'Cases: ${item["active_cases"]} | Avg Distress: ${item["avg_distress"]}%',
                                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Explainable AI (XAI) Risk Decomposition Card
              if (_xaiData != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_graph_rounded, color: Color(0xFF4F46E5), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Explainable AI (XAI) Risk Audit',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('LIME EXPLAINER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deconstructing Case #${_xaiData!["victim_id"]} (Distress Score: ${_xaiData!["distress_score"]}%):',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 12),

                      ...(_xaiData!['feature_contributions'] as List? ?? []).map((feat) {
                        final weight = feat['weight_percent'] as int;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(feat['feature'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                  Text('$weight%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
                                ],
                              ),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: weight / 100.0,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Legal Compliance: ${_xaiData!["compliance"]}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierTab(String tierKey, String label) {
    final isSelected = _selectedTier == tierKey;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTier(tierKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
