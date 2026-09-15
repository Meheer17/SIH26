import 'package:flutter/material.dart';

class PhysicianEmrTab extends StatefulWidget {
  const PhysicianEmrTab({super.key});

  @override
  State<PhysicianEmrTab> createState() => _PhysicianEmrTabState();
}

class _PhysicianEmrTabState extends State<PhysicianEmrTab> {
  // Dual-Lens View Toggle: false = Allopathic (ICD-11 / SNOMED), true = AYUSH (NAMASTE / Dashavidha)
  bool _isAyushLensActive = false;

  final Map<String, dynamic> _patientBrief = {
    'name': 'Rajesh Kumar (Age 48, M)',
    'token': 'OPD-CARD-8842',
    'chiefComplaint': 'Chest tightness & exertional dyspnea (2 days)',
    'hpi': 'Gradual onset, severity 6/10, worse on climbing stairs. No radiation to jaw.',
    'pastHistory': 'Essential Hypertension (5 yrs), Type-2 Diabetes Mellitus',
    'ros': 'Cardiovascular: Positive exertional discomfort. Respiratory: Mild shortness of breath.',
    'allopathicCodes': 'ICD-11: BA80 (Angina Pectoris) | SNOMED CT: 194828000',
    'ayushCodes': 'NAMASTE Code: KVT-04 (Hridroga / Vata-Kaphaja Hridroga)',
    'dashavidhaTable': {
      'Prakriti': 'Pitta-Kapha',
      'Vikriti': 'Vata-Pitta Dushti',
      'Agni': 'Manda Agni',
      'Koshtha': 'Krura Koshtha',
      'Ahara': 'Amla / Katu Pradhana',
    },
    'labAlerts': [
      {'test': 'Serum Creatinine', 'val': '1.6 mg/dL', 'status': 'HIGH (Ref: 0.7 - 1.2)', 'color': const Color(0xFFE11D48)},
      {'test': 'HbA1c', 'val': '8.2%', 'status': 'ELEVATED', 'color': const Color(0xFFD97706)},
    ],
    'drugAlerts': [
      {'drug': 'Tab Metformin 500mg + Tab Telmisartan 40mg', 'warning': 'Check eGFR prior to dose escalation', 'color': const Color(0xFFD97706)},
    ],
    'timeline': [
      {'date': '15 Aug 2025', 'event': 'OPD Visit: BP 140/90, Prescribed Amlodipine 5mg'},
      {'date': '02 Dec 2024', 'event': 'Lab Report: HbA1c 7.8%, Normal Liver Function'},
      {'date': '10 Mar 2024', 'event': 'Discharge Summary: Acute Gastritis treated'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Consultation Room View & Lens Toggle
          _buildPhysicianHeader(),
          const SizedBox(height: 20),

          // Standardized Pre-Consult Brief Card (Chief Complaint -> HPI -> ROS)
          _buildPreConsultBriefCard(),
          const SizedBox(height: 20),

          // Diagnostic Support: Lab Alerts & Drug-Drug Interactions (DDI)
          _buildDiagnosticSupportCard(),
          const SizedBox(height: 20),

          // Chronological Document Timeline
          _buildDocumentTimelineCard(),
          const SizedBox(height: 20),

          // Physician Override & One-Click EHR Commit
          _buildPhysicianCommitCard(),
          const SizedBox(height: 24),
        ],
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
                  Icon(Icons.badge_outlined, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Physician EMR & Consultation Room View',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),

              // Dual-Lens Allopathic / AYUSH Toggle Switch
              Row(
                children: [
                  Text(
                    _isAyushLensActive ? 'AYUSH LENS (NAMASTE)' : 'ALLOPATHIC LENS (ICD-11)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isAyushLensActive ? const Color(0xFF7C3AED) : const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: _isAyushLensActive,
                    activeTrackColor: const Color(0xFF7C3AED),
                    inactiveTrackColor: const Color(0xFF4F46E5),
                    onChanged: (v) => setState(() => _isAyushLensActive = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Patient: ${_patientBrief["name"]} • Token: ${_patientBrief["token"]}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPreConsultBriefCard() {
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
                  Icon(Icons.notes, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    '30-Second Standardized Pre-Consult Synopsis',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isAyushLensActive ? const Color(0xFFF3E8FF) : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isAyushLensActive ? 'AYUSH NAMASTE CODES' : 'SNOMED CT / ICD-11',
                  style: TextStyle(
                    color: _isAyushLensActive ? const Color(0xFF7C3AED) : const Color(0xFF0284C7),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildBriefSection('Chief Complaint', _patientBrief['chiefComplaint'] as String, Icons.report_problem_outlined, const Color(0xFFE11D48)),
          const SizedBox(height: 8),
          _buildBriefSection('History of Present Illness (HPI)', _patientBrief['hpi'] as String, Icons.history, const Color(0xFF0284C7)),
          const SizedBox(height: 8),
          _buildBriefSection('Past & Medication History', _patientBrief['pastHistory'] as String, Icons.medication_outlined, const Color(0xFF059669)),

          const SizedBox(height: 12),
          if (!_isAyushLensActive) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Text('Ontology Mapping: ${_patientBrief["allopathicCodes"]}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE9D5FF))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AYUSH Morbidity Mapping: ${_patientBrief["ayushCodes"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8))),
                  const SizedBox(height: 6),
                  const Text('Extracted Dashavidha Pariksha Parameters:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE))),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (_patientBrief['dashavidhaTable'] as Map<String, String>).entries.map((e) {
                      return Chip(
                        label: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 9, color: Color(0xFF5B21B6))),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFDDD6FE)),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBriefSection(String title, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticSupportCard() {
    final labAlerts = _patientBrief['labAlerts'] as List<Map<String, dynamic>>;
    final drugAlerts = _patientBrief['drugAlerts'] as List<Map<String, dynamic>>;

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
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text(
                'Diagnostic Support: Lab Reference & Drug Interaction Alerter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: [
              ...labAlerts.map((l) {
                final color = l['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${l["test"]}: ${l["val"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text(l['status'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                );
              }),
              ...drugAlerts.map((d) {
                final color = d['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
                  child: Row(
                    children: [
                      Icon(Icons.medical_information, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['drug'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text(d['warning'] as String, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTimelineCard() {
    final timeline = _patientBrief['timeline'] as List<Map<String, String>>;

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
            children: const [
              Icon(Icons.timeline, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Chronological Longitudinal Document Timeline',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: timeline.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: Text(item['date']!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item['event']!, style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A))),
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

  Widget _buildPhysicianCommitCard() {
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
            children: const [
              Icon(Icons.check_circle_outline, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Physician Attestation & One-Click EHR Commit',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Clinician retains full decision-making control. Edit or approve AI-generated intake note before pushing directly to hospital e-Hospital / HIS.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('APPROVE & COMMIT TO HIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('EHR Intake Note committed to e-Hospital HIS! ABDM Encounter Artifact generated.'),
                        backgroundColor: Color(0xFF4F46E5),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.mic, size: 16),
                label: const Text('Voice Edit Note', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
