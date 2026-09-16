import 'package:flutter/material.dart';

class PatientKioskTab extends StatefulWidget {
  const PatientKioskTab({super.key});

  @override
  State<PatientKioskTab> createState() => _PatientKioskTabState();
}

class _PatientKioskTabState extends State<PatientKioskTab> {
  // End-to-End Patient Journey Active Step (1 to 5)
  int _activeJourneyStep = 2; // Step 2: Converse active

  // Selected Active Patient Index in Queue
  int _selectedPatientIndex = 0;

  // Live Patient Queue List
  final List<Map<String, dynamic>> _patientQueue = [
    {
      'id': 'OPD-CARD-8842',
      'name': 'Rajesh Kumar',
      'age': 48,
      'gender': 'Male',
      'abha': '91-8842-1094-8812',
      'language': 'Hindi (हिन्दी)',
      'chiefComplaint': 'Chest tightness & exertional dyspnea (2 days)',
      'department': 'Cardiology Special OPD',
      'status': 'INTAKE IN PROGRESS',
      'statusColor': const Color(0xFF0284C7),
      'bodySite': 'Chest / Respiratory',
      'voiceText': "Spoken: '2 दिनों से सीने में हल्का दर्द और सांस लेने में तकलीफ हो रही है'",
      'severity': 6.0,
      'redFlag': false,
    },
    {
      'id': 'OPD-CARD-4109',
      'name': 'Savitri Devi',
      'age': 64,
      'gender': 'Female',
      'abha': '91-4109-7721-0092',
      'language': 'Hindi (हिन्दी)',
      'chiefComplaint': 'Sudden right-side joint swelling & high fever',
      'department': 'AYUSH Integrated OPD',
      'status': 'READY FOR DOCTOR',
      'statusColor': const Color(0xFF059669),
      'bodySite': 'Joints / Musculoskeletal',
      'voiceText': "Spoken: 'घुटने में बहुत तेज दर्द है और बुखार चढ़ रहा है'",
      'severity': 8.0,
      'redFlag': false,
    },
    {
      'id': 'OPD-CARD-9912',
      'name': 'Aarav Sharma',
      'age': 12,
      'gender': 'Male',
      'abha': '91-9912-3341-8810',
      'language': 'English',
      'chiefComplaint': 'Acute wheezing & respiratory stridor post-pollution',
      'department': 'General Medicine OPD',
      'status': 'RED-FLAG TRIAGE',
      'statusColor': const Color(0xFFE11D48),
      'bodySite': 'Chest / Respiratory',
      'voiceText': "Spoken: 'Having severe trouble breathing since morning'",
      'severity': 9.0,
      'redFlag': true,
    },
    {
      'id': 'OPD-CARD-2041',
      'name': 'Sunita Verma',
      'age': 35,
      'gender': 'Female',
      'abha': '91-2041-9981-1120',
      'language': 'Marathi (मराठी)',
      'chiefComplaint': 'Continuous unilateral migraine & nausea',
      'department': 'General Medicine OPD',
      'status': 'REGISTERED / WAITING',
      'statusColor': const Color(0xFFD97706),
      'bodySite': 'Head / Neurological',
      'voiceText': "Spoken: 'डोके खूप दुखत आहे आणि मळमळ होत आहे'",
      'severity': 5.0,
      'redFlag': false,
    },
  ];

  // Vernacular Voice & Audio Consent State
  bool _audioConsentGranted = true;
  bool _isListeningVoice = false;

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

  // Modal Dialog to Register New Patient
  void _showAddPatientDialog() {
    final nameCtrl = TextEditingController();
    final abhaCtrl = TextEditingController(text: '91-${(1000 + _patientQueue.length * 111)}-8842-9901');
    final ageCtrl = TextEditingController(text: '45');
    final complaintCtrl = TextEditingController();

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
              Text('Register New Patient on Kiosk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                        value: genderVal,
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => genderVal = v!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: langVal,
                  decoration: const InputDecoration(labelText: 'Preferred Language (Bhashini ASR)', border: OutlineInputBorder()),
                  items: ['Hindi (हिन्दी)', 'Tamil (தமிழ்)', 'Bengali (বাংলা)', 'Telugu (తెలుగు)', 'Marathi (मराठी)', 'English']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => langVal = v!,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: complaintCtrl,
                  decoration: const InputDecoration(labelText: 'Chief Complaint / Symptoms', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: deptVal,
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
              label: const Text('REGISTER & START INTAKE'),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final newCard = {
                    'id': 'OPD-CARD-${8840 + _patientQueue.length + 1}',
                    'name': nameCtrl.text,
                    'age': int.tryParse(ageCtrl.text) ?? 40,
                    'gender': genderVal,
                    'abha': abhaCtrl.text,
                    'language': langVal,
                    'chiefComplaint': complaintCtrl.text.isNotEmpty ? complaintCtrl.text : 'General Consultation',
                    'department': deptVal,
                    'status': 'INTAKE IN PROGRESS',
                    'statusColor': const Color(0xFF0284C7),
                    'bodySite': 'Chest / Respiratory',
                    'voiceText': "Spoken: '${complaintCtrl.text}'",
                    'severity': 5.0,
                    'redFlag': false,
                  };

                  setState(() {
                    _patientQueue.insert(0, newCard);
                    _selectedPatientIndex = 0;
                    _activeJourneyStep = 2; // Move to Converse step
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Patient ${nameCtrl.text} registered! ABHA Consent verified for ABDM.'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
            ),
          ],
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
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),

                  // Modal Header
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

                  // Search Bar
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
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Patient List View Table
                  Expanded(
                    child: filteredList.isEmpty
                        ? const Center(
                            child: Text('No patient matching your search query.', style: TextStyle(color: Color(0xFF64748B))),
                          )
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Switched active intake session to ${p["name"]} (${p["id"]})'),
                                          backgroundColor: const Color(0xFF0284C7),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
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
    final activePatient = _patientQueue[_selectedPatientIndex];

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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.touch_app_outlined, color: Color(0xFF16A34A), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'MediKiosk AI Intake Terminal #04',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('BHASHINI ASR ACTIVE', style: TextStyle(color: Color(0xFF16A34A), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Active Intake: ${patient["name"]} (Token: ${patient["id"]}) • ${patient["language"]}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  Text(
                    'Live OPD Patient Queue & Directory',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _showFullPatientListDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.list_alt, size: 13, color: Color(0xFF0F172A)),
                          SizedBox(width: 4),
                          Text('VIEW ALL LIST', style: TextStyle(color: Color(0xFF0F172A), fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                    child: Text('${_patientQueue.length} REGISTERED', style: const TextStyle(color: Color(0xFF0284C7), fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Select any patient card to switch active intake session, view digitized records, or trigger SOCRATES prober.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _patientQueue.length,
              itemBuilder: (context, idx) {
                final p = _patientQueue[idx];
                final isSelected = _selectedPatientIndex == idx;
                final color = p['statusColor'] as Color;

                return GestureDetector(
                  onTap: () => setState(() => _selectedPatientIndex = idx),
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p['id'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(p['status'] as String, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Text('${p["name"]} (${p["age"]} ${p["gender"]})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text(p['chiefComplaint'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientJourneyStepper() {
    final steps = [
      {'step': 1, 'label': '1. IDENTIFY', 'desc': 'ABHA / Audio Consent'},
      {'step': 2, 'label': '2. CONVERSE', 'desc': 'Voice Intake & SOCRATES'},
      {'step': 3, 'label': '3. SCAN', 'desc': 'TrOCR Medical Scan'},
      {'step': 4, 'label': '4. ROUTE', 'desc': 'AI Summary → HIS'},
      {'step': 5, 'label': '5. CONSULT', 'desc': 'Physician EMR Brief'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MediKiosk End-to-End Patient Journey Progress:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(steps.length, (idx) {
              final stepNum = steps[idx]['step'] as int;
              final isDone = stepNum <= _activeJourneyStep;
              final isCurrent = stepNum == _activeJourneyStep;
              final color = isDone ? const Color(0xFF059669) : const Color(0xFF94A3B8);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeJourneyStep = stepNum),
                  child: Container(
                    margin: EdgeInsets.only(right: idx == 4 ? 0 : 4),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCurrent ? const Color(0xFFDCFCE7) : (isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                        width: isCurrent ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: color,
                          child: Text(
                            '$stepNum',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[idx]['label'] as String,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRedFlagAlertBanner(Map<String, dynamic> patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency, color: Color(0xFFE11D48), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRITICAL RED-FLAG INTERCEPTED: ${patient["chiefComplaint"]}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF9F1239)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Patient ${patient["name"]} diverted immediately to Emergency Triage Desk #1. Stretcher notification sent.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () => setState(() => patient['redFlag'] = false),
            child: const Text('DISMISS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.qr_code_scanner, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'Step 1 — ABHA Multi-Modal Check-In & Audio Consent',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(8)),
                child: const Text('ABDM CONSENT VERIFIED', style: TextStyle(color: Color(0xFF0284C7), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.person, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${patient["name"]} (Age: ${patient["age"]}, ${patient["gender"]})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('ABHA ID: ${patient["abha"]} • Token ${patient["id"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.volume_up, size: 14),
                  label: const Text('Play Audio Consent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Playing DPDP Act 2023 Audio Consent in ${patient["language"]}...'),
                        backgroundColor: const Color(0xFF0284C7),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualModeIntakeCard(Map<String, dynamic> patient) {
    final bodySites = [
      {'name': 'Chest / Respiratory', 'icon': Icons.favorite_border, 'color': const Color(0xFFE11D48)},
      {'name': 'Head / Neurological', 'icon': Icons.psychology, 'color': const Color(0xFF7C3AED)},
      {'name': 'Abdomen / GI', 'icon': Icons.water_drop_outlined, 'color': const Color(0xFFD97706)},
      {'name': 'Joints / Musculoskeletal', 'icon': Icons.accessibility_new, 'color': const Color(0xFF059669)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.record_voice_over, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    'Step 2 — Conversational Voice Intake & Dual-Mode UI',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isListeningVoice ? const Color(0xFFE11D48) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: Icon(_isListeningVoice ? Icons.stop : Icons.mic, size: 14),
                label: Text(_isListeningVoice ? 'Listening...' : 'Speak Symptoms', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    _isListeningVoice = !_isListeningVoice;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isListeningVoice ? 'Bhashini Noise-Robust ASR active... Speak naturally.' : patient['voiceText'] as String,
            style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          const Text('Or Select Body Region (Large Pictorial Touch Map):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          Row(
            children: bodySites.map((site) {
              final isSelected = (patient['bodySite'] as String) == site['name'];
              final color = site['color'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => patient['bodySite'] = site['name'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFFE2E8F0),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(site['icon'] as IconData, color: color, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          site['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? color : const Color(0xFF0F172A)),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocratesAyushCard(Map<String, dynamic> patient) {
    final double severity = (patient['severity'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  Text(
                    'SOCRATES Symptom Prober & Full AYUSH Dashavidha Matrix',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.warning, size: 12),
                label: const Text('Simulate Emergency Red-Flag', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => patient['redFlag'] = true),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // SOCRATES Severity Slider
          Text('SOCRATES Symptom Severity Scale: ${severity.toInt()} / 10', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9D5FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.spa, color: Color(0xFF7C3AED)),
                    SizedBox(width: 8),
                    Text('Ayurvedic Dashavidha Pariksha Matrix (10 Parameters):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8))),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _dashavidhaFullParameters.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF5B21B6)),
                      ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  Text(
                    'Step 3 — Multilingual Medical OCR & Zero-Touch Assist',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.camera_alt, size: 14),
                label: const Text('Scan Prescription / Report', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: () {
                  setState(() {
                    _isScanningDocument = true;
                  });
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      setState(() {
                        _isScanningDocument = false;
                      });
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Vision LLM / TrOCR auto-aligns, flattens, and crops wrinkled physical paper records without requiring manual positioning by elderly patients.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
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
}
