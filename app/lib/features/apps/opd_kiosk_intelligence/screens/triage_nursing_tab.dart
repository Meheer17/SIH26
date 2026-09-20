import 'package:flutter/material.dart';
import '../services/medikiosk_service.dart';

class TriageNursingTab extends StatefulWidget {
  const TriageNursingTab({super.key});

  @override
  State<TriageNursingTab> createState() => _TriageNursingTabState();
}

class _TriageNursingTabState extends State<TriageNursingTab> {
  final MediKioskService _service = MediKioskService();

  bool _isLoading = true;
  List<dynamic> _alerts = [];
  Map<String, dynamic>? _adminDashboard;

  // Vitals Form Controllers
  final _patIdCtrl = TextEditingController(text: 'pat-rajesh-001');
  final _bpSysCtrl = TextEditingController(text: '138');
  final _bpDiaCtrl = TextEditingController(text: '88');
  final _hrCtrl = TextEditingController(text: '82');
  final _tempCtrl = TextEditingController(text: '37.1');
  final _spo2Ctrl = TextEditingController(text: '97');
  final _rrCtrl = TextEditingController(text: '18');
  final _heightCtrl = TextEditingController(text: '172');
  final _weightCtrl = TextEditingController(text: '72');

  int _selectedEsiLevel = 3;
  String _routingDept = 'Cardiology Special OPD';
  bool _isRecordingVitals = false;
  Map<String, dynamic>? _lastRecordedVitals;

  @override
  void initState() {
    super.initState();
    _loadTriageData();
  }

  Future<void> _loadTriageData() async {
    setState(() => _isLoading = true);
    final alerts = await _service.getTriageAlerts();
    final dash = await _service.getAdminDashboard();
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _adminDashboard = dash;
        _isLoading = false;
      });
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    final res = await _service.acknowledgeAlert(alertId);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${res["message"] ?? "Alert acknowledged"}'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      _loadTriageData();
    }
  }

  Future<void> _resolveAlert(String alertId) async {
    final res = await _service.resolveAlert(alertId);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${res["message"] ?? "Emergency alert resolved"}'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
      _loadTriageData();
    }
  }

  Future<void> _submitVitals() async {
    setState(() => _isRecordingVitals = true);
    final data = {
      'patient_id': _patIdCtrl.text.trim(),
      'blood_pressure_sys': int.tryParse(_bpSysCtrl.text) ?? 120,
      'blood_pressure_dia': int.tryParse(_bpDiaCtrl.text) ?? 80,
      'heart_rate_bpm': int.tryParse(_hrCtrl.text) ?? 72,
      'temperature_c': double.tryParse(_tempCtrl.text) ?? 37.0,
      'spo2_pct': int.tryParse(_spo2Ctrl.text) ?? 98,
      'respiratory_rate': int.tryParse(_rrCtrl.text) ?? 16,
      'weight_kg': double.tryParse(_weightCtrl.text) ?? 70.0,
      'height_cm': double.tryParse(_heightCtrl.text) ?? 170.0,
    };

    final res = await _service.recordVitals(data);
    if (mounted) {
      setState(() {
        _isRecordingVitals = false;
        _lastRecordedVitals = res?['vitals'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${res?["message"] ?? "Vitals recorded successfully"}'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _submitEsi() async {
    final res = await _service.assignEsi(_patIdCtrl.text.trim(), _selectedEsiLevel, _routingDept);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ESI Level $_selectedEsiLevel (${res?["esi_title"]}) Assigned → $_routingDept'),
          backgroundColor: const Color(0xFF7C3AED),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
    }

    return RefreshIndicator(
      onRefresh: _loadTriageData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTriageHeader(),
            const SizedBox(height: 20),
            _buildEmergencyAlertConsole(),
            const SizedBox(height: 20),
            _buildVitalsEntryStation(),
            const SizedBox(height: 20),
            _buildEsiTriageScoringCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageHeader() {
    final criticalAlerts = _alerts.where((a) => a['severity'] == 'CRITICAL' && a['status'] != 'RESOLVED').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emergency_rounded, color: Color(0xFFE11D48), size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Triage & Emergency Dispatch Station', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text('Continuous Kiosk Telemetry • Red-Flag Triggers • ESI Level 1-5 Triage', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (_adminDashboard != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'KIOSKS: ${_adminDashboard!['active_kiosks'] ?? 4} ONLINE',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: criticalAlerts > 0 ? const Color(0xFFFFE4E6) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: criticalAlerts > 0 ? const Color(0xFFFECDD3) : const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: criticalAlerts > 0 ? const Color(0xFFE11D48) : const Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      criticalAlerts > 0 ? '$criticalAlerts ACTIVE RED FLAGS' : 'ALL KIOSKS NORMAL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: criticalAlerts > 0 ? const Color(0xFFE11D48) : const Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertConsole() {
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
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 22),
                  SizedBox(width: 8),
                  Text('Real-Time Red-Flag Alert Interceptor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              IconButton(icon: const Icon(Icons.refresh, size: 18), onPressed: _loadTriageData, tooltip: 'Refresh Alerts'),
            ],
          ),
          const SizedBox(height: 12),
          if (_alerts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No active red-flag emergency alerts. Kiosk screening operational.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final a = _alerts[i];
                final isCritical = a['severity'] == 'CRITICAL';
                final isResolved = a['status'] == 'RESOLVED';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isResolved ? const Color(0xFFF8FAFC) : (isCritical ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isResolved ? const Color(0xFFE2E8F0) : (isCritical ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCritical ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(a['flag_title'] ?? 'EMERGENCY ALERT', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text('From: ${a["kiosk_id"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                          Text(
                            a['status'] ?? 'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isResolved ? const Color(0xFF059669) : (isCritical ? const Color(0xFFE11D48) : const Color(0xFFD97706)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Patient: ${a["patient_name"]} (${a["age"]}y, ${a["gender"]})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text('Symptoms: ${a["symptoms"]}', style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                      if (a['action_taken'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Action Taken: ${a["action_taken"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (a['status'] != 'RESOLVED' && a['status'] != 'NURSING ACKNOWLEDGED')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE11D48),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.flash_on, size: 14),
                              label: const Text('DISPATCH STRETCHER & ACK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => _acknowledgeAlert(a['id']),
                            ),
                          const SizedBox(width: 8),
                          if (a['status'] != 'RESOLVED')
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF059669),
                                side: const BorderSide(color: Color(0xFF059669)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 14),
                              label: const Text('MARK RESOLVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => _resolveAlert(a['id']),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVitalsEntryStation() {
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
                  Icon(Icons.monitor_heart_outlined, color: Color(0xFF059669), size: 22),
                  SizedBox(width: 8),
                  Text('Triage Nurse Vitals Entry Station', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                child: const Text('BLUETOOTH / MANUAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Record physiological parameters for Kiosk patients lacking built-in vitals sensors.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 16),

          TextField(
            controller: _patIdCtrl,
            decoration: const InputDecoration(labelText: 'Patient ID / UHID *', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bpSysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'BP Sys (mmHg)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _bpDiaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'BP Dia (mmHg)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _hrCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pulse (BPM)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _spo2Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'SpO2 (%)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tempCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Temp (°C)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rrCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Resp Rate (/min)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isRecordingVitals ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, size: 16),
            label: const Text('SAVE VITALS & AUTO-CALCULATE BMI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _isRecordingVitals ? null : _submitVitals,
          ),

          if (_lastRecordedVitals != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ Last Vitals Recorded:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF166534))),
                  const SizedBox(height: 4),
                  Text('BP: ${_lastRecordedVitals!["blood_pressure"]} • Pulse: ${_lastRecordedVitals!["heart_rate"]} bpm • SpO2: ${_lastRecordedVitals!["spo2"]} • BMI: ${_lastRecordedVitals!["bmi"]}', style: const TextStyle(fontSize: 10, color: Color(0xFF15803D))),
                  if ((_lastRecordedVitals!['abnormal_flags'] as List).isNotEmpty)
                    Text('⚠️ Abnormals: ${(_lastRecordedVitals!["abnormal_flags"] as List).join(", ")}', style: const TextStyle(fontSize: 10, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEsiTriageScoringCard() {
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
              Icon(Icons.format_list_numbered, color: Color(0xFF7C3AED), size: 22),
              SizedBox(width: 8),
              Text('Emergency Severity Index (ESI 1–5) Triage Scoring', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Assign priority level to bypass or optimize OPD consultation waiting time.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            children: [
              _buildEsiChip(1, 'ESI-1: Resuscitation (Immediate)', const Color(0xFFE11D48)),
              _buildEsiChip(2, 'ESI-2: Emergent (High Risk)', const Color(0xFFEA580C)),
              _buildEsiChip(3, 'ESI-3: Urgent (Multiple Resources)', const Color(0xFFD97706)),
              _buildEsiChip(4, 'ESI-4: Less Urgent (1 Resource)', const Color(0xFF0284C7)),
              _buildEsiChip(5, 'ESI-5: Non-Urgent (Advice)', const Color(0xFF059669)),
            ],
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            initialValue: _routingDept,
            decoration: const InputDecoration(labelText: 'Routing Department', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: ['Cardiology Special OPD', 'General Medicine OPD', 'AYUSH Integrated OPD', 'Orthopedics OPD', 'Emergency Resuscitation Unit']
                .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                .toList(),
            onChanged: (v) => setState(() => _routingDept = v!),
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('COMMIT ESI SCORE & ROUTE TO OPD QUEUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _submitEsi,
          ),
        ],
      ),
    );
  }

  Widget _buildEsiChip(int level, String label, Color color) {
    final isSelected = _selectedEsiLevel == level;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : color)),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      onSelected: (_) => setState(() => _selectedEsiLevel = level),
    );
  }
}
