import 'package:flutter/material.dart';
import '../services/phc_service.dart';

class CaregiverProviderTab extends StatefulWidget {
  const CaregiverProviderTab({super.key});

  @override
  State<CaregiverProviderTab> createState() => _CaregiverProviderTabState();
}

class _CaregiverProviderTabState extends State<CaregiverProviderTab> with SingleTickerProviderStateMixin {
  final PhcService _phcService = PhcService();

  late TabController _segmentController;
  bool _isLoading = true;

  List<dynamic> _dependents = [];
  List<dynamic> _patients = [];
  Map<String, dynamic>? _heatmap;
  Map<String, dynamic>? _schemesData;
  List<dynamic> _devices = [];

  // Consent states
  final Map<String, bool> _consents = {
    'biometric_telemetry': true,
    'caregiver_vitals_sync': true,
    'asha_worker_escalation': true,
    'anonymized_public_health': true,
  };

  @override
  void initState() {
    super.initState();
    _segmentController = TabController(length: 3, vsync: this);
    _loadMultiRoleData();
  }

  @override
  void dispose() {
    _segmentController.dispose();
    super.dispose();
  }

  Future<void> _loadMultiRoleData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _phcService.getCaregiverDependents(),
        _phcService.getProviderPatients(),
        _phcService.getCommunityHeatmap(),
        _phcService.getSchemesEligibility(),
        _phcService.getPairedDevices(),
      ]);

      if (mounted) {
        setState(() {
          _dependents = results[0] as List<dynamic>? ?? [];
          _patients = results[1] as List<dynamic>? ?? [];
          _heatmap = results[2] as Map<String, dynamic>?;
          _schemesData = results[3] as Map<String, dynamic>?;
          _devices = results[4] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading role data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendCheckIn(String depId, String name) async {
    final res = await _phcService.sendCaregiverCheckin(depId);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📲 Check-in ping sent to $name. Notification dispatched.'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
      _loadMultiRoleData();
    }
  }

  Future<void> _triggerRemoteSos(String depId, String name) async {
    final res = await _phcService.triggerRemoteSos(depId);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 REMOTE SOS DISPATCHED for $name! Emergency responders notified.'),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
    }
  }

  Future<void> _syncDevice(String devId) async {
    final res = await _phcService.syncDevice(devId);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Wearable telemetry synchronized.'), backgroundColor: Color(0xFF059669)),
      );
      _loadMultiRoleData();
    }
  }

  Future<void> _showGenerateAbhaDialog() async {
    final aadhaarCtrl = TextEditingController(text: '8849 2018 3920');
    final mobileCtrl = TextEditingController(text: '+91 98765 43210');
    final nameCtrl = TextEditingController(text: 'Ramesh Chandra Patel');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.credit_card, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Generate ABHA 14-Digit ID', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Generate Ayushman Bharat Health Account under ABDM with instant verification.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            TextField(controller: aadhaarCtrl, decoration: const InputDecoration(labelText: 'Aadhaar Number', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: mobileCtrl, decoration: const InputDecoration(labelText: 'Linked Mobile Number', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _phcService.generateAbhaId(
                aadhaarNumber: aadhaarCtrl.text,
                mobile: mobileCtrl.text,
                fullName: nameCtrl.text,
              );
              if (res != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ABHA Created: ${res['abha_id']} (${res['abha_address']})'),
                    backgroundColor: const Color(0xFF15803D),
                  ),
                );
              }
            },
            child: const Text('Generate ABHA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    return Column(
      children: [
        // Role Segment Controller
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _segmentController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.escalator_warning, size: 18), text: 'Caregiver'),
              Tab(icon: Icon(Icons.medical_information, size: 18), text: 'ASHA / Doctor'),
              Tab(icon: Icon(Icons.account_balance, size: 18), text: 'Schemes & Privacy'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _segmentController,
            children: [
              _buildCaregiverView(),
              _buildProviderAshaView(),
              _buildSchemesAndPrivacyView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaregiverView() {
    return RefreshIndicator(
      onRefresh: _loadMultiRoleData,
      color: const Color(0xFF0284C7),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caregiver Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.family_restroom, color: Color(0xFF0284C7), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Caregiver Family Sentinel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0369A1))),
                        SizedBox(height: 2),
                        Text('Remotely monitor elderly parents and dependents with consent-backed live vitals and proxy SOS triggers.', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'MONITORED DEPENDENTS (LIVE VITALS & ALERTS)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dependents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, idx) {
                final dep = _dependents[idx];
                final v = dep['latest_vitals'] as Map<String, dynamic>? ?? {};
                final risk = dep['health_risk_score'] ?? 40;
                final isElevated = risk >= 50;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isElevated ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0), width: isElevated ? 1.5 : 1),
                    boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isElevated ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                child: Icon(Icons.elderly, color: isElevated ? const Color(0xFFDC2626) : const Color(0xFF15803D), size: 22),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dep['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                  Text('${dep['relationship']} • Age ${dep['age']} • ${dep['location']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isElevated ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Risk: $risk/100',
                              style: TextStyle(color: isElevated ? const Color(0xFFDC2626) : const Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Live Vitals Row
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniVital('Heart Rate', '${v['heart_rate'] ?? 78} bpm', const Color(0xFFE11D48)),
                            _buildMiniVital('SpO2', '${v['spo2'] ?? 97}%', const Color(0xFF0284C7)),
                            _buildMiniVital('Temp', '${v['body_temp'] ?? 37.1}°C', const Color(0xFFD97706)),
                            _buildMiniVital('BP', '${v['systolic_bp'] ?? 120}/${v['diastolic_bp'] ?? 80}', const Color(0xFF7C3AED)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text('Latest Check-in: ${dep['last_checkin_status']}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0284C7)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF0284C7)),
                              label: const Text('Send Ping', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                              onPressed: () => _sendCheckIn(dep['id'] ?? '', dep['name'] ?? ''),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.emergency, size: 14),
                              label: const Text('Remote SOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _triggerRemoteSos(dep['id'] ?? '', dep['name'] ?? ''),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniVital(String title, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        Text(title, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildProviderAshaView() {
    final heatmapCases = _heatmap?['heat_exhaustion_cases_today'] ?? 38;
    final popMonitored = _heatmap?['population_monitored'] ?? 14200;

    return RefreshIndicator(
      onRefresh: _loadMultiRoleData,
      color: const Color(0xFF0D9488),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ASHA / Clinical Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.health_and_safety, color: Color(0xFF0D9488), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ASHA Worker & Physician Clinical Copilot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F766E))),
                        const SizedBox(height: 2),
                        Text('Triage community patients, review AI flags, and monitor rural disease heatmaps in Varanasi district.', style: TextStyle(fontSize: 11, color: const Color(0xFF0D9488))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // District Surveillance Heatmap Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('IDSP EPIDEMIOLOGICAL SURVEILLANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Varanasi District', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDistrictStat('$heatmapCases', 'Heat Exhaustion Cases Today', const Color(0xFFE11D48)),
                      _buildDistrictStat('64', 'Respiratory Flare Incidents', const Color(0xFFD97706)),
                      _buildDistrictStat('$popMonitored', 'Citizens Tracked', const Color(0xFF0284C7)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Cluster Alert: Heat stress spike (+18%) active across Assi Ghat and Shivpur industrial zones.', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'ASSIGNED PATIENTS TRIAGE QUEUE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _patients.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final p = _patients[idx];
                final isHigh = (p['risk_tier'] ?? '') == 'High Risk';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isHigh ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p['risk_tier'] ?? '',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHigh ? const Color(0xFFDC2626) : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${p['gender']}, Age ${p['age']} • ${p['village_ward']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Text('Conditions: ${(p['conditions'] as List<dynamic>? ?? []).join(', ')}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Vitals: ${p['last_vitals']}', style: const TextStyle(fontSize: 11, color: Color(0xFF059669))),
                      const SizedBox(height: 4),
                      Text('Active Alert: ${p['active_alerts']}', style: const TextStyle(fontSize: 11, color: Color(0xFFE11D48), fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictStat(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildSchemesAndPrivacyView() {
    final schemes = _schemesData?['schemes'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadMultiRoleData,
      color: const Color(0xFF2563EB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Government Schemes Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GOVERNMENT HEALTHCARE SCHEMES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8)),
                TextButton.icon(
                  icon: const Icon(Icons.add_card, size: 14),
                  label: const Text('ABHA ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: _showGenerateAbhaDialog,
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Schemes Cards
            ...schemes.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(s['scheme_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                        child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Coverage: ${s['coverage_amount']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  Text('Beneficiary Card: ${s['card_number']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Text('Cashless Services: ${(s['cashless_services'] as List<dynamic>? ?? []).join(', ')}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                ],
              ),
            )),
            const SizedBox(height: 16),

            // Connected BLE Wearables Section
            const Text('CONNECTED WEARABLE SENSORS (BLE HUB)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8)),
            const SizedBox(height: 10),

            ..._devices.map((d) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEEF2FF),
                    child: const Icon(Icons.watch, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['device_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('${d['connection_status']} • Battery: ${d['battery_level']}%', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync, color: Color(0xFF4F46E5), size: 20),
                    onPressed: () => _syncDevice(d['id'] ?? ''),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),

            // DPDP Act 2023 Granular Consent Matrix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.security, color: Color(0xFF10B981), size: 20),
                      SizedBox(width: 8),
                      Text('DPDPA 2023 DATA SOVEREIGNTY GATES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Granular user controls. Toggle sharing permissions per channel without revoking app functions.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  _buildConsentSwitch('On-Device Biometric Telemetry', 'biometric_telemetry'),
                  _buildConsentSwitch('Family Caregiver Vitals Sync', 'caregiver_vitals_sync'),
                  _buildConsentSwitch('ASHA Health Worker Escalation', 'asha_worker_escalation'),
                  _buildConsentSwitch('Anonymized Epidemiological Surveillance', 'anonymized_public_health'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSwitch(String title, String key) {
    final val = _consents[key] ?? true;
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeThumbColor: const Color(0xFF10B981),
      title: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      value: val,
      onChanged: (newVal) async {
        setState(() => _consents[key] = newVal);
        await _phcService.toggleConsent(key, newVal);
      },
    );
  }
}
