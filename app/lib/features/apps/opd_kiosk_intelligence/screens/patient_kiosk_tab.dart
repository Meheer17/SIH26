import 'package:flutter/material.dart';

class PatientKioskTab extends StatefulWidget {
  const PatientKioskTab({super.key});

  @override
  State<PatientKioskTab> createState() => _PatientKioskTabState();
}

class _PatientKioskTabState extends State<PatientKioskTab> {
  // End-to-End Patient Journey Active Step (1 to 5)
  int _activeJourneyStep = 2; // Step 2: Converse active

  // ABHA Check-In State
  bool _isAbhaVerified = true;
  String _abhaNumber = '91-8842-1094-8812';
  String _patientName = 'Rajesh Kumar (Age: 48, Male)';

  // Vernacular Voice & Audio Consent State
  String _selectedLanguage = 'Hindi (हिन्दी)';
  bool _audioConsentGranted = true;
  bool _isListeningVoice = false;
  String _voiceInputText = "Spoken: '2 दिनों से सीने में हल्का दर्द और सांस लेने में तकलीफ हो रही है'";

  // Dual-Mode Body Map Selection
  String _selectedBodySite = 'Chest / Respiratory';

  // SOCRATES Symptom Prober State
  double _severityValue = 6.0; // 1-10 scale
  bool _redFlagTriggered = false;

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
    '10. Vaya (Age / Chronological Stage)': 'Madhyama Vaya (48 Years)',
  };

  // OCR Document Scanner State
  bool _isScanningDocument = false;
  String _scannedDocSummary = 'Scanned: AI4Bharat OCR -> Past Prescription: Tab Amlodipine 5mg (2025), ECG Normal';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Kiosk Status & Language Selector
          _buildKioskHeader(),
          const SizedBox(height: 16),

          // MediKiosk 5-Step End-to-End Patient Journey Stepper
          _buildPatientJourneyStepper(),
          const SizedBox(height: 20),

          // Red-Flag Emergency Alert Interceptor (If Triggered)
          if (_redFlagTriggered) ...[
            _buildRedFlagAlertBanner(),
            const SizedBox(height: 20),
          ],

          // Step 1: ABHA Multi-Modal Check-In & Audio Consent Card
          _buildAbhaCheckinCard(),
          const SizedBox(height: 20),

          // Step 2: Conversational Intake & Dual-Mode Body Map UI
          _buildDualModeIntakeCard(),
          const SizedBox(height: 20),

          // SOCRATES & Full AYUSH Dashavidha 10-Parameter Assessment
          _buildSocratesAyushCard(),
          const SizedBox(height: 20),

          // Step 3: Multilingual Medical OCR Scanner & Zero-Touch Assist
          _buildOcrScannerCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKioskHeader() {
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
                const Text(
                  'Multilingual Voice-First Clinical History Platform • 22 Scheduled Languages • ABDM FHIR Sync',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Color(0xFF059669)),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            items: ['Hindi (हिन्दी)', 'Tamil (தமிழ்)', 'Bengali (বাংলা)', 'Telugu (తెలుగు)', 'Marathi (मराठी)', 'English']
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (val) => setState(() => _selectedLanguage = val!),
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

  Widget _buildRedFlagAlertBanner() {
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
              children: const [
                Text(
                  'CRITICAL RED-FLAG INTERCEPTED: ACUTE CHEST PAIN / STRIDOR',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF9F1239)),
                ),
                SizedBox(height: 2),
                Text(
                  'Patient diverted immediately to Emergency Triage Desk #1. Stretcher dispatch notification sent to nursing staff.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFBE123C)),
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
            onPressed: () => setState(() => _redFlagTriggered = false),
            child: const Text('DISMISS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAbhaCheckinCard() {
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
                      Text(_patientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('ABHA ID: $_abhaNumber • ABDM Token #99412', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
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
                        content: Text('Playing DPDP Act 2023 Audio Consent in $_selectedLanguage...'),
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

  Widget _buildDualModeIntakeCard() {
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
            _isListeningVoice ? 'Bhashini Noise-Robust ASR active... Speak naturally.' : _voiceInputText,
            style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          const Text('Or Select Body Region (Large Pictorial Touch Map):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          Row(
            children: bodySites.map((site) {
              final isSelected = _selectedBodySite == site['name'];
              final color = site['color'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedBodySite = site['name'] as String),
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

  Widget _buildSocratesAyushCard() {
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
                onPressed: () => setState(() => _redFlagTriggered = true),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // SOCRATES Severity Slider
          Text('SOCRATES Symptom Severity Scale: ${_severityValue.toInt()} / 10', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Slider(
            value: _severityValue,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: _severityValue > 7 ? const Color(0xFFE11D48) : const Color(0xFF059669),
            label: '${_severityValue.toInt()}',
            onChanged: (v) => setState(() => _severityValue = v),
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
