import 'package:flutter/material.dart';
import '../services/medikiosk_service.dart';

class OpdOperationsTab extends StatefulWidget {
  const OpdOperationsTab({super.key});

  @override
  State<OpdOperationsTab> createState() => _OpdOperationsTabState();
}

class _OpdOperationsTabState extends State<OpdOperationsTab> {
  final MediKioskService _service = MediKioskService();

  bool _isLoading = true;
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _analytics;
  List<dynamic> _kiosks = [];
  Map<String, dynamic>? _feedback;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final dash = await _service.getAdminDashboard();
    final ana = await _service.getAdminAnalytics();
    final k = await _service.getKiosks();
    final fb = await _service.getFeedback();

    if (mounted) {
      setState(() {
        _dashboard = dash;
        _analytics = ana;
        _kiosks = k;
        _feedback = fb;
        _isLoading = false;
      });
    }
  }

  Future<void> _restartKiosk(String kioskId) async {
    final res = await _service.restartKiosk(kioskId);
    if (mounted && res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 ${res["message"] ?? "Kiosk reboot signal sent"}'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
      _loadAdminData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
    }

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOperationsHeader(),
            const SizedBox(height: 20),
            _buildFleetMetricsGrid(),
            const SizedBox(height: 20),
            _buildDeepDiveAnalyticsCard(),
            const SizedBox(height: 20),
            _buildKioskFleetManagementCard(),
            const SizedBox(height: 20),
            _buildDepartmentLoadBalancerCard(),
            const SizedBox(height: 20),
            _buildFeedbackSentimentCard(),
            const SizedBox(height: 24),
          ],
        ),
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
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics_outlined, color: Color(0xFF059669), size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dashboard?['hospital_name'] ?? 'Hospital Administration & Analytics', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  const Text('OPD Operational Throughput • Kiosk Fleet Optimization • Bottleneck Prevention', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAdminData, tooltip: 'Refresh Metrics'),
        ],
      ),
    );
  }

  Widget _buildFleetMetricsGrid() {
    return Row(
      children: [
        _buildMetricBox('DAILY PATIENTS', '${_dashboard?["patients_served_today"] ?? 1842}', 'Target: ${_dashboard?["daily_throughput_target"] ?? 2500}', const Color(0xFF059669), Icons.people_alt),
        const SizedBox(width: 10),
        _buildMetricBox('AVG KIOSK TIME', '${_dashboard?["avg_kiosk_duration_min"] ?? 7.8}m', 'Target < 12m (Spec)', const Color(0xFF0284C7), Icons.timer),
        const SizedBox(width: 10),
        _buildMetricBox('DOCTOR TIME SAVED', '${_dashboard?["total_time_saved_doctor_hours"] ?? 92.1}h', 'Cumulative OPD Hours', const Color(0xFF7C3AED), Icons.trending_up),
        const SizedBox(width: 10),
        _buildMetricBox('COMPLETION RATE', '${_dashboard?["overall_completion_rate_pct"] ?? 91.4}%', 'DPDPA & ABDM linked', const Color(0xFFD97706), Icons.check_circle),
      ],
    );
  }

  Widget _buildMetricBox(String title, String val, String subtitle, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepDiveAnalyticsCard() {
    final topComplaints = (_analytics?['top_chief_complaints'] as List?) ?? [];
    final languages = (_analytics?['language_distribution'] as List?) ?? [];
    final funnel = (_analytics?['dropout_funnel'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('Deep-Dive OPD Analytics (Complaints, Languages & Dropouts - A2)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 14),

          // Top complaints
          const Text('Top Chief Complaints Encountered:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          ...topComplaints.map((c) {
            final pct = (c['pct'] as num).toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c['complaint'], style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B))),
                      Text('${c["count"]} pts (${pct}%)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    ],
                  ),
                  const SizedBox(height: 3),
                  LinearProgressIndicator(
                    value: pct / 100.0,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: const Color(0xFF0284C7),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),

          // Language breakdown & Dropout funnel
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bhashini Language Distribution:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    ...languages.map((l) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l['language'], style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            Text('${l["pct"]}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kiosk Completion Funnel:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    ...funnel.map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(f['stage'], style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                            Text('${f["completion_pct"]}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKioskFleetManagementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.devices, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Kiosk Fleet Operations & Telemetry (A3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Text('${_kiosks.length} Fleet Terminals', style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _kiosks.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (ctx, i) {
              final k = _kiosks[i];
              final isOnline = k['status'] == 'ONLINE';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFE11D48)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${k["id"]} — ${k["location"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('Uptime: ${k["uptime"]} • ${k["sessions_today"]} sessions today • Avg ${k["avg_time_min"]}m', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(k['status'] as String, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFE11D48))),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.restart_alt, size: 16, color: Color(0xFF0284C7)),
                        onPressed: () => _restartKiosk(k['id']),
                        tooltip: 'Remote Reboot Terminal',
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentLoadBalancerCard() {
    final depts = (_dashboard?['department_load'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.balance, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('Departmental Load Balancer & Queue Optimizer (A6)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: depts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final d = depts[i];
              final loadPct = (d['load_pct'] as num?)?.toDouble() ?? 50.0;
              final color = loadPct > 70 ? const Color(0xFFE11D48) : (loadPct > 35 ? const Color(0xFFD97706) : const Color(0xFF059669));

              return Container(
                padding: const EdgeInsets.all(12),
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
                        Text(d['dept'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('Estimated Wait: ${d["avg_wait_min"]} min • ${d["status"]}', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('${loadPct.toInt()}% LOAD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSentimentCard() {
    final feedbacks = (_feedback?['feedbacks'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.thumb_up_alt_outlined, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text('Patient Satisfaction & Feedback Sentiment (A8)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                child: Text('⭐ ${_feedback?["average_rating"] ?? 4.8} / 5.0 (${_feedback?["sentiment"] ?? "95% POSITIVE"})', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...feedbacks.map((fb) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text('${fb["rating"]}/5', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('"${fb["comments"]}" — ${fb["patient_name"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
