import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class AdminGovernanceTab extends StatefulWidget {
  const AdminGovernanceTab({super.key});

  @override
  State<AdminGovernanceTab> createState() => _AdminGovernanceTabState();
}

class _AdminGovernanceTabState extends State<AdminGovernanceTab> {
  final RakshaSetuService _service = RakshaSetuService();

  bool _isLoading = true;

  // Profile Fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _beltController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  String _selectedForce = 'CRPF';
  String _selectedRank = 'Havaldar';
  double _weeklyDutyHours = 64.0;
  double _deploymentDays = 90.0;
  double _leaveGapRatio = 0.75;
  int _postingRiskClass = 4;

  // Granular DPDP Act Consent Toggles
  bool _termsAccepted = true;
  bool _hrDataConsent = true;
  bool _voluntaryAssessmentConsent = true;
  bool _wearableConsent = true;
  bool _journalNlpConsent = true;
  bool _anonymizedResearchConsent = false;

  // Security toggles
  bool _dualKeyAuth = true;
  bool _differentialPrivacy = true;
  double _epsilon = 0.5;

  List<dynamic> _auditLogs = [];

  final List<String> _forces = [
    'CRPF',
    'BSF',
    'CISF',
    'ITBP',
    'SSB',
    'Indian Army',
    'Indian Navy',
    'Indian Air Force',
    'State Police'
  ];

  final List<String> _ranks = [
    'Constable',
    'Head Constable',
    'Lance Naik',
    'Naik',
    'Havaldar',
    'Naik Subedar',
    'Subedar',
    'Subedar Major',
    'Sub-Inspector',
    'Inspector',
    'Assistant Commandant',
    'Deputy Commandant',
    'Commandant'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _beltController.dispose();
    _unitController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _service.fetchProfile();
      final consent = await _service.fetchConsent();
      final logs = await _service.fetchAuditLogs();

      if (mounted) {
        setState(() {
          _nameController.text = profile['full_name'] ?? 'Havaldar Rajesh Singh';
          _beltController.text = profile['service_belt_number'] ?? 'CRPF-88412';
          _unitController.text = profile['unit_name'] ?? '44th Battalion CAPF (Border Sentinel)';
          _selectedForce = profile['force_branch'] ?? 'CRPF';
          if (!_forces.contains(_selectedForce)) _selectedForce = 'CRPF';
          _selectedRank = profile['rank'] ?? 'Havaldar';
          if (!_ranks.contains(_selectedRank)) _selectedRank = 'Havaldar';
          _weeklyDutyHours = (profile['weekly_duty_hours'] as num?)?.toDouble() ?? 64.0;
          _deploymentDays = (profile['deployment_days'] as num?)?.toDouble() ?? 90.0;
          _leaveGapRatio = (profile['leave_gap_ratio'] as num?)?.toDouble() ?? 0.75;
          _postingRiskClass = profile['posting_area_risk_class'] ?? 4;
          _emergencyNameController.text = profile['emergency_contact_name'] ?? 'Sunita Singh (Wife)';
          _emergencyPhoneController.text = profile['emergency_contact_phone'] ?? '+91 98765 43210';

          _termsAccepted = consent['terms_accepted'] ?? true;
          _hrDataConsent = consent['hr_data_analysis'] ?? true;
          _voluntaryAssessmentConsent = consent['voluntary_self_assessment'] ?? true;
          _wearableConsent = consent['wearable_biometrics'] ?? true;
          _journalNlpConsent = consent['journal_nlp_analysis'] ?? true;
          _anonymizedResearchConsent = consent['anonymized_research'] ?? false;

          _auditLogs = logs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileAndConsent() async {
    try {
      await _service.updatePreferences({
        'full_name': _nameController.text,
        'force_branch': _selectedForce,
        'rank': _selectedRank,
        'unit_name': _unitController.text,
        'service_belt_number': _beltController.text,
        'weekly_duty_hours': _weeklyDutyHours,
        'deployment_days': _deploymentDays.toInt(),
        'leave_gap_ratio': _leaveGapRatio,
        'posting_area_risk_class': _postingRiskClass,
        'emergency_contact_name': _emergencyNameController.text,
        'emergency_contact_phone': _emergencyPhoneController.text,
      });

      await _service.submitConsent({
        'terms_accepted': _termsAccepted,
        'hr_data_analysis': _hrDataConsent,
        'voluntary_self_assessment': _voluntaryAssessmentConsent,
        'wearable_biometrics': _wearableConsent,
        'journal_nlp_analysis': _journalNlpConsent,
        'anonymized_research': _anonymizedResearchConsent,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile & DPDP Act 2023 consent preferences saved to encrypted backend!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0x2A312E81), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_rounded, color: Color(0xFF818CF8), size: 26),
                      SizedBox(width: 8),
                      Text('Profile & Governance Hub', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0x3310B981), borderRadius: BorderRadius.circular(6)),
                    child: const Text('DPDP ACT 2023', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Digital Personal Data Protection Act 2023 & Armed Forces Welfare Compliance Architecture',
                style: TextStyle(fontSize: 12, color: Color(0xFFC7D2FE)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Personnel Service Profile Form
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personnel Service Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedForce,
                      decoration: const InputDecoration(labelText: 'Force / Branch', border: OutlineInputBorder()),
                      items: _forces.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedForce = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRank,
                      decoration: const InputDecoration(labelText: 'Rank', border: OutlineInputBorder()),
                      items: _ranks.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRank = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _beltController,
                      decoration: const InputDecoration(labelText: 'Service / Belt Number', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _postingRiskClass,
                      decoration: const InputDecoration(labelText: 'Posting Risk Class', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Class 1: Peace Station')),
                        DropdownMenuItem(value: 2, child: Text('Class 2: Moderate Reserve')),
                        DropdownMenuItem(value: 3, child: Text('Class 3: Field Outpost')),
                        DropdownMenuItem(value: 4, child: Text('Class 4: High Altitude LOC')),
                        DropdownMenuItem(value: 5, child: Text('Class 5: Extreme Risk LWE')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _postingRiskClass = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Assigned Unit / Battalion', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              // Duty Sliders
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Weekly Duty Workload:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${_weeklyDutyHours.toInt()} Hours / Week', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                ],
              ),
              Slider(
                value: _weeklyDutyHours,
                min: 40.0,
                max: 84.0,
                divisions: 22,
                activeColor: const Color(0xFF0284C7),
                onChanged: (v) => setState(() => _weeklyDutyHours = v),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Field Deployment Length:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('${_deploymentDays.toInt()} Days Continuous', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                ],
              ),
              Slider(
                value: _deploymentDays,
                min: 10.0,
                max: 180.0,
                divisions: 34,
                activeColor: const Color(0xFFF97316),
                onChanged: (v) => setState(() => _deploymentDays = v),
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emergencyNameController,
                      decoration: const InputDecoration(labelText: 'Emergency Contact Name', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _emergencyPhoneController,
                      decoration: const InputDecoration(labelText: 'Emergency Contact Phone', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 3. DPDP Act 2023 Granular Consent Management
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DPDP Act 2023 Granular Privacy Consent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              const Text('Control exactly what telemetry is analyzed. All data is non-punitive and protected.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Terms of Welfare Service', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Mandatory terms governing platform welfare protection', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _termsAccepted,
                activeColor: const Color(0xFF16A34A),
                onChanged: (val) => setState(() => _termsAccepted = val),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('HRMS Operational Duty Data Analysis', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Allows AI to correlate duty hours, leave gap, and field tenure to prevent burnout', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _hrDataConsent,
                activeColor: const Color(0xFF16A34A),
                onChanged: (val) => setState(() => _hrDataConsent = val),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Voluntary Clinical Screening Questionnaires', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Permits encrypted scoring for PHQ-9, GAD-7, and CAPF stress index', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _voluntaryAssessmentConsent,
                activeColor: const Color(0xFF16A34A),
                onChanged: (val) => setState(() => _voluntaryAssessmentConsent = val),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Smartwatch & Band Biometric Telemetry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Resting HR, HRV, and sleep architecture telemetry sync', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _wearableConsent,
                activeColor: const Color(0xFF16A34A),
                onChanged: (val) => setState(() => _wearableConsent = val),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('AI Sentiment Analysis of Voice/Text Journals', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Analyzes emotional strain without transmitting raw audio files', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _journalNlpConsent,
                activeColor: const Color(0xFF16A34A),
                onChanged: (val) => setState(() => _journalNlpConsent = val),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Anonymized Force-Wide Wellness Research', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Contributes differential privacy de-identified metrics to DRDO/NIMHANS studies', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _anonymizedResearchConsent,
                activeColor: const Color(0xFF16A34A),
                onChanged: (val) => setState(() => _anonymizedResearchConsent = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 4. Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveProfileAndConsent,
            icon: const Icon(Icons.verified_user),
            label: const Text('Save Profile & Cryptographic Consent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 5. Anti-Stigmatization & Security Guarantees
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.lock, color: Color(0xFF0F172A), size: 20),
                  SizedBox(width: 8),
                  Text('Cryptographic Security & Anti-Stigmatization', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dual-Key Medical Officer Authorization', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: const Text('Requires 2FA from unit psychologist to decrypt individual dossiers', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _dualKeyAuth,
                activeColor: const Color(0xFF0284C7),
                onChanged: (val) => setState(() => _dualKeyAuth = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Differential Privacy Engine (ε = 0.5)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: const Text('Injects Laplace noise into commander heatmaps to mathematically prevent identification of individual jawans', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                value: _differentialPrivacy,
                activeColor: const Color(0xFF0284C7),
                onChanged: (val) => setState(() => _differentialPrivacy = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6. Security Audit Trail
        const Text('Immutable Security Audit Trail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        ..._auditLogs.map((log) {
          final action = log['action'] ?? 'QUERY';
          final by = log['accessed_by'] ?? 'OFFICER';
          final ts = (log['timestamp'] as String?)?.split('T').last.split('.').first ?? '12:00:00';

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fingerprint, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Text('$action by $by', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  ],
                ),
                Text(ts, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}
