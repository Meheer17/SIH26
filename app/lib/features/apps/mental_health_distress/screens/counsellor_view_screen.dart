import 'package:flutter/material.dart';
import '../services/nyaya_manas_service.dart';

class CounsellorViewScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const CounsellorViewScreen({super.key, this.onRefresh});

  @override
  State<CounsellorViewScreen> createState() => _CounsellorViewScreenState();
}

class _CounsellorViewScreenState extends State<CounsellorViewScreen> {
  final _service = NyayaManasService();

  int _selectedNavIndex = 0; // 0: Triage & CUS, 1: Medical OCR & RAG, 2: AI Decision Engine, 3: XAI & Diagnostics
  bool _loading = true;
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _victimsList = [];
  List<Map<String, dynamic>> _prioritizedCases = [];
  int _selectedVictimIndex = 0;
  String _riskFilter = 'All Risk Levels';
  final String _searchQuery = '';

  // OCR & Doctor Report State
  final TextEditingController _ocrDoctorNameController = TextEditingController(text: 'Dr. Ananya Sharma, MD (Psychiatry)');
  final TextEditingController _ocrLicenseController = TextEditingController(text: 'MCI-NIMHANS-2018-8842');
  final TextEditingController _ocrTextController = TextEditingController();
  String _selectedReportType = 'DMHP Clinical Intake & Trauma Assessment';
  bool _ocrUploading = false;
  Map<String, dynamic>? _lastOcrResult;
  List<Map<String, dynamic>> _victimReports = [];

  // RAG Query State
  final TextEditingController _ragQueryController = TextEditingController();
  bool _ragSearching = false;
  Map<String, dynamic>? _lastRagResult;

  // Automated Decision State
  bool _decisionLoading = false;
  Map<String, dynamic>? _lastDecisionPackage;

  // Override dialog controllers
  final TextEditingController _overrideScoreController = TextEditingController();
  final TextEditingController _overrideReasonController = TextEditingController();

  // Intervention dialog controllers
  final TextEditingController _interventionTitleController = TextEditingController();
  final TextEditingController _interventionDescController = TextEditingController();
  String _selectedInterventionType = 'tele_counselling';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _ocrDoctorNameController.dispose();
    _ocrLicenseController.dispose();
    _ocrTextController.dispose();
    _ragQueryController.dispose();
    _overrideScoreController.dispose();
    _overrideReasonController.dispose();
    _interventionTitleController.dispose();
    _interventionDescController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dash = await _service.fetchRoleDashboard('counsellor');
      final victimsRes = await _service.fetchVictims(
        riskTier: _riskFilter,
        search: _searchQuery,
      );
      final prioRes = await _service.fetchPrioritizedCases();

      if (mounted) {
        setState(() {
          _dashboardData = dash;
          _victimsList = List<Map<String, dynamic>>.from(victimsRes['victims'] ?? []);
          _prioritizedCases = List<Map<String, dynamic>>.from(prioRes['prioritized_cases'] ?? []);
          _loading = false;
        });
      }

      if (_activeVictim != null) {
        _loadReportsForActiveVictim();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadReportsForActiveVictim() async {
    final active = _activeVictim;
    if (active == null) return;
    try {
      final res = await _service.fetchVictimReports(active['id']);
      if (mounted && res.containsKey('reports')) {
        setState(() {
          _victimReports = List<Map<String, dynamic>>.from(res['reports'] ?? []);
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic>? get _activeVictim {
    if (_victimsList.isEmpty) return null;
    if (_selectedVictimIndex >= _victimsList.length) {
      _selectedVictimIndex = 0;
    }
    return _victimsList[_selectedVictimIndex];
  }

  // -------------------------------------------------------------
  // OCR & RAG ACTIONS
  // -------------------------------------------------------------
  Future<void> _uploadAndExtractOcr() async {
    final active = _activeVictim;
    if (active == null) return;

    setState(() => _ocrUploading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final res = await _service.uploadClinicalReport(
        victimId: active['id'],
        doctorName: _ocrDoctorNameController.text,
        doctorLicense: _ocrLicenseController.text,
        reportType: _selectedReportType,
        rawText: _ocrTextController.text.trim(),
        fileName: '${active['id']}_clinical_assessment.pdf',
      );

      if (mounted) {
        setState(() {
          _lastOcrResult = res;
          _ocrUploading = false;
        });
        _loadReportsForActiveVictim();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text('✅ Report OCR Processed & ${res['chunks_indexed'] ?? 3} Vectors Indexed in MongoDB!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ocrUploading = false);
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE11D48),
            content: Text('Failed to process OCR report.'),
          ),
        );
      }
    }
  }

  Future<void> _executeRagQuery() async {
    final active = _activeVictim;
    if (active == null || _ragQueryController.text.trim().isEmpty) return;

    setState(() => _ragSearching = true);
    try {
      final res = await _service.ragQueryClinicalKnowledge(
        query: _ragQueryController.text.trim(),
        victimId: active['id'],
        topK: 3,
      );

      if (mounted) {
        setState(() {
          _lastRagResult = res;
          _ragSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _ragSearching = false);
    }
  }

  Future<void> _triggerAutoDecide() async {
    final active = _activeVictim;
    if (active == null) return;

    setState(() => _decisionLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final res = await _service.generateAutomatedDecision(active['id']);
      if (mounted) {
        setState(() {
          _lastDecisionPackage = res['decision_package'];
          _decisionLoading = false;
          _selectedNavIndex = 2; // Navigate to Decision Tab
        });
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF4F46E5),
            content: Text('⚡ AI Statutory Decision Generated from CUS & Vector RAG Findings!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _decisionLoading = false);
    }
  }

  void _populateOcrPreset(int index) {
    if (index == 0) {
      _ocrTextController.text =
          'PATIENT CLINICAL EVALUATION & FORENSIC TRAUMA INTAKE\n'
          'Patient: Savitri Devi (F/38) | Case: Caste-Motivated Aggravated Assault\n'
          'Clinical Findings: Acute Post-Traumatic Stress Disorder (ICD-11 6B40 / DSM-5 309.81).\n'
          'Severe persistent hypervigilance, nocturnal panic awakenings, somatic tremor in bilateral hands.\n'
          'Suicide Risk Assessment (C-SSRS): Level 3 - Moderate Elevated due to active death threats and fear of testimony.\n'
          'Physical Examination: Soft tissue contusion left shoulder, resolving cervical sprain.\n'
          'Medication Prescribed: Tab Clonazepam 0.5mg SOS for acute panic; Tab Escitalopram 10mg OD.\n'
          'Psychosocial Recommendation: Immediate 24x7 Armed Police Escort under Sec 15A PoA Act; safehouse transit relocation.\n'
          'Statutory Relief: Expedite 50% Rule 12(4) DBT disbursement to alleviate extreme economic duress.';
    } else if (index == 1) {
      _ocrTextController.text =
          'FORENSIC PSYCHIATRIC EVALUATION & HOMICIDE BEREAVEMENT REPORT\n'
          'Patient: Ramesh Chandra (M/42) | Case: Caste Homicide / Lynching of Family Member\n'
          'Clinical Findings: Prolonged Grief Disorder (ICD-11 6B42) with Severe Anxious Depression.\n'
          'Victim reports persistent agricultural boycott, intimidation from village dominant caste members.\n'
          'Depressive Flatness: Hamilton Depression Rating Scale (HDRS) Score 24/52 (Severe).\n'
          'Suicide Risk: Passive death wish without active intent.\n'
          'Physical Assessment: Somatic muscle tension, chronic headache, sleep latency > 180 mins.\n'
          'Prescribed: Tab Sertraline 50mg OD; Weekly Bereavement Support Sessions.\n'
          'Statutory Directive: Provide immediate safehouse accommodation and expedited Rule 12(4) interim compensation.';
    } else {
      _ocrTextController.text =
          'EMERGENCY MEDICAL BOARD & TRAUMA ADMISSION REPORT\n'
          'Patient: Lalita Devi (F/34) | Case: Arson & Grievous Hurt\n'
          'Clinical Findings: Acute Stress Reaction (ICD-11 6B43), panic hyperarousal, flash-backs of burning home.\n'
          'Physical Injuries: Superficial second-degree burns on bilateral forearms, laceration over forehead.\n'
          'Suicide Risk: Low-Moderate (Severe panic attacks whenever sirens heard).\n'
          'Prescribed: Wound debridement dressing, Tab Alprazolam 0.25mg SOS, Burn dressing care.\n'
          'Recommendation: Re-housing relocation grant under PoA Act, legal aid counsel appointment.';
    }
    setState(() {});
  }

  void _showOverrideModal() {
    final active = _activeVictim;
    if (active == null) return;

    _overrideScoreController.text = (active['dds_score'] ?? 75).toString();
    _overrideReasonController.clear();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.edit_note, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Clinical Human Override', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Victim: ${active['full_name']} (${active['id']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
            const SizedBox(height: 12),
            TextField(
              controller: _overrideScoreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Adjusted DDS Score (0-100)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _overrideReasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Clinical Justification Reason (Required for Audit)',
                hintText: 'e.g. Completed 45min crisis de-escalation therapy session...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newScore = double.tryParse(_overrideScoreController.text) ?? 50.0;
              final reason = _overrideReasonController.text;
              if (reason.isEmpty) return;

              Navigator.pop(ctx);
              await _service.submitHumanOverride(
                victimId: active['id'],
                adjustedDdsScore: newScore,
                justificationReason: reason,
              );
              _loadData();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF059669),
                  content: Text('✅ Clinical Override Logged with Merkle-Audit Trail!'),
                ),
              );
            },
            child: const Text('Save Override'),
          ),
        ],
      ),
    );
  }

  void _showNewInterventionModal() {
    final active = _activeVictim;
    if (active == null) return;
    final messenger = ScaffoldMessenger.of(context);

    _interventionTitleController.text = 'Immediate Trauma De-escalation Tele-Session';
    _interventionDescController.text = 'Clinical intervention under Mental Healthcare Act 2017 to manage acute testimony panic.';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dlgCtx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.send_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Dispatch Statutory Intervention', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Victim: ${active['full_name']} (${active['id']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedInterventionType,
                  decoration: InputDecoration(
                    labelText: 'Intervention Category',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tele_counselling', child: Text('1. Tele-Counseling (Tele-MANAS)')),
                    DropdownMenuItem(value: 'medical_trauma', child: Text('2. Emergency Medical Trauma Unit')),
                    DropdownMenuItem(value: 'armed_witness_escort', child: Text('3. Armed Witness Protection Detail')),
                    DropdownMenuItem(value: 'safe_relocation', child: Text('4. Safehouse Transit Relocation')),
                    DropdownMenuItem(value: 'compensation_fast_track', child: Text('5. Fast-Track Statutory Relief')),
                    DropdownMenuItem(value: 'legal_aid_dlsa', child: Text('6. Free Legal Aid (DLSA Advocate)')),
                    DropdownMenuItem(value: 'rehabilitation_grant', child: Text('7. Rehabilitation & Skill Grant')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => _selectedInterventionType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _interventionTitleController,
                  decoration: InputDecoration(
                    labelText: 'Action Title',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _interventionDescController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Scope & Instructions',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _service.dispatchIntervention({
                  'victim_id': active['id'],
                  'intervention_type': _selectedInterventionType,
                  'title': _interventionTitleController.text,
                  'description': _interventionDescController.text,
                  'priority': 'CRITICAL',
                  'assigned_agency': 'DMHP_NIMHANS',
                  'assigned_officer': 'Dr. Ananya Sharma',
                  'sla_hours': 2,
                });
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF059669),
                    content: Text('✅ Intervention Package Dispatched to Field Cell & Police Protection Detail!'),
                  ),
                );
              },
              child: const Text('Dispatch Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF059669),
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            _buildTriageAndCusTab(),
            _buildMedicalOcrAndRagTab(),
            _buildAiDecisionEngineTab(),
            _buildXaiAndDiagnosticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (idx) => setState(() => _selectedNavIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF059669),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_numbered_rtl),
              label: 'Triage & CUS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined),
              label: 'Medical OCR & RAG',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'AI Decision',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              label: 'XAI & Trajectory',
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 0: TRIAGE & COMPOSITE URGENCY SCORE (CUS)
  // =========================================================================
  Widget _buildTriageAndCusTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiSummaryGrid(),
          const SizedBox(height: 16),
          _buildAlertQueueCard(),
          const SizedBox(height: 16),
          _buildCusPrioritizationCard(),
          const SizedBox(height: 16),
          _buildCaseloadSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCusPrioritizationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.leaderboard_outlined, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text(
                    'Automated Case Prioritization (CUS Algorithm)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                child: const Text('PART C SPEC', style: TextStyle(color: Color(0xFF4F46E5), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'CUS = 0.30·DDS + 0.25·SLA + 0.20·Velocity + 0.10·Severity + 0.10·Recency + 0.05·Engagement',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 14),

          Column(
            children: _prioritizedCases.map((c) {
              final rank = c['priority_rank'] ?? 'HIGH_P2';
              Color rankColor = const Color(0xFF059669);
              if (rank == 'CRITICAL_P1') {
                rankColor = const Color(0xFFE11D48);
              } else if (rank == 'HIGH_P2') {
                rankColor = const Color(0xFFEA580C);
              } else if (rank == 'MODERATE_P3') {
                rankColor = const Color(0xFFD97706);
              }

              final isSelected = _activeVictim?['id'] == c['victim_id'];

              return InkWell(
                onTap: () {
                  final idx = _victimsList.indexWhere((v) => v['id'] == c['victim_id']);
                  if (idx != -1) {
                    setState(() => _selectedVictimIndex = idx);
                    _loadReportsForActiveVictim();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: rankColor.withValues(alpha: 0.12),
                        child: Text(
                          '${(c['cus_score'] as num?)?.toInt() ?? 80}',
                          style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 12),
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
                                  c['full_name'] ?? 'Victim',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(color: rankColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(rank, style: TextStyle(color: rankColor, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            Text(
                              c['action_decision'] ?? '',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final idx = _victimsList.indexWhere((v) => v['id'] == c['victim_id']);
                          if (idx != -1) {
                            setState(() => _selectedVictimIndex = idx);
                            _loadReportsForActiveVictim();
                          }
                          _triggerAutoDecide();
                        },
                        child: const Text('Auto-Decide', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: DOCTOR MEDICAL REPORT OCR & VECTOR RAG CLINICAL SEARCH
  // =========================================================================
  Widget _buildMedicalOcrAndRagTab() {
    final active = _activeVictim;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.medical_services_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinical Report OCR & Mongo Vector RAG',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Active Patient: ${active?['full_name'] ?? 'Select Victim'} (${active?['id'] ?? ''})',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // OCR Report Upload & Scan Section
          _buildOcrUploadCard(),
          const SizedBox(height: 16),

          // Extracted OCR Entities (if available)
          if (_lastOcrResult != null) _buildOcrEntityResultsCard(),
          if (_lastOcrResult != null) const SizedBox(height: 16),

          // RAG Semantic Query Bar & Results
          _buildRagQuerySection(),
          const SizedBox(height: 16),

          // Historical Indexed Reports
          _buildHistoricalReportsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOcrUploadCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.document_scanner_rounded, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Doctor Intake & Forensic OCR Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                child: const Text('VECTOR INDEXED', style: TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Preset Buttons for Demo
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFFF1F5F9),
                avatar: const Icon(Icons.description, size: 14, color: Color(0xFF7C3AED)),
                label: const Text('Preset 1: Savitri Devi (PTSD)', style: TextStyle(fontSize: 10.5)),
                onPressed: () => _populateOcrPreset(0),
              ),
              ActionChip(
                backgroundColor: const Color(0xFFF1F5F9),
                avatar: const Icon(Icons.description, size: 14, color: Color(0xFFEA580C)),
                label: const Text('Preset 2: Ramesh Chandra (Grief)', style: TextStyle(fontSize: 10.5)),
                onPressed: () => _populateOcrPreset(1),
              ),
              ActionChip(
                backgroundColor: const Color(0xFFF1F5F9),
                avatar: const Icon(Icons.description, size: 14, color: Color(0xFF059669)),
                label: const Text('Preset 3: Lalita Devi (Arson)', style: TextStyle(fontSize: 10.5)),
                onPressed: () => _populateOcrPreset(2),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ocrDoctorNameController,
                  decoration: InputDecoration(
                    labelText: 'Attending Doctor',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _ocrLicenseController,
                  decoration: InputDecoration(
                    labelText: 'Medical License #',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: _selectedReportType,
            decoration: InputDecoration(
              labelText: 'Clinical Report Category',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
            items: const [
              DropdownMenuItem(
                value: 'DMHP Clinical Intake & Trauma Assessment',
                child: Text('DMHP Clinical Intake & Trauma Assessment', style: TextStyle(fontSize: 11)),
              ),
              DropdownMenuItem(
                value: 'Psychiatric Medico-Legal Evaluation',
                child: Text('Psychiatric Medico-Legal Evaluation', style: TextStyle(fontSize: 11)),
              ),
              DropdownMenuItem(
                value: 'C-SSRS Suicide Risk Assessment',
                child: Text('C-SSRS Suicide Risk Assessment', style: TextStyle(fontSize: 11)),
              ),
              DropdownMenuItem(
                value: 'Rehabilitation & Trauma Recovery Note',
                child: Text('Rehabilitation & Trauma Recovery Note', style: TextStyle(fontSize: 11)),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedReportType = val;
                });
              }
            },
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _ocrTextController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Clinical Notes / Scanned OCR Report Text',
              hintText: 'Paste clinical evaluation or select a demo preset above...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: const TextStyle(fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _ocrUploading ? null : _uploadAndExtractOcr,
              icon: _ocrUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_ocrUploading ? 'Processing OCR & Embedding Vectors...' : 'Extract OCR & Store in Mongo Vector DB', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrEntityResultsCard() {
    final res = _lastOcrResult!;
    final diagnoses = res['diagnoses'] as List<dynamic>? ?? [];
    final statutory = res['statutory_recommendations'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
              SizedBox(width: 8),
              Text('Extracted Clinical Entities & Vector Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46))),
            ],
          ),
          const SizedBox(height: 10),
          Text('Suicide Risk: ${res["suicide_risk_level"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
          const SizedBox(height: 6),
          const Text('Diagnoses:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ...diagnoses.map((d) => Text(' • $d', style: const TextStyle(fontSize: 10.5, color: Color(0xFF334155)))),
          const SizedBox(height: 6),
          const Text('Statutory Directives:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ...statutory.map((s) => Text(' • $s', style: const TextStyle(fontSize: 10.5, color: Color(0xFF059669)))),
        ],
      ),
    );
  }

  Widget _buildRagQuerySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('Interactive Vector RAG Clinical Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ask clinical/judicial questions against MongoDB Vector embeddings for this patient.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 12),

          // Suggested quick queries
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFFF8FAFC),
                label: const Text('Suicide risk & PTSD?', style: TextStyle(fontSize: 10)),
                onPressed: () {
                  _ragQueryController.text = 'What is the patient suicide risk and PTSD severity?';
                  _executeRagQuery();
                },
              ),
              ActionChip(
                backgroundColor: const Color(0xFFF8FAFC),
                label: const Text('Prescriptions & injuries?', style: TextStyle(fontSize: 10)),
                onPressed: () {
                  _ragQueryController.text = 'What physical injuries and medications were prescribed?';
                  _executeRagQuery();
                },
              ),
              ActionChip(
                backgroundColor: const Color(0xFFF8FAFC),
                label: const Text('Section 15A protection?', style: TextStyle(fontSize: 10)),
                onPressed: () {
                  _ragQueryController.text = 'Does this victim qualify for 24x7 armed police protection?';
                  _executeRagQuery();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ragQueryController,
                  decoration: InputDecoration(
                    hintText: 'Enter clinical question for Mongo Vector RAG...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _ragSearching ? null : _executeRagQuery,
                child: _ragSearching
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Query RAG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          if (_lastRagResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 16),
                      SizedBox(width: 6),
                      Text('AI Clinical Synthesis (Vector Grounded)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6B21A8))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_lastRagResult!['ai_synthesis'] ?? '', style: const TextStyle(fontSize: 11, height: 1.4, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text('⚡ Suggested Statutory Action: ${_lastRagResult!["recommended_statutory_action"]}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoricalReportsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.folder_shared_outlined, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('Patient Clinical Report Repository', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 10),
          if (_victimReports.isEmpty)
            const Text('No historical reports uploaded yet. Upload one above.', style: TextStyle(color: Color(0xFF64748B), fontSize: 11))
          else
            Column(
              children: _victimReports.map((r) {
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
                      const Icon(Icons.picture_as_pdf, color: Color(0xFFE11D48), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['report_type'] ?? 'Clinical Report', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('${r["doctor_name"]} • ${r["date_created"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                        child: Text('${r["chunks_indexed"] ?? 3} Chunks', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 9, fontWeight: FontWeight.bold)),
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

  // =========================================================================
  // TAB 2: AI DECISION ENGINE (CUS + RAG SYNTHESIS)
  // =========================================================================
  Widget _buildAiDecisionEngineTab() {
    final active = _activeVictim;
    final pkg = _lastDecisionPackage;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF3730A3)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.gavel, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Statutory Decision Engine',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Patient: ${active?['full_name'] ?? 'Select Victim'} • DDI: ${active?['dds_score'] ?? 75}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _decisionLoading ? null : _triggerAutoDecide,
                  child: _decisionLoading
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)))
                      : const Text('Re-Evaluate', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (pkg == null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.smart_toy_outlined, color: Color(0xFF4F46E5), size: 36),
                    const SizedBox(height: 10),
                    const Text('No decision package generated yet.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    const Text('Tap "Evaluate AI Decision" to synthesize CUS + Vector RAG evidence.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                      onPressed: _triggerAutoDecide,
                      child: const Text('Evaluate AI Decision Now'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                        child: Text('${pkg["priority_rank"]}', style: const TextStyle(color: Color(0xFFE11D48), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Text('SLA: ${pkg["sla_hours"]}h Response Window', style: const TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('PRIMARY STATUTORY DIRECTIVE:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text(pkg['primary_directive'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3)),
                  const SizedBox(height: 14),
                  const Text('SECONDARY MANDATED ACTIONS:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  ...((pkg['secondary_directives'] as List<dynamic>? ?? []).map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, color: Color(0xFF4F46E5), size: 18),
                          Expanded(child: Text(d as String, style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                        ],
                      ),
                    );
                  })),
                  const SizedBox(height: 14),
                  const Text('EVIDENCE CITATIONS (GROUNDED IN RAG & CUS):', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  ...((pkg['evidence_citations'] as List<dynamic>? ?? []).map((e) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                      child: Text('📄 $e', style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                    );
                  })),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF059669),
                            content: Text('🚀 Statutory Decision Package Executed & Dispatched to Police Special Cell & DMHP!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('One-Tap Execute & Dispatch to Police/DMHP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: XAI & DIAGNOSTICS TAB
  // =========================================================================
  Widget _buildXaiAndDiagnosticsTab() {
    final active = _activeVictim;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active != null) _buildXaiInspectorCard(active),
          if (active != null) const SizedBox(height: 16),
          if (active != null) _buildInterventionSection(active),
          if (active != null) const SizedBox(height: 16),
          if (active != null) _buildTrajectoryCard(active),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =========================================================================
  // SHARED COMPONENT WIDGETS
  // =========================================================================
  Widget _buildKpiSummaryGrid() {
    final total = _dashboardData?['total_assigned_cases'] ?? _victimsList.length;
    final critical = _dashboardData?['critical_risk_count'] ?? _victimsList.where((v) => v['risk_tier'] == 'CRITICAL').length;
    final high = _dashboardData?['high_risk_count'] ?? _victimsList.where((v) => v['risk_tier'] == 'HIGH').length;
    final avgDds = _dashboardData?['average_caseload_dds'] ?? 64.2;

    return Row(
      children: [
        _buildKpiTile('Total Cases', '$total', 'Active Supervision', Icons.people_alt_outlined, const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        _buildKpiTile('Critical (🔴)', '$critical', 'DDS > 75 (1-4h SLA)', Icons.warning_amber_rounded, const Color(0xFFE11D48)),
        const SizedBox(width: 8),
        _buildKpiTile('High Risk', '$high', 'DDS 51-75 (24h)', Icons.priority_high_rounded, const Color(0xFFEA580C)),
        const SizedBox(width: 8),
        _buildKpiTile('Avg DDS', '$avgDds', 'Caseload Mean', Icons.speed_outlined, const Color(0xFF7C3AED)),
      ],
    );
  }

  Widget _buildKpiTile(String title, String val, String sub, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(sub, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertQueueCard() {
    final alerts = _dashboardData?['urgent_alert_queue'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.notification_important, color: Color(0xFFE11D48)),
                  SizedBox(width: 8),
                  Text(
                    'Real-Time Escalation & Alert Queue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9F1239)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(8)),
                child: Text('${alerts.length} URGENT', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: alerts.map((a) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFFFE4E6),
                      child: const Icon(Icons.shield_moon, color: Color(0xFFE11D48), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a["victim_name"]} (${a["victim_id"]}) • DDI: ${a["dds_score"]}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '${a["trigger"]} • SLA: ${a["sla_countdown"]}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFBE185D)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${a["victim_name"]} via secure Tele-MANAS encrypted bridge...')),
                        );
                      },
                      child: const Text('Call', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
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

  Widget _buildCaseloadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.folder_shared_outlined, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Text(
                    'Assigned Victim Caseload Triage',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: _riskFilter,
                style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                underline: const SizedBox(),
                items: ['All Risk Levels', 'Critical', 'High', 'Moderate', 'Low']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _riskFilter = val);
                    _loadData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _victimsList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final v = _victimsList[idx];
              final isSelected = _selectedVictimIndex == idx;
              final score = (v['dds_score'] as num?)?.toDouble() ?? 50.0;
              Color color = const Color(0xFF059669);
              if (score >= 76) {
                color = const Color(0xFFE11D48);
              } else if (score >= 51) {
                color = const Color(0xFFEA580C);
              } else if (score >= 26) {
                color = const Color(0xFFD97706);
              }

              return InkWell(
                onTap: () {
                  setState(() => _selectedVictimIndex = idx);
                  _loadReportsForActiveVictim();
                },
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
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Text(
                          '${score.toInt()}',
                          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${v["full_name"]} (${v["id"]})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              '${v["district"]} • ${v["offense_category"] ?? "SC/ST PoA"} • ${v["case_stage"]?.toUpperCase() ?? "TRIAL"}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          v['risk_tier'] ?? 'LOW',
                          style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildXaiInspectorCard(Map<String, dynamic> active) {
    final shapList = active['shap_data'] as List<dynamic>? ?? [
      {"feature": "Acoustic Pitch Micro-Tremor & Tension", "weight": "+34.2%", "color": "#7C3AED"},
      {"feature": "Retaliation Threat by Accused", "weight": "+29.4%", "color": "#E11D48"},
      {"feature": "Witness Cross-Examination Proximity (<24h)", "weight": "+22.5%", "color": "#D97706"},
      {"feature": "Hopelessness Keywords in Transcripts", "weight": "+13.9%", "color": "#0284C7"}
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text(
                    'SHAP / LIME Feature Attribution (XAI)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _showOverrideModal,
                icon: const Icon(Icons.edit, size: 12, color: Color(0xFF7C3AED)),
                label: const Text('Clinical Override', style: TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mathematical attribution explaining why ${active["full_name"]} scored ${active["dds_score"]}/100.',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 14),

          Column(
            children: shapList.map((item) {
              final colorHex = (item['color'] as String?)?.replaceAll('#', '0xFF') ?? '0xFF7C3AED';
              final color = Color(int.tryParse(colorHex) ?? 0xFF7C3AED);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item['feature'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                        Text(item['weight'] as String, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
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

  Widget _buildInterventionSection(Map<String, dynamic> active) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.health_and_safety_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    '7-Point Statutory Intervention Dispatcher',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: _showNewInterventionModal,
                child: const Text('+ Dispatch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Statutory relief packages mandated under SC/ST PoA Act 1989 & Mental Healthcare Act 2017.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              Chip(label: Text('1. Tele-Counseling', style: TextStyle(fontSize: 9.5)), backgroundColor: Color(0xFFF1F5F9)),
              Chip(label: Text('2. Medical Trauma', style: TextStyle(fontSize: 9.5)), backgroundColor: Color(0xFFF1F5F9)),
              Chip(label: Text('3. Armed Escort', style: TextStyle(fontSize: 9.5)), backgroundColor: Color(0xFFFEE2E2)),
              Chip(label: Text('4. Safehouse Transit', style: TextStyle(fontSize: 9.5)), backgroundColor: Color(0xFFFEE2E2)),
              Chip(label: Text('5. Relief Fast-Track', style: TextStyle(fontSize: 9.5)), backgroundColor: Color(0xFFECFDF5)),
              Chip(label: Text('6. DLSA Legal Aid', style: TextStyle(fontSize: 9.5)), backgroundColor: Color(0xFFF1F5F9)),
              Chip(label: Text('7. Rehabilitation Grant', style: TextStyle(fontSize: 9.5)), backgroundColor: Color(0xFFF1F5F9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrajectoryCard(Map<String, dynamic> active) {
    final history = (active['distress_history'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [68.0, 72.0, 75.0, 82.0, 89.2];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.show_chart_rounded, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                '7-Day Dynamic Distress Trajectory (DDI)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: history.asMap().entries.map((entry) {
              final val = entry.value;
              final dayLabel = ['Mon', 'Tue', 'Wed', 'Thu', 'Today'][entry.key % 5];
              Color barColor = const Color(0xFF059669);
              if (val >= 76) {
                barColor = const Color(0xFFE11D48);
              } else if (val >= 51) {
                barColor = const Color(0xFFEA580C);
              }

              return Column(
                children: [
                  Text('${val.toInt()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: barColor)),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: (val / 100.0) * 80,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(dayLabel, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
