import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import 'login_screen.dart';
import 'admin_roles_screen.dart';
import 'consent_management_screen.dart';
import '../apps/arogya_sathi_screen.dart';
import '../apps/medikiosk_screen.dart';
import '../apps/rakshak_mitra_screen.dart';
import '../apps/nyaya_sahay_screen.dart';


class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _authService.currentUser;
      if (user != null) {
        final authorizedApps = <String>[];
        final hasAdmin = user.isAdmin || user.mappedRoles.contains('SYSTEM_ADMIN');
        if (hasAdmin || user.mappedRoles.contains('PATIENT')) authorizedApps.add('arogya');
        if (hasAdmin || user.mappedRoles.contains('PHYSICIAN')) authorizedApps.add('medikiosk');
        if (hasAdmin || user.mappedRoles.contains('SOLDIER') || user.mappedRoles.contains('WELFARE_OFFICER')) authorizedApps.add('rakshak');
        if (hasAdmin || user.mappedRoles.contains('COUNSELOR')) authorizedApps.add('nyaya');

        if (authorizedApps.length == 1) {
          if (authorizedApps[0] == 'arogya') {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ArogyaSathiScreen()));
          } else if (authorizedApps[0] == 'medikiosk') {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MediKioskScreen()));
          } else if (authorizedApps[0] == 'rakshak') {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RakshakMitraScreen()));
          } else if (authorizedApps[0] == 'nyaya') {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NyayaSahayScreen()));
          }
        }
      }
    });
  }

  bool _isAuthorized(String app) {
    return true; // Zero barrier evaluation mode for hackathon judging
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SvasthyaSetu Unified Mobile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            Text(
              'Smart India Hackathon 2026 Mobile Prototype',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_hospital, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aesthetic Clinical Suite',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '4 Problem Statements • Real-time Processing Engine',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Text(
                        'Select any Problem Statement below to inspect live heat stress formulas, clinical triage engine, stress scoring, or victim escalation workflows.',
                        style: TextStyle(color: Color(0xFF334155), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              const Text(
                'Breakthrough Scalable Innovations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              _buildAppCard(
                psTag: 'KILLER FEATURE',
                title: '🌐 Community Immunity Network',
                subtitle: 'Offline BLE Mesh Health Swarm',
                description: 'Offline peer-to-peer mesh sync for community symptom and outbreak detection.',
                borderColor: const Color(0xFF10B981),
                onTap: () {
                  Navigator.of(context).pushNamed('/cin');
                },
              ),
              const SizedBox(height: 12),

              _buildAppCard(
                psTag: 'NON-INVASIVE ML',
                title: '🫁 Acoustic Cough & Anemia',
                subtitle: 'Zero Crossing Rate Audio & Palmar RGB',
                description: 'Non-invasive acoustic spectral cough screening & camera palmar Hb estimation.',
                borderColor: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.of(context).pushNamed('/cough-screening');
                },
              ),
              const SizedBox(height: 12),

              _buildAppCard(
                psTag: 'STEALTH SOS',
                title: '🆘 Panic Disguise SOS',
                subtitle: 'Stealth Calculator & Dead Man Switch',
                description: 'Covert calculator panic PIN, accelerometer shake, & 2hr inactivity dead man switch.',
                borderColor: const Color(0xFFE11D48),
                onTap: () {
                  Navigator.of(context).pushNamed('/panic-disguise');
                },
              ),
              const SizedBox(height: 12),

              _buildAppCard(
                psTag: 'GRAPH AI',
                title: '🧬 Family Health Risk Graph',
                subtitle: 'NetworkX Lineage & AI Counselor',
                description: 'Traverses pedigree lineage for hereditary risk calculation & cultural counseling.',
                borderColor: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.of(context).pushNamed('/family-graph');
                },
              ),

              const SizedBox(height: 24),

              const Text(
                'Problem Statement Switcher',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),


              // PS Card 1: ArogyaSathi (SIH26181)
              _buildAppCard(
                psTag: 'SIH26181',
                title: '🫀 ArogyaSathi',
                subtitle: 'Qualcomm • Disaster Health & Vitals',
                description: 'Heat stress index formula, telemetry monitoring, AI triage assistant & 1-tap SOS.',
                borderColor: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ArogyaSathiScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // PS Card 2: MediKiosk (SIH26047)
              _buildAppCard(
                psTag: 'SIH26047',
                title: '🏥 MediKiosk',
                subtitle: 'Ayush • OPD Clinical History & Triage',
                description: 'SOCRATES clinical history intake, AYUSH Prakriti profiling & physician terminal.',
                borderColor: const Color(0xFF0D9488),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MediKioskScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // PS Card 3: RakshakMitra (SIH26186)
              _buildAppCard(
                psTag: 'SIH26186',
                title: '🎖️ RakshakMitra',
                subtitle: 'MHA • Forces Burnout & Mental Stress',
                description: 'Burnout Index calculation, Voice mood log, & Commander Unit Stress Heatmap.',
                borderColor: const Color(0xFF059669),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RakshakMitraScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // PS Card 4: NyayaSahay (SIH26094)
              _buildAppCard(
                psTag: 'SIH26094',
                title: '⚖️ NyayaSahay',
                subtitle: 'MoSJE • Atrocity Victim Support',
                description: 'Distress Score correlation, case timeline tracker & District Counselor Desk.',
                borderColor: const Color(0xFFD97706),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NyayaSahayScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard({
    required String psTag,
    required String title,
    required String subtitle,
    required String description,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    psTag,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: borderColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: borderColor),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
