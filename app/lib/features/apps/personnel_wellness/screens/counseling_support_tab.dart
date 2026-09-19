import 'package:flutter/material.dart';
import '../services/raksha_setu_service.dart';

class CounselingSupportTab extends StatefulWidget {
  final VoidCallback onTriggerSos;

  const CounselingSupportTab({super.key, required this.onTriggerSos});

  @override
  State<CounselingSupportTab> createState() => _CounselingSupportTabState();
}

class _CounselingSupportTabState extends State<CounselingSupportTab> with SingleTickerProviderStateMixin {
  final RakshaSetuService _service = RakshaSetuService();

  late TabController _tabController;
  bool _isLoading = true;

  List<dynamic> _counselors = [];
  List<dynamic> _appointments = [];
  Map<String, dynamic>? _peerBuddy;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final counselors = await _service.fetchCounselors();
      final appointments = await _service.fetchAppointments();
      final peer = await _service.fetchPeerBuddy();
      if (mounted) {
        setState(() {
          _counselors = counselors;
          _appointments = appointments;
          _peerBuddy = peer;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openBookingModal(Map<String, dynamic> counselor) {
    final name = counselor['name'] as String? ?? 'Military Psychologist';
    final slots = (counselor['available_slots'] as List<dynamic>?) ?? ['10:00 - 10:45', '14:30 - 15:15'];
    String selectedSlot = slots.first as String;
    String selectedMode = 'VIDEO_CALL';
    final TextEditingController reasonController = TextEditingController(
      text: 'Operational fatigue debriefing & tactical sleep scheduling',
    );
    bool isAnonymous = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Book Confidential Counseling Session',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Counselor: $name',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(height: 16),

                    const Text('Available Time Slot:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: slots.map((s) {
                        final isSel = selectedSlot == s;
                        return ChoiceChip(
                          label: Text(s as String, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : const Color(0xFF334155))),
                          selected: isSel,
                          selectedColor: const Color(0xFF0284C7),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedSlot = s);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    const Text('Session Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildModeChip('VIDEO_CALL', '📹 Secure Video', selectedMode, (m) => setModalState(() => selectedMode = m)),
                        const SizedBox(width: 8),
                        _buildModeChip('AUDIO_CALL', '📞 Encrypted Call', selectedMode, (m) => setModalState(() => selectedMode = m)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Reason / Operational Concerns',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Anonymous Identity Shield', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Masks belt number and name from unit chain of command (Welfare protected)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      value: isAnonymous,
                      activeColor: const Color(0xFF16A34A),
                      onChanged: (val) => setModalState(() => isAnonymous = val),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            final res = await _service.bookAppointment({
                              'counselor_id': counselor['id'] ?? 'CNS-001',
                              'counselor_name': name,
                              'appointment_date': '2026-09-22',
                              'time_slot': selectedSlot,
                              'session_mode': selectedMode,
                              'reason': reasonController.text,
                              'is_anonymous': isAnonymous,
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Appointment confirmed! Join via app.'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                              _service.fetchAppointments().then((a) => setState(() => _appointments = a));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Booking error: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Confirm Appointment'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeChip(String mode, String label, String curMode, Function(String) onSelect) {
    final isSel = curMode == mode;
    return InkWell(
      onTap: () => onSelect(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF0284C7).withOpacity(0.12) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFF0284C7) : const Color(0xFF334155)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0284C7),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF0284C7),
            tabs: const [
              Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Counselors'),
              Tab(icon: Icon(Icons.event_available, size: 18), text: 'My Bookings'),
              Tab(icon: Icon(Icons.military_tech_outlined, size: 18), text: 'Peer Buddy'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCounselorsTab(),
          _buildAppointmentsTab(),
          _buildPeerBuddyTab(),
        ],
      ),
    );
  }

  // --- SUBTAB 1: COUNSELOR DIRECTORY ---
  Widget _buildCounselorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Emergency SOS Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x33DC2626), blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.emergency_share, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Emergency Sentinel SOS Beacon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('One-tap silent beacon dispatched with GPS to Base Duty MO and Ops Room.', style: TextStyle(fontSize: 11, color: Color(0xFFFEE2E2))),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: widget.onTriggerSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade700,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('TRIGGER'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Authorized Military Psychologists & Tele-MANAS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._counselors.map((c) {
          final name = c['name'] ?? 'Psychologist';
          final desig = c['designation'] ?? '';
          final qual = c['qualification'] ?? '';
          final rating = c['rating'] ?? 5.0;
          final langs = (c['languages'] as List<dynamic>?)?.join(', ') ?? 'Hindi, English';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF0284C7).withOpacity(0.12),
                      child: const Icon(Icons.person, color: Color(0xFF0284C7), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text(desig, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7))),
                          Text(qual, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text('$rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Languages: $langs', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openBookingModal(c as Map<String, dynamic>),
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: const Text('Book Confidential Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- SUBTAB 2: BOOKED APPOINTMENTS ---
  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
      return const Center(
        child: Text(
          'No booked counseling appointments yet.\nBook a confidential session with a psychologist.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final a = _appointments[index];
        final name = a['counselor_name'] ?? 'Counselor';
        final date = a['appointment_date'] ?? 'Upcoming';
        final slot = a['time_slot'] ?? '14:30';
        final mode = a['session_mode'] ?? 'VIDEO_CALL';
        final reason = a['reason'] ?? 'Routine consultation';
        final isAnon = a['is_anonymous'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Text('CONFIRMED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ),
                  if (isAnon)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                      child: const Text('IDENTITY SHIELDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('$date ($slot)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  const SizedBox(width: 12),
                  Icon(mode == 'VIDEO_CALL' ? Icons.videocam : Icons.phone, size: 14, color: const Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(mode == 'VIDEO_CALL' ? 'Secure Video' : 'Encrypted Audio', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 6),
              Text('Topic: $reason', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening secure tele-health room...'), backgroundColor: Color(0xFF0284C7)),
                  );
                },
                icon: const Icon(Icons.video_camera_front, size: 16),
                label: const Text('Join Telehealth Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- SUBTAB 3: PEER BUDDY CONNECT ---
  Widget _buildPeerBuddyTab() {
    final alias = _peerBuddy?['alias'] ?? 'Cheetah-9 (Anonymous Comrade)';
    final unit = _peerBuddy?['unit'] ?? '44th Bn CAPF';
    final profile = _peerBuddy?['deployment_profile'] ?? 'High Altitude Watch';
    final bio = _peerBuddy?['bio'] ?? 'Fellow jawan available for anonymous peer decompression.';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Color(0x060F172A), blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
                    child: const Icon(Icons.shield_moon_outlined, color: Color(0xFF0D9488), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alias, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('$unit • $profile', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Text('ONLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(bio, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4)),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),
              const Text('Shared Outpost Experiences:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: const [
                  Chip(label: Text('Border Sentry Vigil', style: TextStyle(fontSize: 10))),
                  Chip(label: Text('Sub-Zero Acclimatization', style: TextStyle(fontSize: 10))),
                  Chip(label: Text('Family Distance Coping', style: TextStyle(fontSize: 10))),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connected to Cheetah-9. Opening anonymous peer chat...'), backgroundColor: Color(0xFF0D9488)),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Start Anonymous Peer Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
