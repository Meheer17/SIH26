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
    final user = _authService.currentUser;
    if (user == null) return false;
    final hasAdmin = user.isAdmin || user.mappedRoles.contains('SYSTEM_ADMIN');
    if (hasAdmin) return true;
    if (app == 'arogya') return user.mappedRoles.contains('PATIENT');
    if (app == 'medikiosk') return user.mappedRoles.contains('PHYSICIAN');
    if (app == 'rakshak') return user.mappedRoles.contains('SOLDIER') || user.mappedRoles.contains('WELFARE_OFFICER');
    if (app == 'nyaya') return user.mappedRoles.contains('COUNSELOR');
    return false;
  }

  void _handleLogout() {
    _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'SvasthyaSetu Portal',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF43F5E)),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (user.isAdmin) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'ADMIN',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ]
                                ],
                              ),

                              Text(
                                user.emailOrPhone,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Assigned Security Tiers:',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.mappedRoles.map((role) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Toolbar
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ConsentManagementScreen()),
                        );
                      },
                      icon: const Icon(Icons.verified_user_outlined, size: 18),
                      label: const Text('Consent Engine'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.indigoAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.indigoAccent, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  if (user.isAdmin) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminRolesScreen()),
                          );
                        },
                        icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                        label: const Text('Admin Roles'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.amberAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.amberAccent, width: 1.2),
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Available Applications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              // App 1: ArogyaSathi
              if (_isAuthorized('arogya')) ...[
                _buildAppCard(
                  title: '🫀 ArogyaSathi',
                  subtitle: 'Disaster Health & Vitals Monitoring',
                  description: 'Heat stress index, AQI exposure, dehydration tracking, and SOS triggers.',
                  color: const Color(0xFFF43F5E),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ArogyaSathiScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // App 2: MediKiosk
              if (_isAuthorized('medikiosk')) ...[
                _buildAppCard(
                  title: '🏥 MediKiosk',
                  subtitle: 'OPD Clinical History & Triage System',
                  description: 'Conversational history intake, medical doc OCR, & physician terminal.',
                  color: Colors.lightBlueAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MediKioskScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // App 3: RakshakMitra
              if (_isAuthorized('rakshak')) ...[
                _buildAppCard(
                  title: '🎖️ RakshakMitra',
                  subtitle: 'Forces Stress & Burnout Predictor',
                  description: 'Voice mood journals, HRMS data correlation, & commander heatmaps.',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RakshakMitraScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              // App 4: NyayaSahay
              if (_isAuthorized('nyaya')) ...[
                _buildAppCard(
                  title: '⚖️ NyayaSahay',
                  subtitle: 'Atrocity Victim Support & Outreach',
                  description: 'Voice stress analysis, case correlation, and multi-tier escalation.',
                  color: Colors.amberAccent,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NyayaSahayScreen()),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard({
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 14, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
