import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/api/api_client.dart';
import 'login_screen.dart';
import 'admin_roles_screen.dart';
import 'consent_management_screen.dart';
import '../chat/multi_agent_hub_screen.dart';
import '../creative/voice_stress_studio_screen.dart';
import '../apps/sc_st_relief_screen.dart';
import 'authority_dashboard_screen.dart';
import '../apps/nyaya_sahay_screen.dart';
import '../apps/arogya_sathi_screen.dart';
import '../apps/medikiosk_screen.dart';
import '../apps/rakshak_mitra_screen.dart';
import '../creative/cin_screen.dart';
import '../creative/dbscan_outbreak_screen.dart';
import '../creative/cough_screening_screen.dart';
import '../creative/panic_disguise_screen.dart';
import '../creative/family_graph_screen.dart';
import '../creative/groundbreaking_suite_screen.dart';

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({super.key});

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  final _authService = AuthService();
  final _apiClient = ApiClient();
  int _currentTabIndex = 0;
  bool _backendConnected = true;

  final List<Map<String, String>> _demoAccounts = const [
    {'role': 'Victim/Complainant', 'email': 'victim_scst@district.gov.in', 'label': '⚖️ SC/ST Victim (NHAA 14566)', 'icon': '⚖️'},
    {'role': 'District Counselor', 'email': 'legal_officer@district.gov.in', 'label': '👨‍⚕️ District Counselor Desk', 'icon': '👨‍⚕️'},
    {'role': 'District Magistrate/SP', 'email': 'dm_varanasi@up.gov.in', 'label': '🛡️ District Magistrate / SP', 'icon': '🛡️'},
    {'role': 'State Nodal Officer', 'email': 'nodal_state@up.gov.in', 'label': '🏛️ State Nodal Authority', 'icon': '🏛️'},
  ];

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
  }

  Future<void> _checkBackendStatus() async {
    try {
      final res = await _apiClient.get('health');
      if (mounted) {
        setState(() {
          _backendConnected = res is Map && res['status'] == 'healthy';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _backendConnected = false;
        });
      }
    }
  }

  Future<void> _quickLogin(String email) async {
    try {
      await _authService.login(emailOrPhone: email, password: 'demo123456');
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('✅ Switched Persona: ${_authService.currentUser?.fullName} (${_authService.currentUser?.primaryRole})'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Login failed: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '⚖️',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NYAYA-MANAS',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A), letterSpacing: -0.3),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _backendConnected ? const Color(0xFF10B981) : Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _backendConnected ? 'NHAA 14566 Live • 7 Bedrock Agents' : 'Connecting...',
                        style: TextStyle(
                          fontSize: 10,
                          color: _backendConnected ? const Color(0xFF0D9488) : Colors.amber.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Covert Panic Disguise',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(Icons.emergency, color: Color(0xFFDC2626), size: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanicDisguiseScreen()));
            },
          ),
          if (user == null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF0FDFA),
                  foregroundColor: const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFCCFBF1)),
                  ),
                ),
                child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  if (mounted) setState(() {});
                },
              ),
            )
          else
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF0D9488),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              onSelected: (val) {
                if (val == 'logout') _logout();
                if (val == 'admin') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminRolesScreen()));
                if (val == 'consent') Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConsentManagementScreen()));
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text(user.primaryRole, style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'admin', child: Text('🛡️ Admin Role Matrix')),
                const PopupMenuItem(value: 'consent', child: Text('📋 DPDP Consent Manager')),
                const PopupMenuItem(value: 'logout', child: Text('🚪 Sign Out', style: TextStyle(color: Color(0xFFE11D48)))),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildVictimGatewayTab(user),
            const MultiAgentHubScreen(),
            const VoiceStressStudioScreen(),
            const SCSTReliefScreen(),
            const AuthorityDashboardScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: const Color(0xFFF0FDFA),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF0D9488)),
              label: 'Command',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.smart_toy_rounded, color: Color(0xFF4F46E5)),
              label: 'AI Agents',
            ),
            NavigationDestination(
              icon: Icon(Icons.graphic_eq_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.graphic_eq_rounded, color: Color(0xFF0284C7)),
              label: 'Voice AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.gavel_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.gavel_rounded, color: Color(0xFFD97706)),
              label: 'SC/ST Relief',
            ),
            NavigationDestination(
              icon: Icon(Icons.query_stats_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.query_stats_rounded, color: Color(0xFF0D9488)),
              label: 'Authority',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanicDisguiseScreen()));
              },
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.emergency),
              label: const Text('Covert SOS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              elevation: 3,
            )
          : null,
    );
  }

  // ================= TAB 0: VICTIM GATEWAY & MASTER COMMAND CENTER =================
  Widget _buildVictimGatewayTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Persona Switcher Bar
          if (user == null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user, color: Color(0xFF0D9488), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Live Hackathon Demo Persona Switcher',
                        style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Test real Bedrock AI agent inference with verified multi-role personas:',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _demoAccounts.map((acc) {
                      return InkWell(
                        onTap: () => _quickLogin(acc['email']!),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            '${acc['icon']} ${acc['role']}',
                            style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Primary Banner Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('NHAA 14566 HELPLINE', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900)),
                    ),
                    const Text('SC/ST PoA ACT 1989', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Dynamic Victim Mental Health & Distress Prediction System',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.2),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Continuous psychological monitoring, voice stress analytics, predictive crisis escalation, and statutory SC/ST compensation.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NyayaSahayScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D9488),
                  ),
                  icon: const Icon(Icons.speed_rounded, size: 16),
                  label: const Text('Launch Dynamic Distress Gateway'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main 4 SIH Core Feature Modules Grid
          const Text(
            'Core SIH Problem Statement Features',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
          ),
          const SizedBox(height: 4),
          const Text(
            'All core & innovation components implemented for SC/ST atrocity victim protection.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.12,
            children: [
              _buildModuleGridCard(
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Dynamic Distress Score',
                subtitle: 'Longitudinal trend gauge & FIR to trial milestones',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NyayaSahayScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.smart_toy_rounded,
                iconColor: const Color(0xFF4F46E5),
                title: 'Strands Bedrock Agents',
                subtitle: '4 specialized AI agents & live tool call execution',
                onTap: () => setState(() => _currentTabIndex = 1),
              ),
              _buildModuleGridCard(
                icon: Icons.graphic_eq_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Voice Stress Studio',
                subtitle: 'Acoustic pitch jitter, speech rate & emotion radar',
                onTap: () => setState(() => _currentTabIndex = 2),
              ),
              _buildModuleGridCard(
                icon: Icons.gavel_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'SC/ST Relief Portal',
                subtitle: 'Annexure-I compensation calculator & DBT bank sync',
                onTap: () => setState(() => _currentTabIndex = 3),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Additional Modular Systems & Extensions Section (Preserving all previous code!)
          const Text(
            'Additional Modular Systems & Extensions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
          ),
          const SizedBox(height: 4),
          const Text(
            'Integrated modular suites (Clinical, Forces Resilience, CIN Mesh, Family Graph, Panic Disguise).',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.12,
            children: [
              _buildModuleGridCard(
                icon: Icons.medical_services_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Smart OPD & Intake',
                subtitle: 'SOCRATES intake & dual ICD-11 / AYUSH protocols',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MediKioskScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.psychology_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Forces Resilience',
                subtitle: 'Duty burnout formula & acoustic voice mood',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RakshakMitraScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.calculate_rounded,
                iconColor: const Color(0xFFE11D48),
                title: 'Panic Disguise',
                subtitle: 'Covert 9999= calculator PIN & dead-man switch',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanicDisguiseScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.family_restroom_rounded,
                iconColor: const Color(0xFF9333EA),
                title: 'Family Risk Graph',
                subtitle: 'Pedigree NetworkX lineage & hereditary AI',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyGraphScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.hub_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Field Mesh (CIN)',
                subtitle: 'Zero-internet BLE mesh & DBSCAN clusters',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityImmunityNetworkScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Digital Twin Suite',
                subtitle: 'Organ simulation, Health Karma, federated node',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroundbreakingSuiteScreen())),
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildModuleGridCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
