import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class CommanderDashboardTab extends StatefulWidget {
  const CommanderDashboardTab({super.key});

  @override
  State<CommanderDashboardTab> createState() => _CommanderDashboardTabState();
}

class _CommanderDashboardTabState extends State<CommanderDashboardTab> with SingleTickerProviderStateMixin {
  final RakshaSetuService _service = RakshaSetuService();

  late TabController _tabController;
  bool _isLoading = true;

  Map<String, dynamic>? _overview;
  List<dynamic> _garrisonCompanies = [];
  List<dynamic> _alerts = [];
  List<dynamic> _interventions = [];
  Map<String, dynamic>? _forecast;
  List<dynamic> _auditLogs = [];

  String _alertFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllCommanderData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCommanderData() async {
    setState(() => _isLoading = true);
    try {
      final ov = await _service.fetchCommanderOverview();
      final hm = await _service.fetchCommanderHeatmap();
      final al = await _service.fetchCommanderAlerts(priority: _alertFilter);
      final it = await _service.fetchInterventions();
      final fc = await _service.fetchCommanderForecast();
      final ad = await _service.fetchAuditLogs();

      if (mounted) {
        setState(() {
          _overview = ov;
          _garrisonCompanies = hm['garrison_companies'] as List<dynamic>? ?? [];
          _alerts = al;
          _interventions = it;
          _forecast = fc;
          _auditLogs = ad;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _actionAlert(String alertId, String action) async {
    try {
      await _service.actionCommanderAlert(alertId, action, notes: 'Handled from Commander Operations Console');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert $alertId marked as $action'), backgroundColor: const Color(0xFF16A34A)),
        );
        _service.fetchCommanderAlerts(priority: _alertFilter).then((al) {
          if (mounted) setState(() => _alerts = al);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _openAssignInterventionModal() {
    String personnelId = 'PER-CRPF-88412';
    String interventionType = 'MANDATORY_RR_LEAVE';
    final TextEditingController titleController = TextEditingController(text: 'Grant 7-Day Mandatory R&R Leave');
    final TextEditingController descController = TextEditingController(
      text: 'Immediate rest and recuperation rotation following 115 continuous outpost deployment days in high altitude.',
    );
    String priority = 'HIGH';
    int slaDays = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Assign Welfare Action (कल्याणकारी हस्तक्षेप)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: personnelId,
                      decoration: const InputDecoration(labelText: 'Target Personnel', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'PER-CRPF-88412', child: Text('Hav. Rajesh Singh (CRPF-88412)')),
                        DropdownMenuItem(value: 'PER-BSF-91024', child: Text('Ct. Amit Kumar (BSF-91024)')),
                        DropdownMenuItem(value: 'PER-ITBP-73451', child: Text('SI Priya Sharma (ITBP-73451)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => personnelId = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: interventionType,
                      decoration: const InputDecoration(labelText: 'Intervention Category', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'MANDATORY_RR_LEAVE', child: Text('Mandatory Rest & Recuperation (R&R) Leave')),
                        DropdownMenuItem(value: 'SHIFT_ROTATION', child: Text('Night Shift Duty Roster Rotation')),
                        DropdownMenuItem(value: 'CLINICAL_PSYCH_REFERRAL', child: Text('Clinical Psychologist Direct Referral')),
                        DropdownMenuItem(value: 'PEER_BUDDY_ASSIGN', child: Text('Assign Experienced Peer Buddy')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            interventionType = val;
                            if (val == 'MANDATORY_RR_LEAVE') {
                              titleController.text = 'Grant 7-Day Mandatory R&R Leave';
                            } else if (val == 'SHIFT_ROTATION') {
                              titleController.text = 'Night Shift Duty Roster Rotation';
                            } else if (val == 'CLINICAL_PSYCH_REFERRAL') {
                              titleController.text = 'Base Psychologist Evaluation Booking';
                            } else {
                              titleController.text = 'Pair with Senior Acclimatized Buddy';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Intervention Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Operational Scope & Directions', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            decoration: const InputDecoration(labelText: 'Priority Tier', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
                              DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
                              DropdownMenuItem(value: 'MODERATE', child: Text('MODERATE')),
                              DropdownMenuItem(value: 'ROUTINE', child: Text('ROUTINE')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: slaDays,
                            decoration: const InputDecoration(labelText: 'SLA Window', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('24 Hours')),
                              DropdownMenuItem(value: 3, child: Text('3 Days')),
                              DropdownMenuItem(value: 7, child: Text('7 Days')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => slaDays = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            final res = await _service.assignIntervention({
                              'personnel_id': personnelId,
                              'intervention_type': interventionType,
                              'title': titleController.text,
                              'description': descController.text,
                              'priority': priority,
                              'assigned_officer': 'Col. A. Chatterjee (Commanding Officer)',
                              'sla_days': slaDays,
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Intervention assigned to jawan!'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                              _service.fetchInterventions().then((it) {
                                if (mounted) setState(() => _interventions = it);
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Dispatch Welfare Intervention'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _viewPersonnelDossier(String personnelId) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _service.fetchPersonnelDossier(personnelId),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
            }

            final data = snapshot.data!;
            final p = data['personnel'] as Map<String, dynamic>? ?? {};
            final name = p['full_name'] ?? 'Soldier';
            final rank = p['rank'] ?? 'Havaldar';
            final belt = p['service_belt_number'] ?? 'CRPF-88412';
            final shap = data['shap_factor_breakdown'] as List<dynamic>? ?? [];

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.security, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dossier: $rank $name ($belt)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'Authorized Medical & Welfare Officer View • Logged in Security Audit Trail',
                        style: TextStyle(fontSize: 10, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('SHAP Contributing Feature Contributions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...shap.map((s) {
                      final f = s['factor'] ?? '';
                      final pts = s['contribution_points'] ?? '+10';
                      final isInc = s['direction'] == 'INCREASES_RISK';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(f, style: const TextStyle(fontSize: 11))),
                            Text(
                              pts,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isInc ? Colors.red : Colors.green),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    const Divider(),
                    Text('Current Posting: ${p['posting_location'] ?? 'Forward Border Outpost'}', style: const TextStyle(fontSize: 11)),
                    Text('Deployment Length: ${p['deployment_days'] ?? 115} Days Continuous', style: const TextStyle(fontSize: 11)),
                    Text('Duty Workload: ${p['weekly_duty_hours'] ?? 64}h / Week', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Dossier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0284C7),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0284C7),
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: 'Battalion Overview'),
              Tab(icon: Icon(Icons.map_outlined, size: 16), text: 'Garrison Heatmap'),
              Tab(icon: Icon(Icons.warning_amber_outlined, size: 16), text: 'Alert Queue'),
              Tab(icon: Icon(Icons.assignment_turned_in_outlined, size: 16), text: 'Interventions'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildHeatmapTab(),
          _buildAlertsTab(),
          _buildInterventionsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAssignInterventionModal,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text('Assign Welfare Action', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- SUBTAB 1: BATTALION OVERVIEW ---
  Widget _buildOverviewTab() {
    final unitName = _overview?['unit_name'] ?? '44th Battalion CAPF (Border Sentinel)';
    final co = _overview?['commanding_officer'] ?? 'Col. A. Chatterjee';
    final strength = _overview?['total_strength'] ?? 850;
    final deployed = _overview?['active_field_deployed'] ?? 620;
    final avgBurnout = _overview?['average_unit_burnout_index'] ?? 38.6;
    final highRisk = _overview?['high_risk_count'] ?? 12;
    final stressors = _overview?['unit_stressors'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadAllCommanderData,
      color: const Color(0xFF0284C7),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Commander Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.military_tech, color: Color(0xFF38BDF8), size: 26),
                        SizedBox(width: 8),
                        Text('Unit Command & Welfare Console', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0x3310B981), borderRadius: BorderRadius.circular(6)),
                      child: const Text('DPDP SECURE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(unitName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Commanding Officer: $co • Field Strength: $strength ($deployed Deployed)', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3 Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Unit Burnout', '$avgBurnout%', 'Moderate Resilience', const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('High Risk Watch', '$highRisk Jawans', 'Intervention Queue', const Color(0xFFEF4444)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('Active Deployed', '$deployed / $strength', '92% Roster Fit', const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Unit Stressors Breakdown
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
                const Text('Aggregated Unit Stress Drivers (समग्र तनाव कारक)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                ...stressors.map((st) {
                  final name = st['name'] ?? '';
                  final pct = (st['affected_percentage'] as num?)?.toDouble() ?? 30.0;
                  final trend = st['trend'] ?? 'STABLE';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                            Text('${pct.toInt()}% ($trend)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 30-Day Predictive Fatigue Forecast
          if (_forecast != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.trending_up, color: Color(0xFFB45309), size: 20),
                      SizedBox(width: 8),
                      Text('30-Day Predictive Fatigue Forecast (पूर्वानुमान)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_forecast!['forecast_period'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                  const SizedBox(height: 8),
                  Text(
                    'AI models predict an 18.5% stress surge during the upcoming election duty rotation. Pre-positioning relief companies from Delta Logistics is recommended.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // --- SUBTAB 2: GARRISON HEATMAP ---
  Widget _buildHeatmapTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: const [
              Icon(Icons.map, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Live Garrison Company Stress Heatmap • Color-coded by aggregated psychological strain.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ..._garrisonCompanies.map((c) {
          final name = c['name'] ?? 'Company';
          final loc = c['location'] ?? '';
          final score = (c['stress_score'] as num?)?.toDouble() ?? 50.0;
          final tier = c['risk_tier'] ?? 'MODERATE';
          final highCount = c['high_risk_personnel'] ?? 0;
          final total = c['total_strength'] ?? 100;
          final stressor = c['primary_stressor'] ?? '';

          Color tierColor = const Color(0xFF10B981);
          if (tier == 'CRITICAL') tierColor = const Color(0xFFEF4444);
          else if (tier == 'HIGH') tierColor = const Color(0xFFF97316);
          else if (tier == 'MODERATE') tierColor = const Color(0xFFF59E0B);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(loc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: tierColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '$tier (${score.toInt()}%)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tierColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.group, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('Strength: $total jawans', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                    const SizedBox(width: 14),
                    const Icon(Icons.warning, size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 4),
                    Text('High Strain: $highCount jawans', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Primary Stressor: $stressor', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _viewPersonnelDossier('PER-CRPF-88412'),
                      icon: const Icon(Icons.person_search, size: 16),
                      label: const Text('Inspect Company Dossier'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF0284C7)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- SUBTAB 3: ALERTS QUEUE ---
  Widget _buildAlertsTab() {
    return Column(
      children: [
        // Priority Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Filter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(width: 8),
              ...['ALL', 'CRITICAL', 'HIGH', 'MODERATE'].map((p) {
                final isSel = _alertFilter == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(p, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : const Color(0xFF334155))),
                    selected: isSel,
                    selectedColor: const Color(0xFF0284C7),
                    onSelected: (sel) {
                      setState(() => _alertFilter = p);
                      _service.fetchCommanderAlerts(priority: _alertFilter).then((al) {
                        if (mounted) setState(() => _alerts = al);
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _alerts.length,
            itemBuilder: (context, index) {
              final a = _alerts[index];
              final id = a['id'] ?? '';
              final title = a['title'] ?? 'Alert';
              final desc = a['description'] ?? '';
              final priority = a['priority'] ?? 'MODERATE';
              final status = a['status'] ?? 'NEW';
              final pName = a['personnel_name'] ?? 'Jawan';

              Color prioColor = const Color(0xFFF59E0B);
              if (priority == 'CRITICAL') prioColor = const Color(0xFFEF4444);
              else if (priority == 'HIGH') prioColor = const Color(0xFFF97316);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: prioColor.withOpacity(0.3)),
                  boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: prioColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: prioColor)),
                        ),
                        Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('Target: $pName', style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _actionAlert(id, 'DISMISSED'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                          child: const Text('Dismiss'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _actionAlert(id, 'ACKNOWLEDGED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Acknowledge & Act'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- SUBTAB 4: INTERVENTIONS ---
  Widget _buildInterventionsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _interventions.length,
      itemBuilder: (context, index) {
        final it = _interventions[index];
        final id = it['id'] ?? '';
        final title = it['title'] ?? 'Welfare Action';
        final desc = it['description'] ?? '';
        final pName = it['personnel_name'] ?? 'Personnel';
        final status = it['status'] ?? 'PENDING_APPROVAL';
        final priority = it['priority'] ?? 'HIGH';
        final officer = it['assigned_officer'] ?? 'Commanding Officer';

        Color statusColor = const Color(0xFFF59E0B);
        if (status == 'APPROVED' || status == 'COMPLETED') statusColor = const Color(0xFF16A34A);
        else if (status == 'IN_PROGRESS') statusColor = const Color(0xFF0284C7);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                  Text('Priority: $priority', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('Soldier: $pName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3)),
              const SizedBox(height: 8),
              Text('Assigned Officer: $officer', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              const SizedBox(height: 12),
              if (status == 'PENDING_APPROVAL')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _service.updateInterventionStatus(id, 'APPROVED', notes: 'Approved by Commanding Officer');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Intervention APPROVED & dispatched!'), backgroundColor: Color(0xFF16A34A)),
                        );
                        _service.fetchInterventions().then((res) {
                          if (mounted) setState(() => _interventions = res);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Approve & Dispatch Roster'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
