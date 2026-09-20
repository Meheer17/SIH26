import 'package:flutter/material.dart';
import '../services/medikiosk_service.dart';

class PhysicianEmrTab extends StatefulWidget {
  const PhysicianEmrTab({super.key});

  @override
  State<PhysicianEmrTab> createState() => _PhysicianEmrTabState();
}

class _PhysicianEmrTabState extends State<PhysicianEmrTab> {
  final MediKioskService _service = MediKioskService();

  bool _isLoading = true;
  bool _isAyushLensActive = false;
  bool _isSigningOff = false;

  Map<String, dynamic>? _doctorDashboard;
  List<dynamic> _patientQueue = [];
  Map<String, dynamic>? _activeSummary;
  List<dynamic> _timelineEvents = [];
  Map<String, dynamic>? _labTrends;
  Map<String, dynamic>? _drugInteractions;
  List<dynamic> _scannedDocs = [];

  String _selectedToken = 'OPD-CARD-8842';

  // Physical Exam Controllers
  final _generalExamCtrl = TextEditingController(text: 'Conscious, oriented, afebrile, pulse 78/min regular, BP 130/84 mmHg');
  final _cvsExamCtrl = TextEditingController(text: 'S1 S2 heard, no murmurs, normal apical impulse');
  final _rsExamCtrl = TextEditingController(text: 'Bilateral vesicular breath sounds, mild expiratory wheeze at bases');
  final _abdomenExamCtrl = TextEditingController(text: 'Soft, non-tender, no organomegaly');

  @override
  void initState() {
    super.initState();
    _loadAllDoctorData();
  }

  Future<void> _loadAllDoctorData() async {
    setState(() => _isLoading = true);
    final dash = await _service.getDoctorDashboard();
    final queue = await _service.getDoctorQueue();
    final summary = await _service.getSummary('sum-rajesh-001');
    final timelineRes = await _service.getTimeline('pat-rajesh-001');
    final labs = await _service.getLabTrends('pat-rajesh-001', testName: 'HbA1c');
    final ddi = await _service.getDrugInteractions('pat-rajesh-001');
    final docs = await _service.getPatientDocuments('pat-rajesh-001');

    if (mounted) {
      setState(() {
        _doctorDashboard = dash;
        _patientQueue = queue;
        _activeSummary = summary;
        _timelineEvents = (timelineRes?['timeline'] as List?) ?? [];
        _labTrends = labs;
        _drugInteractions = ddi;
        _scannedDocs = docs;
        _isLoading = false;
      });
    }
  }

  Future<void> _callPatient(String token) async {
    final res = await _service.callPatient(token);
    if (mounted && res != null) {
      setState(() => _selectedToken = token);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 ${res["message"] ?? "Patient called into room 104"}'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
      _loadAllDoctorData();
    }
  }

  Future<void> _commitSignoff() async {
    if (_activeSummary == null) return;
    setState(() => _isSigningOff = true);
    final summaryId = _activeSummary!['id'] ?? 'sum-rajesh-001';
    final res = await _service.acceptSummary(summaryId, doctorName: 'Dr. Ananya Sharma');

    if (mounted) {
      setState(() {
        _isSigningOff = false;
        _activeSummary!['status'] = 'FINAL_COMMITTED';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${res?["message"] ?? "Summary committed to ABDM & Hospital HIS!"}'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _showEditSectionDialog(String sectionKey, String sectionTitle, String currentText) {
    final textCtrl = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Text('Edit $sectionTitle', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: TextField(
            controller: textCtrl,
            maxLines: 5,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Modify clinical text...'),
          ),
          actions: [
            TextButton(child: const Text('CANCEL'), onPressed: () => Navigator.pop(ctx)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              child: const Text('SAVE TO EMR'),
              onPressed: () async {
                final summaryId = _activeSummary?['id'] ?? 'sum-rajesh-001';
                final res = await _service.editSummarySection(summaryId, sectionKey, textCtrl.text.trim());
                if (mounted && res != null) {
                  setState(() {
                    _activeSummary![sectionKey] = textCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Section $sectionTitle updated!'), backgroundColor: const Color(0xFF4F46E5)),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDualPrescriptionDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.medication_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Create Dual Parallel Prescription (D8)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Allopathic Rx (ICD-11 BA80 / SNOMED CT):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                const Text('• Tab Sorbitrate 5mg (SL PRN for chest tightness)\n• Tab Amlodipine 5mg (1-0-0 x 30 days)\n• Tab Atorvastatin 20mg (0-0-1 x 30 days)', style: TextStyle(fontSize: 11, color: Color(0xFF334155))),
                const Divider(height: 20),
                const Text('AYUSH Parallel Rx (NAMASTE KVT-04):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                const SizedBox(height: 4),
                const Text('• Arjunarishta (20ml BD with lukewarm water)\n• Prabhakar Vati (1 tab BD cardio-protective)\n• Hridayarnava Rasa (125mg BD under supervision)', style: TextStyle(fontSize: 11, color: Color(0xFF5B21B6))),
                const Divider(height: 20),
                const Text('Investigations Ordered:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                const SizedBox(height: 4),
                const Text('• 12-Lead Resting ECG\n• Serum Troponin-I & Creatinine\n• Fasting Lipid Panel & HbA1c', style: TextStyle(fontSize: 11, color: Color(0xFF0369A1))),
              ],
            ),
          ),
          actions: [
            TextButton(child: const Text('CANCEL'), onPressed: () => Navigator.pop(ctx)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('DISPATCH DUAL RX TO PHARMACY'),
              onPressed: () async {
                await _service.saveDualPrescription({
                  'encounter_id': 'enc-001',
                  'patient_id': 'pat-rajesh-001',
                  'diagnoses': ['Angina Pectoris (BA80)', 'Essential Hypertension'],
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Dual-Path Prescription saved & routed to Hospital Pharmacy!'), backgroundColor: Color(0xFF059669)),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    return RefreshIndicator(
      onRefresh: _loadAllDoctorData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhysicianHeader(),
            const SizedBox(height: 20),
            _buildQueueSelectorBar(),
            const SizedBox(height: 20),
            _buildPreConsultBriefCard(),
            const SizedBox(height: 20),
            _buildDiagnosticSupportCard(),
            const SizedBox(height: 20),
            _buildDocumentTimelineCard(),
            const SizedBox(height: 20),
            _buildScannedDocumentsOcrCard(),
            const SizedBox(height: 20),
            _buildPhysicalExamEntryCard(),
            const SizedBox(height: 20),
            _buildPhysicianCommitCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicianHeader() {
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
                  Icon(Icons.badge_outlined, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 10),
                  Text('Physician EMR Consultation Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Row(
                children: [
                  const Text('Allopathic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                  Switch(
                    value: _isAyushLensActive,
                    activeThumbColor: const Color(0xFF7C3AED),
                    activeTrackColor: const Color(0xFFDDD6FE),
                    inactiveThumbColor: const Color(0xFF0284C7),
                    inactiveTrackColor: const Color(0xFFBAE6FD),
                    onChanged: (v) => setState(() => _isAyushLensActive = v),
                  ),
                  const Text('AYUSH Lens', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Attending: ${_doctorDashboard?["doctor_name"] ?? "Dr. Ananya Sharma"} • ${_doctorDashboard?["department"] ?? "Cardiology OPD"} (${_doctorDashboard?["room_no"] ?? "Room 104"})',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSelectorBar() {
    return Container(
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
              const Text('Upcoming Patients Waiting in Queue (D2):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('${_patientQueue.length} In Queue', style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _patientQueue.map((q) {
                final isSelected = q['token'] == _selectedToken;
                final isRed = q['red_flag'] == true;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(isRed ? Icons.warning_rounded : Icons.person, size: 16, color: isRed ? Colors.white : (isSelected ? Colors.white : const Color(0xFF4F46E5))),
                    label: Text('${q["token"]}: ${q["patient_name"]}'),
                    backgroundColor: isRed ? const Color(0xFFE11D48) : (isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9)),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: (isSelected || isRed) ? Colors.white : const Color(0xFF0F172A),
                    ),
                    onPressed: () => _callPatient(q['token']),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreConsultBriefCard() {
    if (_activeSummary == null) return const SizedBox.shrink();

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
                  Icon(Icons.assignment_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Structured Clinical Intake Summary (D3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: Text('AI CONFIDENCE: ${_activeSummary!["ai_confidence_score"] ?? 94}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildSectionTile('Chief Complaint', _activeSummary!['chief_complaint'] ?? '', 'chief_complaint'),
          _buildSectionTile('History of Present Illness (HPI)', _activeSummary!['hpi'] ?? '', 'hpi'),
          _buildSectionTile('Past Medical History', _activeSummary!['past_medical_history'] ?? '', 'past_medical_history'),
          _buildSectionTile('Drug & Allergy History', _activeSummary!['drug_allergy'] ?? '', 'drug_allergy'),
          _buildSectionTile('Family & Social History', '${_activeSummary!["family_history"]}\n${_activeSummary!["personal_history"]}', 'family_history'),
          _buildSectionTile('Review of Systems (ROS)', _activeSummary!['ros'] ?? '', 'ros'),

          if (_activeSummary!['red_flags'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECDD3))),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Color(0xFFE11D48), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('⚠️ RED FLAG: ${_activeSummary!["red_flags"]}', style: const TextStyle(fontSize: 10, color: Color(0xFFBE123C), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTile(String title, String content, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                InkWell(
                  onTap: () => _showEditSectionDialog(key, title, content),
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 12, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text('EDIT SECTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(content, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticSupportCard() {
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
              Icon(Icons.biotech_outlined, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text('Diagnostic Decision Support: Lab Trends & DDI Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),

          // Trending Lab HbA1c trajectory
          if (_labTrends != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🔬 Trajectory: ${_labTrends!["test_name"]} Trend', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      Text('Ref: ${_labTrends!["reference_range"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF78350F))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_labTrends!['interpretation'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF92400E))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ((_labTrends!['data_points'] as List?) ?? []).map((dp) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFCD34D))),
                        child: Text('${dp["date"]}: ${dp["value"]}% (HIGH)', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Drug Interactions
          if (_drugInteractions != null) ...[
            ...((_drugInteractions!['alerts'] as List?) ?? []).map((alert) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
                child: Row(
                  children: [
                    const Icon(Icons.sync_problem, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${alert["drug_pair"]} [${alert["severity"]}]', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                          Text(alert['warning'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF15803D))),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentTimelineCard() {
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
              Icon(Icons.timeline, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('Chronological Medical Journey & Care Episodes (D4)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _timelineEvents.length,
            separatorBuilder: (_, __) => const Divider(height: 14),
            itemBuilder: (ctx, i) {
              final ev = _timelineEvents[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                    child: Text(ev['date'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${ev["type"]}: ${ev["title"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text(ev['details'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScannedDocumentsOcrCard() {
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
              Icon(Icons.document_scanner_outlined, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('Scanned Prior Records & OCR Text Viewer (D5)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          ..._scannedDocs.map((doc) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(doc['title'] ?? 'Scanned Record', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('OCR Confidence: ${doc["confidence"] ?? 92}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Text(doc['ocr_text'] ?? '', style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Color(0xFF334155))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhysicalExamEntryCard() {
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
                  Icon(Icons.notes, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Physical Examination Templates & Notes (D7)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                icon: const Icon(Icons.save, size: 14),
                label: const Text('SAVE EXAM FINDINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await _service.saveDoctorNotes({
                    'encounter_id': 'enc-001',
                    'patient_id': 'pat-rajesh-001',
                    'general_exam': _generalExamCtrl.text,
                    'systemic_cvs': _cvsExamCtrl.text,
                    'systemic_rs': _rsExamCtrl.text,
                    'systemic_abdomen': _abdomenExamCtrl.text,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Examination notes saved to patient encounter!'), backgroundColor: Color(0xFF059669)),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _generalExamCtrl, decoration: const InputDecoration(labelText: 'General Physical Examination', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _cvsExamCtrl, decoration: const InputDecoration(labelText: 'Cardiovascular System (CVS)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _rsExamCtrl, decoration: const InputDecoration(labelText: 'Respiratory System (RS)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _abdomenExamCtrl, decoration: const InputDecoration(labelText: 'Abdomen / GI', border: OutlineInputBorder())),
        ],
      ),
    );
  }

  Widget _buildPhysicianCommitCard() {
    final isCommitted = _activeSummary?['status'] == 'FINAL_COMMITTED';

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
                  Icon(Icons.verified, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('One-Click EHR Sign-Off & Dual Prescription (D8 & D10)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
                icon: const Icon(Icons.medication, size: 14),
                label: const Text('CREATE DUAL RX (D8)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: _showDualPrescriptionDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Digitally signs the pre-consult history, merges physical examination findings, and synchronizes the FHIR R4 Clinical Artifact with ABDM M3 repository.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCommitted ? const Color(0xFF059669) : const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSigningOff
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(isCommitted ? Icons.check_circle : Icons.draw, size: 18),
                  label: Text(
                    isCommitted ? 'SIGNED OFF & PUSHED TO ABDM M3' : 'COMMIT & DIGITALLY SIGN ENCOUNTER (D10)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: (_isSigningOff || isCommitted) ? null : _commitSignoff,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
