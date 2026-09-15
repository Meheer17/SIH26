import 'package:flutter/material.dart';

class SystemAdminTab extends StatefulWidget {
  const SystemAdminTab({super.key});

  @override
  State<SystemAdminTab> createState() => _SystemAdminTabState();
}

class _SystemAdminTabState extends State<SystemAdminTab> {
  bool _ephemeralSanitizerActive = true;
  bool _abdmM3SyncActive = true;
  bool _fhirR4BundleActive = true;

  final List<Map<String, String>> _abdmAuditLogs = [
    {'time': '14:40:12', 'event': 'FHIR R4 Bundle Created', 'details': 'Encounter + Condition (BA80) + MedicationStatement', 'status': 'ABDM M3 VERIFIED'},
    {'time': '14:38:05', 'event': 'Ephemeral Memory Sanitized', 'details': 'Scrubbed 4.2MB raw ASR audio & prescription scan', 'status': 'ZERO-PERSISTENCE PASS'},
    {'time': '14:15:20', 'event': 'NIC e-Hospital HIS Sync', 'details': 'HL7 v2 Message ACK received from CDAC MedSys', 'status': 'HIS SYNC SUCCESS'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: System Administrator & Governance
          _buildGovernanceHeader(),
          const SizedBox(height: 20),

          // ABDM Gateway & FHIR R4 Pipeline Manager
          _buildFhirAbdmGatewayCard(),
          const SizedBox(height: 20),

          // Privacy, Security & Ephemeral Session Sanitizer
          _buildEphemeralSanitizerCard(),
          const SizedBox(height: 20),

          // DPDP Act & ABDM Cryptographic Audit Trail
          _buildAbdmAuditTrailCard(),
          const SizedBox(height: 20),

          // Medical OCR & ASR Tuning Workbench
          _buildAsrOcrTuningCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGovernanceHeader() {
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
                  Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'System Administrator & Data Governance Console',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Text(
                  'DPDP & ABDM COMPLIANT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Handles platform security, AI model maintenance, health information exchange pipelines (ABDM M1/M2/M3), and statutory compliance.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFhirAbdmGatewayCard() {
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
              Icon(Icons.hub_outlined, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text(
                'FHIR R4 Pipeline Manager & ABDM Gateway',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Packages intake notes and digitized documents into standard FHIR bundles (Encounter, Condition, Observation, MedicationStatement).',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Enable ABDM M1/M2/M3 Automatic Bundle Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Syncs with e-Hospital, CDAC MedSys, and National Health Stack.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _abdmM3SyncActive,
            activeTrackColor: const Color(0xFF0284C7),
            onChanged: (v) => setState(() => _abdmM3SyncActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildEphemeralSanitizerCard() {
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
              Icon(Icons.cleaning_services_outlined, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Ephemeral Session Sanitizer (Zero-Persistence)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Automated memory-scrubbing daemon wiping cached patient biometric audio, raw scans, and session tokens immediately after submission.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Zero-Persistence Flash Memory Scrubbing Daemon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Wipes raw audio waveforms and prescription camera buffers.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _ephemeralSanitizerActive,
            activeTrackColor: const Color(0xFF059669),
            onChanged: (v) => setState(() => _ephemeralSanitizerActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAbdmAuditTrailCard() {
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
              Icon(Icons.receipt_long, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'DPDP Act 2023 & ABDM Cryptographic Audit Trail',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: _abdmAuditLogs.map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${log["time"]} • ${log["event"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text(log['details']!, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                    Text(log['status']!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAsrOcrTuningCard() {
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
              Icon(Icons.tune, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text(
                'Medical OCR & ASR Tuning Workbench (Active Learning)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Retrains local Bhashini speech models and TrOCR engines on edge cases to handle doctor shorthand and regional accents.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
