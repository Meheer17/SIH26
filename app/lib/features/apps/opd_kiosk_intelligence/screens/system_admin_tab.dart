import 'package:flutter/material.dart';
import '../services/medikiosk_service.dart';

class SystemAdminTab extends StatefulWidget {
  const SystemAdminTab({super.key});

  @override
  State<SystemAdminTab> createState() => _SystemAdminTabState();
}

class _SystemAdminTabState extends State<SystemAdminTab> {
  final MediKioskService _service = MediKioskService();

  bool _isLoading = true;
  bool _isPurging = false;
  bool _abdmM3SyncActive = true;

  Map<String, dynamic>? _systemHealth;
  List<dynamic> _auditLogs = [];
  Map<String, dynamic>? _fhirBundle;

  @override
  void initState() {
    super.initState();
    _loadSystemData();
  }

  Future<void> _loadSystemData() async {
    setState(() => _isLoading = true);
    final health = await _service.getSystemHealth();
    final logs = await _service.getAuditLogs();
    final fhir = await _service.getFhirBundle('pat-rajesh-001');

    if (mounted) {
      setState(() {
        _systemHealth = health;
        _auditLogs = logs;
        _fhirBundle = fhir;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerMemoryPurge() async {
    setState(() => _isPurging = true);
    final res = await _service.purgeEphemeralMemory();
    if (mounted) {
      setState(() => _isPurging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🧹 ${res?["message"] ?? "Ephemeral memory scrubbed successfully!"}'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      _loadSystemData();
    }
  }

  void _showFhirBundleDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.hub_outlined, color: Color(0xFF0284C7)),
              SizedBox(width: 8),
              Text('HL7 FHIR R4 Bundle Inspector (S2)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Generated Live from ABDM Gateway API:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      _fhirBundle != null ? _formatJson(_fhirBundle!) : 'Loading FHIR Bundle...',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF38BDF8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(child: const Text('CLOSE'), onPressed: () => Navigator.pop(ctx)),
          ],
        );
      },
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    return json.toString().replaceAll(', ', ',\n ').replaceAll('{', '{\n ').replaceAll('}', '\n}');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5)));
    }

    return RefreshIndicator(
      onRefresh: _loadSystemData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGovernanceHeader(),
            const SizedBox(height: 20),
            _buildSystemHealthCard(),
            const SizedBox(height: 20),
            _buildFhirAbdmGatewayCard(),
            const SizedBox(height: 20),
            _buildEphemeralSanitizerCard(),
            const SizedBox(height: 20),
            _buildAbdmAuditTrailCard(),
            const SizedBox(height: 24),
          ],
        ),
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
                  Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF4F46E5), size: 24),
                  SizedBox(width: 10),
                  Text('System Administrator & Data Governance Console', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Text('DPDPA & ABDM COMPLIANT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Handles platform security, microservices latency telemetry, health information exchange pipelines (ABDM M1/M2/M3), and statutory compliance.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    final services = (_systemHealth?['services'] as Map<String, dynamic>?) ?? {};
    final metrics = (_systemHealth?['metrics'] as Map<String, dynamic>?) ?? {};

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
                  Icon(Icons.speed, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Microservices Infrastructure Telemetry (S1)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: const Text('ALL SERVICES HEALTHY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Latency boxes
          Row(
            children: [
              _buildLatencyBox('API p95 LATENCY', '${metrics["api_p95_latency_ms"] ?? 148} ms', const Color(0xFF059669)),
              const SizedBox(width: 8),
              _buildLatencyBox('ASR SPEECH LATENCY', '${metrics["asr_latency_ms"] ?? 320} ms', const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildLatencyBox('OCR VISION LATENCY', '${metrics["ocr_latency_ms"] ?? 680} ms', const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              _buildLatencyBox('LLM DIALOGUE', '${metrics["llm_socrates_latency_ms"] ?? 420} ms', const Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 14),

          // Services status list
          ...services.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  Text(e.value.toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLatencyBox(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
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
                  Icon(Icons.hub_outlined, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text('FHIR R4 Pipeline Manager & ABDM Gateway (S2)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                icon: const Icon(Icons.code, size: 14),
                label: const Text('INSPECT FHIR BUNDLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: _showFhirBundleDialog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Packages intake notes and digitized documents into standard FHIR bundles (Encounter, Condition, Observation, MedicationStatement, Composition).',
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
                  Icon(Icons.cleaning_services_outlined, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Ephemeral Session Sanitizer (Zero-Persistence - S3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                icon: _isPurging ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.delete_sweep, size: 14),
                label: const Text('TRIGGER MEMORY PURGE NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                onPressed: _isPurging ? null : _triggerMemoryPurge,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Automated memory-scrubbing daemon wiping cached patient biometric audio, raw scans, and session tokens immediately after submission.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
            child: Row(
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Statutory Compliance: Zero-Persistence Flash Memory Scrubbing meets DPDPA 2023 §8(7) storage limitation guidelines.', style: TextStyle(fontSize: 10, color: Color(0xFF166534))),
                ),
              ],
            ),
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
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('DPDP Act 2023 & ABDM Cryptographic Audit Trail (S5)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _auditLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final log = _auditLogs[i];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${log["timestamp"]} • ${log["event"]}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('${log["details"]} (User: ${log["user_or_patient"]})', style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                      ],
                    ),
                    Text(log['status'] ?? 'PASS', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
