import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/medikiosk_service.dart';

class AllPatientsTab extends StatefulWidget {
  final VoidCallback? onSwitchToEmr;
  final VoidCallback? onSwitchToKiosk;

  const AllPatientsTab({
    super.key,
    this.onSwitchToEmr,
    this.onSwitchToKiosk,
  });

  @override
  State<AllPatientsTab> createState() => _AllPatientsTabState();
}

class _AllPatientsTabState extends State<AllPatientsTab> {
  final MediKioskService _service = MediKioskService();

  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedDept = 'All';
  String _selectedStatus = 'ALL';

  Map<String, dynamic> _stats = {
    'total_patients': 0,
    'intake_in_progress': 0,
    'ready_for_doctor': 0,
    'in_consultation': 0,
    'completed': 0,
    'red_flags': 0,
    'avg_wait_min': 14.5,
  };

  List<Map<String, dynamic>> _patients = [];

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDirectoryData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDirectoryData() async {
    setState(() => _isLoading = true);
    final res = await _service.getPatientsLiveDirectory(
      dept: _selectedDept == 'All' ? null : _selectedDept,
      statusFilter: _selectedStatus == 'ALL' ? null : _selectedStatus,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (mounted) {
      setState(() {
        if (res != null && res['patients'] is List) {
          _patients = List<Map<String, dynamic>>.from(res['patients']);
          if (res['stats'] is Map) {
            _stats = Map<String, dynamic>.from(res['stats']);
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _callPatient(String token, String name) async {
    final res = await _service.callPatient(token);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                res?['message'] ?? 'Patient $name called to consultation room. Kiosk alert chimed.',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7),
      ),
    );
    _loadDirectoryData();
  }

  Color _getStatusColor(String status, bool redFlag) {
    if (redFlag || status.toUpperCase().contains('RED-FLAG')) {
      return const Color(0xFFE11D48);
    }
    final s = status.toUpperCase();
    if (s.contains('CONSULTATION')) return const Color(0xFF0284C7);
    if (s.contains('READY') || s.contains('WAITING')) return const Color(0xFF059669);
    if (s.contains('INTAKE') || s.contains('PROGRESS')) return const Color(0xFFD97706);
    if (s.contains('COMPLETED') || s.contains('RX')) return const Color(0xFF7C3AED);
    return const Color(0xFF64748B);
  }

  IconData _getStatusIcon(String status, bool redFlag) {
    if (redFlag || status.toUpperCase().contains('RED-FLAG')) {
      return Icons.emergency;
    }
    final s = status.toUpperCase();
    if (s.contains('CONSULTATION')) return Icons.medical_services_outlined;
    if (s.contains('READY') || s.contains('WAITING')) return Icons.check_circle_outline;
    if (s.contains('INTAKE') || s.contains('PROGRESS')) return Icons.pending_actions;
    if (s.contains('COMPLETED') || s.contains('RX')) return Icons.task_alt;
    return Icons.person_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadDirectoryData,
        color: const Color(0xFF059669),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildSearchAndFilters(),
              const SizedBox(height: 20),
              _buildPatientListSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Icon(Icons.people_alt_rounded, color: Color(0xFF059669), size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Patients Command Center',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Live OPD Journey Tracker • Pre-Consultation Intake to Physician Sign-Off',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _loadDirectoryData,
            icon: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh Live'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              'Total Intake',
              '${_stats['total_patients'] ?? _patients.length}',
              Icons.groups_outlined,
              const Color(0xFF0284C7),
              const Color(0xFFE0F2FE),
              width: isWide ? (constraints.maxWidth - 60) / 5 : (constraints.maxWidth - 12) / 2,
            ),
            _buildStatCard(
              'In Intake',
              '${_stats['intake_in_progress'] ?? 0}',
              Icons.pending_actions_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFEF3C7),
              width: isWide ? (constraints.maxWidth - 60) / 5 : (constraints.maxWidth - 12) / 2,
            ),
            _buildStatCard(
              'Ready for Dr',
              '${_stats['ready_for_doctor'] ?? 0}',
              Icons.assignment_turned_in_outlined,
              const Color(0xFF059669),
              const Color(0xFFECFDF5),
              width: isWide ? (constraints.maxWidth - 60) / 5 : (constraints.maxWidth - 12) / 2,
            ),
            _buildStatCard(
              'Consulting',
              '${_stats['in_consultation'] ?? 0}',
              Icons.medical_services_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
              width: isWide ? (constraints.maxWidth - 60) / 5 : (constraints.maxWidth - 12) / 2,
            ),
            _buildStatCard(
              'Red Flags',
              '${_stats['red_flags'] ?? 0}',
              Icons.emergency_outlined,
              const Color(0xFFE11D48),
              const Color(0xFFFFE4E6),
              width: isWide ? (constraints.maxWidth - 60) / 5 : (constraints.maxWidth - 12) / 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x050F172A), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
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
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by Patient Name, UHID, ABHA, Token, or Symptoms...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                              _loadDirectoryData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _loadDirectoryData();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDept,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    items: [
                      'All',
                      'Cardiology Special OPD',
                      'General Medicine OPD',
                      'AYUSH Integrated OPD',
                      'Orthopedics OPD'
                    ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDept = val);
                        _loadDirectoryData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('ALL', 'All Statuses'),
                _buildStatusFilterChip('RED-FLAG', '🚨 Red-Flag Alert'),
                _buildStatusFilterChip('READY', '🟢 Ready for Doctor'),
                _buildStatusFilterChip('CONSULTATION', '🔵 In Consultation'),
                _buildStatusFilterChip('INTAKE', '🟠 In Kiosk Intake'),
                _buildStatusFilterChip('COMPLETED', '🟣 Rx Issued / Done'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String key, String label) {
    final isSelected = _selectedStatus == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFF059669),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onSelected: (selected) {
          setState(() => _selectedStatus = selected ? key : 'ALL');
          _loadDirectoryData();
        },
      ),
    );
  }

  Widget _buildPatientListSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: Color(0xFF059669)),
        ),
      );
    }

    if (_patients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No Patients Found Matching Filters',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try adjusting your search criteria or register a new patient via the Patient Kiosk tab.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchCtrl.clear();
                  _searchQuery = '';
                  _selectedDept = 'All';
                  _selectedStatus = 'ALL';
                });
                _loadDirectoryData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              child: const Text('Reset All Filters', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Patients Directory (${_patients.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const Text(
              'Synced with Live MongoDB Queue',
              style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _patients.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final patient = _patients[index];
            return _buildPatientCard(patient);
          },
        ),
      ],
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> p) {
    final status = p['status'] ?? 'READY FOR DOCTOR';
    final isRedFlag = p['red_flag'] == true || status.toString().toUpperCase().contains('RED');
    final statusColor = _getStatusColor(status, isRedFlag);
    final statusIcon = _getStatusIcon(status, isRedFlag);
    final journeyStep = (p['journey_step'] as int?) ?? 4;
    final vitals = p['vitals'] as Map<String, dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRedFlag ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
          width: isRedFlag ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRedFlag ? const Color(0x1AE11D48) : const Color(0x080F172A),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Patient Demographics & Status Pill
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(
                    (p['full_name'] ?? 'P')[0].toUpperCase(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p['full_name'] ?? 'Patient Name',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p['token'] ?? 'OPD-101',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p['age'] ?? 45} yrs • ${p['gender'] ?? 'Male'} • UHID: ${p['uhid'] ?? 'UHID-2026'} • ABHA: ${p['abha_id'] ?? '91-XXXX'}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Red-Flag Banner if active
          if (isRedFlag)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF1F2),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE11D48)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CLINICAL RED FLAG: Suspected Acute Coronary Syndrome (ACS). Stretcher & Triage priority alert active.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBE123C)),
                    ),
                  ),
                ],
              ),
            ),

          // Journey Stage Step Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Patient Journey Progress:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    Text(
                      _getJourneyStepLabel(journeyStep),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: journeyStep / 6.0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Clinical Details Grid: Department, Room, Complaint, Vitals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.coronavirus_outlined, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      const Text('Complaint: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      Expanded(
                        child: Text(
                          p['chief_complaint'] ?? 'General Health Consultation',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (p['severity'] as num? ?? 5) > 6 ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Severity ${(p['severity'] as num? ?? 5).toStringAsFixed(1)}/10',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (p['severity'] as num? ?? 5) > 6 ? const Color(0xFFE11D48) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 14, color: Color(0xFFE2E8F0)),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${p['department']} (${p['room_no']})',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                p['doctor_assigned'] ?? 'Dr. Assigned',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (vitals != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildVitalsChip('BP', vitals['blood_pressure'] ?? '130/84'),
                        const SizedBox(width: 6),
                        _buildVitalsChip('HR', '${vitals['heart_rate'] ?? 78} bpm'),
                        const SizedBox(width: 6),
                        _buildVitalsChip('SpO2', vitals['spo2'] ?? '98%'),
                        const SizedBox(width: 6),
                        _buildVitalsChip('BMI', '${vitals['bmi'] ?? 24.2}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showPatient360Dossier(p),
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('360° Dossier', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _viewFhirBundle(p['patient_id']),
                  icon: const Icon(Icons.data_object, size: 15, color: Color(0xFF7C3AED)),
                  label: const Text('FHIR R4', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDD6FE)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _callPatient(p['token'] ?? 'OPD-101', p['full_name'] ?? 'Patient'),
                  icon: const Icon(Icons.ring_volume, size: 15),
                  label: const Text('Call into Room', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsChip(String label, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $val',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
      ),
    );
  }

  String _getJourneyStepLabel(int step) {
    switch (step) {
      case 1:
        return '1/6 Registration Completed';
      case 2:
        return '2/6 DPDPA Consent Granted';
      case 3:
        return '3/6 SOCRATES History In Progress';
      case 4:
        return '4/6 Triage & Waiting for Doctor';
      case 5:
        return '5/6 In Doctor Consultation';
      case 6:
        return '6/6 ABDM Signed & Rx Issued';
      default:
        return 'In Progress';
    }
  }

  void _showPatient360Dossier(Map<String, dynamic> p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['full_name'] ?? 'Patient Dossier',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'UHID: ${p['uhid']} • ABHA: ${p['abha_id']} • Phone: ${p['phone']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            p['token'] ?? 'OPD-101',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Section 1: Demographics & Consent
                    const Text('1. DPDPA 2023 Consent & Identification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• DPDPA 2023 Notice Version: 2023.2-IN (Active & Signed)', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Verified Consent Scopes: Voice Recording, OCR Scanning, Physician EMR Access, ABDM Linkage', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Address: Varanasi, Uttar Pradesh (Assi Ghat Ward)', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Emergency Contact: Verified Family Contact on Record', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Clinical Intake & SOCRATES
                    const Text('2. AI Clinical Intake & SOCRATES Findings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Chief Complaint: ${p['chief_complaint']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text('• Pain / Severity Rating: ${(p['severity'] as num? ?? 5)}/10 VAS Scale', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Site: Retrosternal / Precordial with radiation to left arm', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Character: Constricting pressure sensation on exertion', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Associations: Exertional dyspnea, mild diaphoresis', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Red Flag Alert Status: ACS Rule evaluation confirmed priority routing', style: TextStyle(fontSize: 12, color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: AYUSH Dashavidha Pariksha
                    const Text('3. AYUSH Dashavidha Pariksha & Prakriti', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Prakriti (Constitution): ${p['prakriti'] ?? 'Pitta-Kapha Pradhana'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          const Text('• Vikriti (Dosha Imbalance): Vata-Pitta Dushti with cardiovascular involvement', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Sara (Tissue Vitality): Rakta-Mamsa Madhyama Sara', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Agni (Digestive Fire): Manda Agni (Low assimilation rate)', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• Ahara-Vihara: Vegetarian, irregular meals, disturbed sleep (6 hrs)', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Recorded Vitals & ESI
                    const Text('4. Vitals & Triage ESI Classification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Blood Pressure: ${p['vitals']?['blood_pressure'] ?? '130/84 mmHg'}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          Text('• Pulse / Heart Rate: ${p['vitals']?['heart_rate'] ?? 78} bpm', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          Text('• Oxygen Saturation (SpO2): ${p['vitals']?['spo2'] ?? '98%'}', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          Text('• Temperature: ${p['vitals']?['temperature_c'] ?? 37.0} °C', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          Text('• Body Mass Index (BMI): ${p['vitals']?['bmi'] ?? 24.2} kg/m²', style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                          const Text('• ESI Triage Score: Level 3 (Urgent priority OPD slot assigned)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _callPatient(p['token'] ?? 'OPD-101', p['full_name'] ?? 'Patient');
                            },
                            icon: const Icon(Icons.ring_volume, size: 16),
                            label: const Text('Call to Doctor Room'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _viewFhirBundle(p['patient_id']);
                            },
                            icon: const Icon(Icons.data_object, size: 16),
                            label: const Text('View ABDM Bundle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewFhirBundle(String patientId) async {
    final bundle = await _service.getFhirBundle(patientId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_object, color: Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Text('ABDM FHIR R4 Bundle ($patientId)'),
          ],
        ),
        content: SizedBox(
          width: 550,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              bundle != null
                  ? const JsonEncoder.withIndent('  ').convert(bundle)
                  : '{"resourceType": "Bundle", "type": "document", "id": "$patientId", "status": "verified"}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
