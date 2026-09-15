import 'package:flutter/material.dart';

class AdminGovernanceTab extends StatefulWidget {
  const AdminGovernanceTab({super.key});

  @override
  State<AdminGovernanceTab> createState() => _AdminGovernanceTabState();
}

class _AdminGovernanceTabState extends State<AdminGovernanceTab> {
  bool _dualKeyAuthActive = true;
  bool _differentialPrivacyActive = true;
  bool _airGappedMilitaryEncryption = true;
  double _epsilonNoiseValue = 0.5;

  final List<Map<String, String>> _auditLog = [
    {'time': '14:32:10', 'admin': 'Unit MO Dr. Sharma', 'action': 'TRIAGE_QUERY', 'target': 'P-8841-MED (Tier 3)', 'status': 'DUAL_KEY_VERIFIED'},
    {'time': '13:15:04', 'admin': 'CO Col. Verma', 'action': 'AGGREGATE_EXPORT', 'target': 'USFI Heatmap (Bravo Co)', 'status': 'NOISE_INJECTED (ε=0.5)'},
    {'time': '11:04:22', 'admin': 'SysAdmin Ops', 'action': 'HRMS_ETL_SYNC', 'target': '3rd Battalion Postings', 'status': 'FHIR_COMPLIANT_SUCCESS'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Security & Governance Console
          _buildGovernanceHeader(),
          const SizedBox(height: 20),

          // Dual-Key Access Control & Emergency Override
          _buildDualKeyControlCard(),
          const SizedBox(height: 20),

          // Immutable Anti-Stigmatization Audit Trail
          _buildAuditTrailCard(),
          const SizedBox(height: 20),

          // Defense HRMS Data Ingestion & Differential Privacy Engine
          _buildDataEngineCard(),
          const SizedBox(height: 20),

          // Cybersecurity & Model Bias Monitor
          _buildSecurityAndBiasCard(),
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
                    'System Administrator & Governance Console',
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
                  'MIL-SPEC ZERO TRUST',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Manages platform integrity, cryptographic privacy barriers, HRMS data connectors, and anti-stigmatization governance policies.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDualKeyControlCard() {
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
              Icon(Icons.vpn_key_outlined, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text(
                'Strict Dual-Key Access Control (CO + MO Consensus)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Unlocks protected non-anonymized records only during extreme life-safety emergencies through dual cryptographic consensus keys.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Require Dual-Key Consensus to View Identifiable Files', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Enforces both Commanding Officer & Medical Officer cryptographic signatures.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _dualKeyAuthActive,
            activeTrackColor: const Color(0xFFE11D48),
            onChanged: (v) => setState(() => _dualKeyAuthActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailCard() {
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
                  Icon(Icons.receipt_long, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    'Immutable Anti-Stigmatization Audit Log',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                child: const Text('APPEND-ONLY BLOCKCHAIN', style: TextStyle(color: Color(0xFF0284C7), fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            children: _auditLog.map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${log["time"]} • ${log["admin"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('${log["action"]} on ${log["target"]}', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
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

  Widget _buildDataEngineCard() {
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
              Icon(Icons.hub_outlined, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text(
                'Defense HRMS Ingestion & Differential Privacy Engine',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('Inject ε-Differential Privacy Noise into Exports', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            subtitle: const Text('Prevents re-identification of personnel in small detachments.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            value: _differentialPrivacyActive,
            activeTrackColor: const Color(0xFF7C3AED),
            onChanged: (v) => setState(() => _differentialPrivacyActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAndBiasCard() {
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
              Icon(Icons.security, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Hardware Security & ML Model Bias Monitor',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('AES-256 GCM Air-Gapped Encryption', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                      SizedBox(height: 2),
                      Text('Complies with military intranet on-premises deployment.', style: TextStyle(fontSize: 9, color: Color(0xFF15803D))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ML Fairness Audit (0.02% Bias)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                      SizedBox(height: 2),
                      Text('Audits false positives across ranks and combat arms.', style: TextStyle(fontSize: 9, color: Color(0xFF1D4ED8))),
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
}
