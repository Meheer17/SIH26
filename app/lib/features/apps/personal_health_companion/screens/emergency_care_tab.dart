import 'dart:async';
import 'package:flutter/material.dart';
import '../services/phc_service.dart';

class EmergencyCareTab extends StatefulWidget {
  const EmergencyCareTab({super.key});

  @override
  State<EmergencyCareTab> createState() => _EmergencyCareTabState();
}

class _EmergencyCareTabState extends State<EmergencyCareTab> with SingleTickerProviderStateMixin {
  final PhcService _phcService = PhcService();

  bool _isLoading = true;
  Map<String, dynamic>? _sosState;
  Map<String, dynamic>? _medicalId;
  List<dynamic> _contacts = [];
  List<dynamic> _hospitals = [];

  // Countdown timer for active SOS
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  late AnimationController _sosPulseController;

  @override
  void initState() {
    super.initState();
    _sosPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _loadEmergencyData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sosPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _phcService.getEmergencySosStatus(),
        _phcService.getEmergencyMedicalId(),
        _phcService.getEmergencyContacts(),
        _phcService.getNearbyHospitals(),
      ]);

      if (mounted) {
        setState(() {
          _sosState = results[0] as Map<String, dynamic>?;
          _medicalId = results[1] as Map<String, dynamic>?;
          _contacts = results[2] as List<dynamic>? ?? [];
          _hospitals = results[3] as List<dynamic>? ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading emergency data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startSosCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds <= 1) {
        timer.cancel();
        _confirmTriggerSos();
      } else {
        setState(() => _countdownSeconds--);
      }
    });
  }

  Future<void> _confirmTriggerSos() async {
    _countdownTimer?.cancel();
    final res = await _phcService.triggerEmergencySos(
      lat: 25.3176,
      lng: 82.9739,
      address: 'Assi Ghat, Varanasi, Uttar Pradesh',
      triggerType: 'manual_button',
      reason: 'Acute Heat Exhaustion & Extreme Dizziness',
    );
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 EMERGENCY SOS BROADCASTED: Caregivers & BHU Trauma Centre alerted!'),
          backgroundColor: Color(0xFFE11D48),
          duration: Duration(seconds: 4),
        ),
      );
      _loadEmergencyData();
    }
  }

  Future<void> _cancelSos() async {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 0);
    final res = await _phcService.cancelEmergencySos();
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Emergency SOS Cancelled. Caregivers notified of user safety.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      _loadEmergencyData();
    }
  }

  Future<void> _simulateFallDetection() async {
    final res = await _phcService.reportFallDetected();
    if (res != null && mounted) {
      _startSosCountdown();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFFFEF2F2),
          title: Row(
            children: const [
              Icon(Icons.warning, color: Color(0xFFE11D48)),
              SizedBox(width: 8),
              Text('Impact & Fall Detected!', style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '3.8G deceleration spike followed by 28 seconds zero movement. Auto-SOS will dispatch in 30 seconds unless cancelled.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
              ),
              const SizedBox(height: 16),
              Text('$_countdownSeconds s', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFE11D48))),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                _cancelSos();
              },
              child: const Text("I'm Okay (Cancel SOS)"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showAddContactDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController(text: 'Family Member');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDB2777), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                await _phcService.addEmergencyContact({
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                  'relationship': relCtrl.text,
                  'is_primary': false,
                });
                _loadEmergencyData();
              }
            },
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)));
    }

    final isSosActive = _sosState?['is_active'] == true || _countdownSeconds > 0;
    final sosStatus = _sosState?['status'] ?? 'IDLE';

    return RefreshIndicator(
      onRefresh: _loadEmergencyData,
      color: const Color(0xFFE11D48),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Emergency SOS Button Card
            _buildSosActionCard(isSosActive, sosStatus),
            const SizedBox(height: 20),

            // Emergency Medical ID Card (Lockscreen-Ready)
            _buildMedicalIdCard(),
            const SizedBox(height: 20),

            // Emergency Contacts Hierarchy
            _buildEmergencyContactsCard(),
            const SizedBox(height: 20),

            // Nearby Emergency Trauma Centres & Hospitals
            _buildNearbyHospitalsCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSosActionCard(bool isActive, String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF1F2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0), width: isActive ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: isActive ? const Color(0x33E11D48) : const Color(0x060F172A),
            blurRadius: isActive ? 16 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('EMERGENCY RESCUE SENTINEL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFE11D48), letterSpacing: 0.8)),
                  Text('Dispatches GPS, Medical ID & Vitals to 112 & Contacts', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFE11D48) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'SOS ACTIVE' : 'READY',
                  style: TextStyle(color: isActive ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Central SOS Circle Button
          GestureDetector(
            onTap: isActive ? _cancelSos : () => _startSosCountdown(),
            child: AnimatedBuilder(
              animation: _sosPulseController,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isActive
                          ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                          : [const Color(0xFFE11D48), const Color(0xFFBE123C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: isActive ? 0.6 : 0.3 * _sosPulseController.value),
                        blurRadius: isActive ? 24 : 14,
                        spreadRadius: isActive ? 8 : 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isActive ? Icons.close : Icons.emergency, color: Colors.white, size: 36),
                        const SizedBox(height: 4),
                        Text(
                          isActive ? (_countdownSeconds > 0 ? '$_countdownSeconds s\nCANCEL' : 'STAND\nDOWN') : 'SOS',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isActive
                ? 'Ambulance & Trauma response en route (ETA: 8 mins). GPS Coordinates broadcasted.'
                : 'Press SOS for 1-Tap Emergency Broadcast. Works offline via emergency SMS fallback.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: isActive ? const Color(0xFF991B1B) : const Color(0xFF64748B), fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
          ),
          const SizedBox(height: 14),

          // Secondary Fall Simulation Action
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE11D48),
              side: const BorderSide(color: Color(0xFFFDA4AF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.screen_rotation, size: 16),
            label: const Text('Test Fall Detection Trigger', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _simulateFallDetection,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalIdCard() {
    final name = _medicalId?['full_name'] ?? 'Ramesh Chandra Patel';
    final blood = _medicalId?['blood_group'] ?? 'O+';
    final allergies = _medicalId?['allergies'] as List<dynamic>? ?? [];
    final conditions = _medicalId?['chronic_conditions'] as List<dynamic>? ?? [];
    final meds = _medicalId?['current_medications'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
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
              Row(
                children: const [
                  Icon(Icons.badge, color: Color(0xFFDB2777), size: 20),
                  SizedBox(width: 8),
                  Text('EMERGENCY MEDICAL ID CARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
                child: const Text('Lockscreen Accessible', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4338CA))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    const Text('ABHA: 91-4829-5710-3849 • Age 44', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    const Text('BLOOD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                    Text(blood, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFDC2626))),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          _buildMedicalIdRow('Clinical Allergies:', allergies.join(', '), const Color(0xFFE11D48)),
          const SizedBox(height: 8),
          _buildMedicalIdRow('Diagnosed Conditions:', conditions.join(', '), const Color(0xFFD97706)),
          const SizedBox(height: 8),
          _buildMedicalIdRow('Active Prescriptions:', meds.join(', '), const Color(0xFF0284C7)),
          const SizedBox(height: 8),
          _buildMedicalIdRow('Organ Donor Status:', 'Registered Donor (NOTTO India)', const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildMedicalIdRow(String label, String value, Color bulletColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 3, backgroundColor: bulletColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildEmergencyContactsCard() {
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
              Row(
                children: const [
                  Icon(Icons.contacts, color: Color(0xFF0284C7), size: 18),
                  SizedBox(width: 8),
                  Text('EMERGENCY CONTACTS HIERARCHY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF0284C7), size: 20),
                onPressed: _showAddContactDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _contacts.length,
            separatorBuilder: (_, _) => const Divider(height: 12),
            itemBuilder: (context, idx) {
              final c = _contacts[idx];
              final isPrimary = c['is_primary'] == true;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isPrimary ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    child: Icon(Icons.phone, size: 14, color: isPrimary ? const Color(0xFF15803D) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(c['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            if (isPrimary) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                                child: const Text('PRIMARY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                              ),
                            ],
                          ],
                        ),
                        Text('${c['relationship']} • ${c['phone']}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_forwarded, size: 16, color: Color(0xFF059669)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${c['name']} (${c['phone']})...')),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyHospitalsCard() {
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
            children: const [
              Text('NEARBY EMERGENCY HOSPITALS & TRAUMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              Text('Live Bed Tracker', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hospitals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final h = _hospitals[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            h['name'] ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: Text('${h['distance_km']} km • ${h['eta_mins']} mins', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(h['type'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bed, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text('${h['icu_beds_available']} ICU Beds', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                            const SizedBox(width: 8),
                            if (h['heat_stroke_unit'] == true) ...[
                              const Icon(Icons.ac_unit, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 4),
                              const Text('Heat Unit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                            ],
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 28),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.phone, size: 11),
                          label: const Text('Call Trauma', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dialing emergency hotline: ${h['emergency_phone']}...'), backgroundColor: const Color(0xFFE11D48)),
                            );
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
    );
  }
}
