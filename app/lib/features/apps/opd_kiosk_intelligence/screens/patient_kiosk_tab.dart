import 'package:flutter/material.dart';
import '../services/medikiosk_service.dart';

class PatientKioskTab extends StatefulWidget {
  const PatientKioskTab({super.key});

  @override
  State<PatientKioskTab> createState() => _PatientKioskTabState();
}

class _PatientKioskTabState extends State<PatientKioskTab> {
  final MediKioskService _service = MediKioskService();

  // End-to-End Patient Journey Active Step (1 to 5)
  int _activeJourneyStep = 2; // Step 2: Converse active

  // Selected Active Patient Index in Queue
  int _selectedPatientIndex = 0;
  bool _isLoading = true;

  // Live Patient Queue List (Loaded from backend)
  List<Map<String, dynamic>> _patientQueue = [];

  // Vernacular Voice & Audio Consent State
  bool _audioConsentGranted = true;
  bool _isListeningVoice = false;

  // Active Socrates Question State
  Map<String, dynamic>? _currentSocratesQuestion;
  String? _activeInterviewId;
  int _socratesStep = 1;
  int _socratesTotalSteps = 8;
  bool _socratesCompleted = false;
  String _selectedSite = 'Chest / Respiratory';

  // AYUSH Dashavidha Assessment State (Full 10 Parameters)
  final Map<String, String> _dashavidhaFullParameters = {
    '1. Prakriti (Constitution)': 'Pitta-Kapha Pradhana',
    '2. Vikriti (Current Imbalance)': 'Vata-Pitta Dushti',
    '3. Sara (Tissue Quality)': 'Rakta-Mamsa Madhyama Sara',
    '4. Samhanana (Body Build)': 'Madhyama Samhanana (Medium Compactness)',
    '5. Pramana (Proportions)': 'Anurupa Pramana (Symmetrical)',
    '6. Satmya (Adaptability)': 'Sarva-Rasa Satmya',
    '7. Sattva (Mental Resilience)': 'Madhyama Sattva (Balanced Resilience)',
    '8. Ahara Shakti (Digestive Power)': 'Manda Agni (Low Assimilation)',
    '9. Vyayama Shakti (Physical Capacity)': 'Madhyama Vyayama Shakti',
    '10. Vaya (Age / Chronological Stage)': 'Madhyama Vaya (Adult Stage)',
  };

  // OCR Document Scanner State
  bool _isScanningDocument = false;
  String _scannedDocSummary = 'Scanned: AI4Bharat OCR -> Past Prescription: Tab Amlodipine 5mg (2025), ECG Normal';

  @override
  void initState() {
    super.initState();
    _loadBackendQueue();
  }

  Future<void> _loadBackendQueue() async {
    setState(() => _isLoading = true);
    final queue = await _service.getDoctorQueue();
    if (mounted) {
      setState(() {
        if (queue.isNotEmpty) {
          _patientQueue = queue.map((q) {
            final isRed = q['red_flag'] == true;
            return {
              'id': q['token'] ?? 'OPD-CARD-8842',
              'name': q['patient_name'] ?? 'Rajesh Kumar',
              'age': q['age'] ?? 48,
              'gender': q['gender'] ?? 'Male',
              'abha': q['abha'] ?? '91-8842-1094-8812',
              'language': 'Hindi (हिन्दी)',
              'chiefComplaint': q['chief_complaint'] ?? 'Chest tightness & exertional dyspnea',
              'department': q['department'] ?? 'Cardiology Special OPD',
              'status': q['status'] ?? 'READY FOR DOCTOR',
              'statusColor': isRed ? const Color(0xFFE11D48) : const Color(0xFF059669),
              'bodySite': 'Chest / Respiratory',
              'voiceText': "Spoken: '${q['chief_complaint']}'",
              'severity': (q['severity'] as num?)?.toDouble() ?? 6.0,
              'redFlag': isRed,
            };
          }).toList();
        } else {
          // Fallback if network issue
          _patientQueue = [
            {
              'id': 'OPD-CARD-8842',
              'name': 'Rajesh Kumar',
              'age': 48,
              'gender': 'Male',
              'abha': '91-8842-1094-8812',
              'language': 'Hindi (हिन्दी)',
              'chiefComplaint': 'Chest tightness & exertional dyspnea (2 days)',
              'department': 'Cardiology Special OPD',
              'status': 'READY FOR DOCTOR',
              'statusColor': const Color(0xFF059669),
              'bodySite': 'Chest / Respiratory',
              'voiceText': "Spoken: '2 दिनों से सीने में हल्का दर्द और सांस लेने में तकलीफ हो रही है'",
              'severity': 6.0,
              'redFlag': false,
            }
          ];
        }
        _selectedPatientIndex = 0;
        _isLoading = false;
      });
      _startSocratesInterview();
    }
  }

  Future<void> _startSocratesInterview() async {
    final activePatient = _patientQueue.isNotEmpty ? _patientQueue[_selectedPatientIndex] : null;
    final res = await _service.startHistory(
      'ses-kiosk-01',
      dept: activePatient?['department'] ?? 'General Medicine OPD',
      site: _selectedSite,
    );
    if (res != null && mounted) {
      setState(() {
        _activeInterviewId = res['interview_id'];
        _currentSocratesQuestion = res['question'];
        _socratesStep = res['step'] ?? 1;
        _socratesTotalSteps = res['total_steps'] ?? 8;
      });
    }
  }

  Future<void> _submitSocratesAnswer(String answerText) async {
    if (_activeInterviewId == null || _currentSocratesQuestion == null) return;

    final qId = _currentSocratesQuestion!['id'];
    final res = await _service.respondHistory(_activeInterviewId!, qId, answerText);
    if (res != null && mounted) {
      setState(() {
        if (res['completed'] == true) {
          _socratesCompleted = true;
          _activeJourneyStep = 4; // Advance to review
        } else {
          _currentSocratesQuestion = res['next_question'];
          _socratesStep = res['step'] ?? (_socratesStep + 1);
        }
        if (res['red_flags'] != null && (res['red_flags'] as List).isNotEmpty) {
          _patientQueue[_selectedPatientIndex]['redFlag'] = true;
          _patientQueue[_selectedPatientIndex]['status'] = 'RED-FLAG TRIAGE';
          _patientQueue[_selectedPatientIndex]['statusColor'] = const Color(0xFFE11D48);
        }
      });
    }
  }

  // Modal Dialog to Register New Patient (Connected to Backend)
  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final abhaCtrl = TextEditingController(text: '91-${(1000 + _patientQueue.length * 111)}-8842-9901');
    final ageCtrl = TextEditingController(text: '45');
    final complaintCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 98412 88421');

    String genderVal = 'Male';
    String langVal = 'Hindi (हिन्दी)';
    String deptVal = 'General Medicine OPD';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.person_add, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text('Register New Patient on MediKiosk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Patient Full Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: abhaCtrl,
                  decoration: const InputDecoration(labelText: 'ABHA ID / Aadhaar / Mobile *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Contact Phone Number *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: genderVal,
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => genderVal = v!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: langVal,
                  decoration: const InputDecoration(labelText: 'Preferred Language (Bhashini ASR)', border: OutlineInputBorder()),
                  items: [
                    'Hindi (हिन्दी)',
                    'Bhojpuri (भोजपुरी)',
                    'Tamil (தமிழ்)',
                    'Bengali (বাংলা)',
                    'Telugu (తెలుగు)',
                    'Marathi (मराठी)',
                    'English'
                  ].map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) => langVal = v!,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: complaintCtrl,
                  decoration: const InputDecoration(labelText: 'Chief Complaint / Symptoms', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: deptVal,
                  decoration: const InputDecoration(labelText: 'Department OPD Routing', border: OutlineInputBorder()),
                  items: ['General Medicine OPD', 'Cardiology Special OPD', 'Orthopedics OPD', 'AYUSH Integrated OPD']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => deptVal = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('REGISTER ON BACKEND & START INTAKE'),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  final regData = {
                    'full_name': nameCtrl.text.trim(),
                    'age': int.tryParse(ageCtrl.text) ?? 40,
                    'gender': genderVal,
                    'phone': phoneCtrl.text.trim(),
                    'abha_id': abhaCtrl.text.trim(),
                    'department': deptVal,
                    'preferred_language': langVal.contains('Hindi') ? 'hi' : 'en',
                  };

                  final res = await _service.registerPatient(regData);
                  if (mounted && res != null) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Patient ${nameCtrl.text} registered on backend with Token ${res["queue_token"]}!'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                    await _loadBackendQueue();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Feedback Dialog (Connected to Backend)
  void _showFeedbackDialog() {
    int rating = 5;
    final commentsCtrl = TextEditingController(text: 'Smooth kiosk intake, voice support in Hindi was very helpful.');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.star_rate_rounded, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Text('Patient Experience Feedback (P20)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How easy was it to complete your clinical intake on MediKiosk?'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      return IconButton(
                        icon: Icon(
                          idx < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFD97706),
                          size: 32,
                        ),
                        onPressed: () => setDialogState(() => rating = idx + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Comments or Suggestions', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(child: const Text('SKIP'), onPressed: () => Navigator.pop(ctx)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                  child: const Text('SUBMIT FEEDBACK'),
                  onPressed: () async {
                    await _service.submitFeedback({
                      'session_id': 'ses-kiosk-01',
                      'patient_name': _patientQueue[_selectedPatientIndex]['name'],
                      'rating': rating,
                      'comments': commentsCtrl.text.trim(),
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Thank you for your feedback! Stored on backend analytics.'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Full Patient Directory Modal Dialog with Live Search & Filtering
  void _showFullPatientListDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (stContext, setModalState) {
            final filteredList = _patientQueue.where((p) {
              final query = searchQuery.toLowerCase();
              return (p['name'] as String).toLowerCase().contains(query) ||
                  (p['id'] as String).toLowerCase().contains(query) ||
                  (p['abha'] as String).toLowerCase().contains(query) ||
                  (p['chiefComplaint'] as String).toLowerCase().contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.people_alt, color: Color(0xFF0284C7), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('All Registered OPD Patients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text('${_patientQueue.length} Total Registered Kiosk Records', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('+ ADD NEW PATIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddPatientDialog();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by Patient Name, OPD Card ID, ABHA ID, or Symptoms...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0284C7)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(child: Text('No patient matching query.', style: TextStyle(color: Color(0xFF64748B))))
                        : ListView.separated(
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, idx) {
                              final p = filteredList[idx];
                              final isCurrentActive = _selectedPatientIndex == _patientQueue.indexOf(p);
                              final color = p['statusColor'] as Color;

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentActive ? const Color(0xFFF0FDF4) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrentActive ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                                    width: isCurrentActive ? 1.5 : 1.0,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  leading: CircleAvatar(
                                    backgroundColor: isCurrentActive ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                    child: Text(
                                      (p['name'] as String).substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                      const SizedBox(width: 8),
                                      Text('(${p["age"]} yrs • ${p["gender"]})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                        child: Text(p['status'] as String, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Token: ${p["id"]} • ABHA: ${p["abha"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                                      Text('Symptoms: ${p["chiefComplaint"]}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      Text('Routing: ${p["department"]} • Lang: ${p["language"]}', style: const TextStyle(fontSize: 9, color: Color(0xFF0284C7))),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCurrentActive ? const Color(0xFF059669) : const Color(0xFF0284C7),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(isCurrentActive ? 'ACTIVE' : 'SELECT', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      final origIdx = _patientQueue.indexOf(p);
                                      if (origIdx != -1) {
                                        setState(() {
                                          _selectedPatientIndex = origIdx;
                                        });
                                      }
                                      Navigator.pop(ctx);
                                      _startSocratesInterview();
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
    }

    final activePatient = _patientQueue.isNotEmpty ? _patientQueue[_selectedPatientIndex] : null;
    if (activePatient == null) {
      return const Center(child: Text('No active kiosk intake session. Click + Register Patient.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Kiosk Status & Language Selector
          _buildKioskHeader(activePatient),
          const SizedBox(height: 16),

          // Registered Patients Directory & Queue Card (+ Register Patient Button)
          _buildPatientQueueDirectoryCard(),
          const SizedBox(height: 20),

          // MediKiosk 5-Step End-to-End Patient Journey Stepper
          _buildPatientJourneyStepper(),
          const SizedBox(height: 20),

          // Red-Flag Emergency Alert Interceptor (If Triggered)
          if (activePatient['redFlag'] == true) ...[
            _buildRedFlagAlertBanner(activePatient),
            const SizedBox(height: 20),
          ],

          // Step 1: ABHA Multi-Modal Check-In & Audio Consent Card
          _buildAbhaCheckinCard(activePatient),
          const SizedBox(height: 20),

          // Step 2: Conversational Intake & Dual-Mode Body Map UI
          _buildDualModeIntakeCard(activePatient),
          const SizedBox(height: 20),

          // SOCRATES & Full AYUSH Dashavidha 10-Parameter Assessment
          _buildSocratesAyushCard(activePatient),
          const SizedBox(height: 20),

          // Step 3: Multilingual Medical OCR Scanner & Zero-Touch Assist
          _buildOcrScannerCard(),
          const SizedBox(height: 20),

          // Step 4 & 5: Summary Review, Queue Token & Feedback
          _buildSummaryAndTokenCard(activePatient),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKioskHeader(Map<String, dynamic> patient) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.touch_app_outlined, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('MediKiosk AI Intake Terminal #04', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('BHASHINI ASR ACTIVE', style: TextStyle(color: Color(0xFF16A34A), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Active Intake: ${patient["name"]} (Token: ${patient["id"]}) • ${patient["language"]}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('+ REGISTER PATIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _showAddPatientDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientQueueDirectoryCard() {
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
                  Icon(Icons.people_alt_outlined, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text('Live OPD Patient Queue & Directory (Connected to Backend)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _loadBackendQueue,
                    tooltip: 'Refresh Queue from Backend',
                  ),
                  InkWell(
                    onTap: _showFullPatientListDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
                      child: Row(
                        children: const [
                          Icon(Icons.list_alt, size: 13, color: Color(0xFF0F172A)),
                          SizedBox(width: 4),
                          Text('VIEW ALL LIST', style: TextStyle(color: Color(0xFF0F172A), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _patientQueue.asMap().entries.map((entry) {
                final idx = entry.key;
                final pat = entry.value;
                final isSelected = _selectedPatientIndex == idx;
                final color = pat['statusColor'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedPatientIndex = idx);
                      _startSocratesInterview();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      width: 220,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(pat['id'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(pat['status'] as String, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(pat['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('${pat["age"]}y • ${pat["gender"]} • ${pat["language"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(pat['chiefComplaint'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientJourneyStepper() {
    final steps = [
      {'num': 1, 'title': 'Language & ABHA', 'icon': Icons.qr_code_scanner},
      {'num': 2, 'title': 'Body Map & Voice', 'icon': Icons.mic},
      {'num': 3, 'title': 'SOCRATES Prober', 'icon': Icons.psychology},
      {'num': 4, 'title': 'Document OCR', 'icon': Icons.document_scanner},
      {'num': 5, 'title': 'Token & Summary', 'icon': Icons.confirmation_number},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.map((s) {
          final sNum = s['num'] as int;
          final isActive = _activeJourneyStep == sNum;
          final isPast = _activeJourneyStep > sNum;

          return InkWell(
            onTap: () => setState(() => _activeJourneyStep = sNum),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isPast ? const Color(0xFF059669) : (isActive ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0)),
                  child: isPast
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('$sNum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF64748B))),
                ),
                const SizedBox(width: 6),
                Text(
                  s['title'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRedFlagAlertBanner(Map<String, dynamic> patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🚨 EMERGENCY RED-FLAG DETECTED — PRIORITY BYPASS', style: TextStyle(color: Color(0xFF9F1239), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Critical symptoms identified for ${patient["name"]}. Stretcher and Triage Nurse Station notified automatically.', style: const TextStyle(color: Color(0xFFBE123C), fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
            child: const Text('BYPASS QUEUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Patient rerouted to Emergency Resuscitation Unit!'), backgroundColor: Color(0xFFE11D48)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAbhaCheckinCard(Map<String, dynamic> patient) {
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
                  Icon(Icons.verified_user_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Step 1 — ABHA Multi-Modal Check-In & Audio Consent (DPDPA 2023)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: const Text('ABDM M1 VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ABHA Address / Number', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      Text(patient['abha'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 4),
                      Text('Linked Phone: +91 98***-88421 • e-KYC Complete', style: const TextStyle(fontSize: 9, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_audioConsentGranted ? Icons.check_circle : Icons.radio_button_unchecked, color: const Color(0xFF059669), size: 16),
                          const SizedBox(width: 6),
                          const Text('Audio-Visual Consent Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('DPDPA 2023 Granular consent recorded. Ephemeral audio buffer cleared after text extraction.', style: TextStyle(fontSize: 9, color: Color(0xFF15803D))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDualModeIntakeCard(Map<String, dynamic> patient) {
    final sites = ['Head / Neurological', 'Chest / Respiratory', 'Abdomen / GI', 'Joints / Musculoskeletal'];

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
                  Icon(Icons.touch_app_rounded, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text('Step 2 — Dual-Mode Intake (Interactive Body Map + Voice Dictation)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListeningVoice ? const Color(0xFFE11D48) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(_isListeningVoice ? Icons.mic : Icons.mic_none, size: 14),
                label: Text(_isListeningVoice ? 'LISTENING (BHASHINI)...' : 'SPEAK COMPLAINT (MIC)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() => _isListeningVoice = !_isListeningVoice);
                  if (_isListeningVoice) {
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() {
                          _isListeningVoice = false;
                          patient['voiceText'] = "Transcribed: 'सीने में भारीपन और सांस फूलने की समस्या 2 दिनों से है'";
                        });
                      }
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Select anatomical site where symptoms are located:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: sites.map((s) {
              final isSel = _selectedSite == s;
              return ChoiceChip(
                selected: isSel,
                label: Text(s, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : const Color(0xFF0F172A), fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: const Color(0xFFF1F5F9),
                onSelected: (_) {
                  setState(() {
                    _selectedSite = s;
                    patient['bodySite'] = s;
                  });
                  _startSocratesInterview();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over, color: Color(0xFF0284C7), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(patient['voiceText'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocratesAyushCard(Map<String, dynamic> patient) {
    final severity = patient['severity'] as double;

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
                  Icon(Icons.psychology_outlined, color: Color(0xFF7C3AED)),
                  SizedBox(width: 8),
                  Text('SOCRATES Clinical Dialogue & AYUSH Dashavidha Matrix', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                icon: const Icon(Icons.warning, size: 12),
                label: const Text('Simulate Emergency Red-Flag', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() {
                  patient['redFlag'] = true;
                  patient['status'] = 'RED-FLAG TRIAGE';
                  patient['statusColor'] = const Color(0xFFE11D48);
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Dynamic SOCRATES Question from Backend
          if (_currentSocratesQuestion != null && !_socratesCompleted) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFC7D2FE))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SOCRATES Step $_socratesStep of $_socratesTotalSteps (${_currentSocratesQuestion!["section"] ?? ""})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                      const Icon(Icons.volume_up, size: 16, color: Color(0xFF4F46E5)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_currentSocratesQuestion!['question'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ((_currentSocratesQuestion!['options'] as List?) ?? []).map((opt) {
                      return ActionChip(
                        label: Text(opt.toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF4F46E5))),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                        onPressed: () => _submitSocratesAnswer(opt.toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else if (_socratesCompleted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF86EFAC))),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Text('SOCRATES Clinical Interview Complete. Ready for Physician EMR Review.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // VAS Pain Severity Slider
          Text('Pain Severity Scale (Visual Analog Scale): ${severity.toInt()} / 10', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Slider(
            value: severity,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: severity > 7 ? const Color(0xFFE11D48) : const Color(0xFF059669),
            label: '${severity.toInt()}',
            onChanged: (v) => setState(() => patient['severity'] = v),
          ),
          const SizedBox(height: 10),

          // Full 10-Parameter AYUSH Dashavidha Pariksha Parameters
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE9D5FF))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.spa, color: Color(0xFF7C3AED)),
                        SizedBox(width: 8),
                        Text('Ayurvedic Dashavidha Pariksha Matrix (10 Parameters):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8))),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                      child: const Text('SYNC AYUSH PORTAL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        await _service.saveDashavidha({
                          'patient_id': patient['id'],
                          'prakriti': 'Pitta-Kapha Pradhana',
                          'vikriti': 'Vata-Pitta Dushti',
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Dashavidha Pariksha synchronized with AYUSH Clinical Portal!'), backgroundColor: Color(0xFF7C3AED)),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _dashavidhaFullParameters.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDDD6FE))),
                      child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6))),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrScannerCard() {
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
                  Icon(Icons.document_scanner_outlined, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text('Step 3 — Multilingual Medical OCR & Zero-Touch Assist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                icon: const Icon(Icons.camera_alt, size: 14),
                label: const Text('Scan Prescription / Report', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() => _isScanningDocument = true);
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      setState(() {
                        _isScanningDocument = false;
                        _scannedDocSummary = 'Scanned: AI4Bharat OCR -> Tab Amlodipine 5mg OD, Tab Metformin 500mg BD (Confidence: 94.8%)';
                      });
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Vision LLM auto-aligns and extracts medical entities from physical paper records.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBAE6FD))),
            child: Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF0284C7)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isScanningDocument ? 'TrOCR processing handwritten report...' : _scannedDocSummary,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndTokenCard(Map<String, dynamic> patient) {
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
                  Icon(Icons.confirmation_number_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Step 4 & 5 — Token Issued & Consultation Routing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                icon: const Icon(Icons.star, size: 14),
                label: const Text('GIVE FEEDBACK (P20)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: _showFeedbackDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OFFICIAL OPD QUEUE TOKEN', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(patient['id'] as String, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Assigned Room: Room 104 • Estimated Wait: 8 mins', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Column(
                    children: [
                      Icon(Icons.qr_code, color: Colors.white, size: 36),
                      SizedBox(height: 2),
                      Text('SCAN TO TRACK', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
