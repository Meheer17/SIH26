import 'package:flutter/material.dart';
import '../services/phc_service.dart';

class MedsTelemedicineTab extends StatefulWidget {
  const MedsTelemedicineTab({super.key});

  @override
  State<MedsTelemedicineTab> createState() => _MedsTelemedicineTabState();
}

class _MedsTelemedicineTabState extends State<MedsTelemedicineTab> with SingleTickerProviderStateMixin {
  final PhcService _phcService = PhcService();

  late TabController _subTabController;
  bool _isLoading = true;

  List<dynamic> _medications = [];
  Map<String, dynamic>? _adherenceData;
  List<dynamic> _doctors = [];
  List<dynamic> _appointments = [];
  List<dynamic> _records = [];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _phcService.getMedications(),
        _phcService.getMedicationAdherence(),
        _phcService.getTelemedicineDoctors(),
        _phcService.getTelemedicineAppointments(),
        _phcService.getHealthRecords(),
      ]);

      if (mounted) {
        setState(() {
          _medications = results[0] as List<dynamic>? ?? [];
          _adherenceData = results[1] as Map<String, dynamic>?;
          _doctors = results[2] as List<dynamic>? ?? [];
          _appointments = results[3] as List<dynamic>? ?? [];
          _records = results[4] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleMedicationStatus(String id, String currentStatus) async {
    final nextStatus = currentStatus == 'taken' ? 'pending' : 'taken';
    final res = await _phcService.logMedicationStatus(id, nextStatus);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medication marked as ${nextStatus.toUpperCase()}.'),
          backgroundColor: nextStatus == 'taken' ? const Color(0xFF059669) : const Color(0xFFD97706),
          duration: const Duration(seconds: 1),
        ),
      );
      _loadAllData();
    }
  }

  Future<void> _showAddMedicationDialog() async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final freqCtrl = TextEditingController(text: 'Once Daily (Morning)');
    final timeCtrl = TextEditingController(text: 'After Breakfast');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Medication Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Drug Name (e.g. Tab Telmisartan 40mg)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: doseCtrl, decoration: const InputDecoration(labelText: 'Dosage (e.g. 40 mg)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: freqCtrl, decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Timing Instructions', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                await _phcService.addMedication({
                  'name': nameCtrl.text,
                  'dosage': doseCtrl.text.isEmpty ? '1 tablet' : doseCtrl.text,
                  'frequency': freqCtrl.text,
                  'timing': timeCtrl.text,
                  'category': 'Prescription Drug',
                  'total_tablets': 30,
                  'remaining_tablets': 30,
                  'instructions': timeCtrl.text,
                });
                _loadAllData();
              }
            },
            child: const Text('Save Medication'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBookDoctorDialog(dynamic doc) async {
    final complaintCtrl = TextEditingController(text: 'Follow-up for blood pressure and heat-stress hydration advisories.');
    String consultationType = 'video';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.video_call, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Book Consultation: ${doc['name']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${doc['specialty']} • ${doc['hospital']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.verified, color: Color(0xFF4338CA), size: 16),
                    SizedBox(width: 6),
                    Text('Cashless under Ayushman PM-JAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: complaintCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Chief Complaint / Medical Query', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: consultationType,
                decoration: const InputDecoration(labelText: 'Consultation Mode', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'video', child: Text('Telemedicine Video Call')),
                  DropdownMenuItem(value: 'audio', child: Text('Audio Call (Low Bandwidth)')),
                ],
                onChanged: (val) => setDState(() => consultationType = val ?? 'video'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await _phcService.bookTelemedicineAppointment(
                  doctorId: doc['id'] ?? '',
                  appointmentTime: 'Today, in 15 mins',
                  chiefComplaint: complaintCtrl.text,
                  consultationType: consultationType,
                );
                if (res != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Appointment confirmed. Video link generated.'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                  _loadAllData();
                }
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUploadRecordDialog() async {
    final titleCtrl = TextEditingController();
    final providerCtrl = TextEditingController(text: 'BHU Pathology Lab');
    final notesCtrl = TextEditingController();
    String category = 'Lab Diagnostic Report';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setRState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Vault Health Record (AES-256)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Document Title (e.g. ECG Scan)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Lab Diagnostic Report', child: Text('Lab Report')),
                  DropdownMenuItem(value: 'Prescription', child: Text('Doctor Prescription')),
                  DropdownMenuItem(value: 'Discharge Summary', child: Text('Hospital Discharge')),
                  DropdownMenuItem(value: 'Vaccination Certificate', child: Text('Vaccine Certificate')),
                ],
                onChanged: (val) => setRState(() => category = val ?? 'Lab Diagnostic Report'),
              ),
              const SizedBox(height: 10),
              TextField(controller: providerCtrl, decoration: const InputDecoration(labelText: 'Issuing Clinic / Hospital', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Clinical Summary / Values', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty) {
                  Navigator.pop(ctx);
                  await _phcService.uploadHealthRecord({
                    'title': titleCtrl.text,
                    'category': category,
                    'doctor_or_lab': providerCtrl.text,
                    'date_recorded': DateTime.now().toString().substring(0, 10),
                    'summary_notes': notesCtrl.text.isEmpty ? 'Verified document' : notesCtrl.text,
                    'tags': ['manual_upload', category.toLowerCase()],
                  });
                  _loadAllData();
                }
              },
              child: const Text('Encrypt & Vault'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
    }

    return Column(
      children: [
        // Sub-tabs Header
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            labelColor: const Color(0xFF059669),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF059669),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.medication, size: 18), text: 'Medications'),
              Tab(icon: Icon(Icons.video_camera_front, size: 18), text: 'Telemedicine'),
              Tab(icon: Icon(Icons.folder_shared, size: 18), text: 'Records Vault'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _buildMedicationsView(),
              _buildTelemedicineView(),
              _buildRecordsVaultView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationsView() {
    final adherencePct = _adherenceData?['overall_adherence_pct'] ?? 94.5;
    final streakDays = _adherenceData?['streak_days'] ?? 18;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF059669),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adherence Stats Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MEDICATION ADHERENCE RATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                      const SizedBox(height: 4),
                      Text('$adherencePct%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                      Text('$streakDays Consecutive Days Streak', style: const TextStyle(fontSize: 11, color: Color(0xFF047857))),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Drug', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _showAddMedicationDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "TODAY'S PRESCRIBED DOSAGE SCHEDULE",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final m = _medications[idx];
                final isTaken = m['today_status'] == 'taken';
                final id = m['id'] ?? '';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isTaken ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isTaken ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        child: Icon(
                          isTaken ? Icons.check_circle : Icons.medication,
                          color: isTaken ? const Color(0xFF15803D) : const Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('${m['dosage']} • ${m['scheduled_time']} • ${m['timing']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text(m['instructions'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isTaken ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isTaken ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                          size: 26,
                        ),
                        onPressed: () => _toggleMedicationStatus(id, m['today_status'] ?? 'pending'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemedicineView() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF0284C7),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner: Ayushman Telemedicine
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.video_camera_front, color: Color(0xFF0284C7), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ayushman Tele-Sanjeevani Gateway', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0369A1))),
                        SizedBox(height: 2),
                        Text('100% Cashless video consultations with real-time biometric streaming to certified government physicians.', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_appointments.isNotEmpty) ...[
              const Text(
                'YOUR BOOKED CONSULTATIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _appointments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final appt = _appointments[idx];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFDCFCE7),
                          child: Icon(
                            appt['consultation_type'] == 'video' ? Icons.videocam : Icons.phone_in_talk,
                            color: const Color(0xFF16A34A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appt['doctor_name'] ?? 'Doctor Consultation', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text('Scheduled: ${appt['appointment_time']} • ${(appt['status'] ?? 'confirmed').toString().toUpperCase()}', style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600)),
                              if (appt['chief_complaint'] != null)
                                Text('Query: ${appt['chief_complaint']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Connecting to encrypted stream: ${appt['video_link'] ?? 'tele-room'}')),
                            );
                          },
                          child: const Text('Join Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              'AVAILABLE ON-DUTY SPECIALISTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _doctors.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final doc = _doctors[idx];
                final isAvail = doc['available_now'] == true;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFE0F2FE),
                            child: const Icon(Icons.person_pin, color: Color(0xFF0284C7), size: 30),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(doc['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isAvail ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isAvail ? 'ONLINE NOW' : 'NEXT: ${doc['next_slot']}',
                                        style: TextStyle(color: isAvail ? const Color(0xFF15803D) : const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${doc['specialty']} • ${doc['experience_years']} yrs exp', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                Text(doc['hospital'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                              SizedBox(width: 4),
                              Text('4.9 Rating', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              SizedBox(width: 10),
                              Text('Hindi, English, Bhojpuri', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.video_call, size: 16),
                            label: const Text('Consult', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _showBookDoctorDialog(doc),
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
      ),
    );
  }

  Widget _buildRecordsVaultView() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: const Color(0xFF7C3AED),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vault Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ENCRYPTED HEALTH VAULT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF6B21A8))),
                      SizedBox(height: 2),
                      Text('AES-256 Client-Side Encryption', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF581C87))),
                      Text('DPDP Act 2023 Compliant Vault', style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE))),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.cloud_upload, size: 16),
                    label: const Text('Upload', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _showUploadRecordDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'VAULTED MEDICAL DOCUMENTS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final r = _records[idx];
                final id = r['id'] ?? '';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                            child: Text(r['category'] ?? 'Record', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.lock, size: 12, color: Color(0xFF7C3AED)),
                              SizedBox(width: 4),
                              Text('AES-256', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(r['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text('${r['provider']} • Date: ${r['date']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Text(r['summary'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Shared with: ${(r['shared_with'] as List<dynamic>? ?? []).join(', ')}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () async {
                              await _phcService.deleteHealthRecord(id);
                              _loadAllData();
                            },
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
      ),
    );
  }
}
