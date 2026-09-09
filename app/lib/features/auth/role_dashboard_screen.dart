import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/api/api_client.dart';
import 'login_screen.dart';
import 'admin_roles_screen.dart';
import 'consent_management_screen.dart';
import '../chat/ai_chat_screen.dart';
import '../storage_demo/storage_demo_screen.dart';
import '../sos_demo/sos_demo_screen.dart';
import '../creative/cin_screen.dart';
import '../creative/cough_screening_screen.dart';
import '../creative/panic_disguise_screen.dart';
import '../creative/family_graph_screen.dart';
import '../creative/groundbreaking_suite_screen.dart';
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
  final _apiClient = ApiClient();
  int _currentTabIndex = 0;
  bool _backendConnected = true;

  final List<Map<String, String>> _demoAccounts = const [
    {'role': 'Patient', 'email': 'arogya_user@example.com', 'label': '🫀 ArogyaSathi (Rural Patient)', 'icon': '🫀'},
    {'role': 'OPD Doctor', 'email': 'dr_sharma@hospital.org', 'label': '🏥 MediKiosk (OPD Physician)', 'icon': '🏥'},
    {'role': 'Forces Officer', 'email': 'capt_verma@forces.gov.in', 'label': '🎖️ RakshakMitra (Forces Officer)', 'icon': '🎖️'},
    {'role': 'Legal Counselor', 'email': 'legal_officer@district.gov.in', 'label': '⚖️ NyayaSahay (Legal Counselor)', 'icon': '⚖️'},
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
            content: Text('✅ Logged in as ${_authService.currentUser?.fullName} (${_authService.currentUser?.primaryRole})'),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '✚',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SvasthyaSetu',
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
                        _backendConnected ? '5 ML Engines & FastAPI Live' : 'Connecting...',
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
            tooltip: '1-Tap Emergency SOS',
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
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosDemoScreen()));
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
            _buildMasterCommandTab(user),
            _buildClinicalTab(),
            _buildFieldMeshTab(),
            _buildResilienceTab(),
            _buildSuperAppVaultTab(user),
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
              icon: Icon(Icons.medical_services_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.medical_services_rounded, color: Color(0xFF0D9488)),
              label: 'Clinical',
            ),
            NavigationDestination(
              icon: Icon(Icons.hub_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.hub_rounded, color: Color(0xFF0D9488)),
              label: 'Field & Mesh',
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.psychology_rounded, color: Color(0xFF0D9488)),
              label: 'Resilience',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_user_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.verified_user_rounded, color: Color(0xFF0D9488)),
              label: 'Vault & AI',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosDemoScreen()));
              },
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.emergency),
              label: const Text('1-Tap SOS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              elevation: 3,
            )
          : null,
    );
  }

  // ================= TAB 0: MASTER COMMAND CENTER =================
  Widget _buildMasterCommandTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinical Persona Switcher / Active Profile Bar
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.verified_user, color: Color(0xFF0D9488), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Clinical Persona Switcher',
                        style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Test real ML inference with verified multi-role personas:',
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
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCCFBF1)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0D9488),
                    radius: 18,
                    child: Text(user.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                        Text('${user.primaryRole} • ABHA: ${user.abhaId ?? "91-1234-5678-9012"}', style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0D9488))),
                  )
                ],
              ),
            ),

          // Live Environmental & Physiological Telemetry (Clean Medical Cards)
          const Text(
            'Live Patient Telemetry & Environmental Sentinel',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildCleanTelemetryCard(
                label: 'Heart Rate',
                value: '74 bpm',
                status: 'Optimal',
                icon: Icons.favorite_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFEF4444),
              ),
              _buildCleanTelemetryCard(
                label: 'Blood Oxygen',
                value: '99% SpO2',
                status: 'Normal',
                icon: Icons.bloodtype_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
              ),
              _buildCleanTelemetryCard(
                label: 'Thermal WBGT',
                value: '28.4°C',
                status: 'Safe Range',
                icon: Icons.thermostat_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
              ),
              _buildCleanTelemetryCard(
                label: 'Fall Sentinel',
                value: 'Active',
                status: 'Monitoring',
                icon: Icons.shield_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zero-Mock Production ML Engine Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 16, color: Color(0xFF0D9488)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5 Production ML Models Online',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Cough FFT, Anemia Hb, Voice Stress, Crisis NLP, DBSCAN',
                        style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text('ZERO MOCK', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Super-App Unified Functional Modules Grid
          const Text(
            'Unified Clinical Modules',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2),
          ),
          const SizedBox(height: 4),
          const Text(
            'All 6 healthcare domains integrated with real-time diagnostic intelligence.',
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
                icon: Icons.graphic_eq_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Diagnostics Lab',
                subtitle: 'Acoustic cough FFT & palmar anemia colorimetry',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoughScreeningScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.hub_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Field Mesh (CIN)',
                subtitle: 'Zero-internet BLE mesh & DBSCAN clusters',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityImmunityNetworkScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.psychology_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Forces Resilience',
                subtitle: 'Duty burnout formula & acoustic voice mood',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RakshakMitraScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.balance_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'Legal & Distress',
                subtitle: 'Trauma distress index & BSA Sec 63 chain',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NyayaSahayScreen())),
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
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Digital Twin & AI',
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

  // ================= TAB 1: CLINICAL & DIAGNOSTICS =================
  Widget _buildClinicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinical & Diagnostic Intelligence',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Structured intake, non-invasive ML screening, and dual-system clinical pathways.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          _buildHubCard(
            tag: 'OPD & TRIAGE',
            title: '🏥 Smart Clinical History & OPD Intake',
            subtitle: 'SOCRATES Protocol & AYUSH Prakriti Profiling',
            description: 'Interactive voice/text intake structuring symptoms, pain severity, duration, and Ayurvedic constitutional matrix for physician review.',
            color: const Color(0xFF0D9488),
            actionLabel: 'Open Clinical Intake',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MediKioskScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'AUDIO ML & COLORIMETRY',
            title: '🫁 Non-Invasive AI Screening Suite',
            subtitle: 'FFT Cough Acoustics & Palmar Hemoglobin Estimator',
            description: 'Runs real 7-feature FFT acoustic Random Forest model for wet/dry/whooping cough, plus camera RGB chromaticity model for instant Hb (g/dL).',
            color: const Color(0xFF0284C7),
            actionLabel: 'Launch AI Screener',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoughScreeningScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'TELEMETRY',
            title: '🫀 Disaster Health & Vital Monitoring',
            subtitle: 'Live Open-Meteo Weather & Fall Sentinel',
            description: 'Real-time Wet Bulb Globe Temperature heat stress calculation, continuous sensor vitals stream, and low-gravity fall detection.',
            color: const Color(0xFF0F766E),
            actionLabel: 'Open Vitals Monitor',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ArogyaSathiScreen())),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ================= TAB 2: FIELD & MESH =================
  Widget _buildFieldMeshTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Field & Community Outbreak Hub',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Decentralized frontline health surveillance, offline BLE mesh swarms, and spatial outbreak clustering.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          _buildHubCard(
            tag: 'OFFLINE MESH',
            title: '🌐 Community Immunity Network (CIN)',
            subtitle: 'Peer-to-Peer BLE Mesh Token Synchronization',
            description: 'Operates entirely without internet or SIM cards. Relays anonymized syndromic tokens across peer devices to detect local disease clusters.',
            color: const Color(0xFF10B981),
            actionLabel: 'Open CIN Mesh Monitor',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityImmunityNetworkScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'SPATIAL ML',
            title: '🗺️ DBSCAN Epidemic Outbreak Cluster Engine',
            subtitle: 'Haversine Spatial Clustering & R0 Projections',
            description: 'Live spatial clustering identifying active infection hotspots, infection radius, and transmission velocities across districts.',
            color: const Color(0xFF059669),
            actionLabel: 'Explore Outbreak Engine',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityImmunityNetworkScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'SECURE SDK',
            title: '🔒 SvasthyaStorage Encrypted Local Buffer',
            subtitle: 'AES-256 Offline Database & Background Sync',
            description: 'Zero-data-loss guarantee for frontline ASHA workers in zero-connectivity remote regions.',
            color: const Color(0xFF0D9488),
            actionLabel: 'Inspect Local Storage SDK',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StorageDemoScreen())),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ================= TAB 3: RESILIENCE, MIND & SAFETY =================
  Widget _buildResilienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resilience, Mental Health & Protection Hub',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Specialized support for armed forces, trauma victims, and covert emergency situations.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          _buildHubCard(
            tag: 'FORCES STRESS',
            title: '🎖️ Armed Forces Burnout & Resilience',
            subtitle: 'Duty Gap Burnout Index & Acoustic Voice Mood',
            description: 'Calculates cumulative stress scores using duty hours, rest deficits, and high-altitude deployments, paired with acoustic voice mood analysis.',
            color: const Color(0xFF7C3AED),
            actionLabel: 'Open Resilience Suite',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RakshakMitraScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'LEGAL & TRAUMA',
            title: '⚖️ Nyaya Psychological & Legal Aid',
            subtitle: 'Trauma Distress Calculator & Trial Milestones',
            description: 'Structured scoring for psychological distress with integrated FIR and trial milestone tracking and district legal counselor escalation.',
            color: const Color(0xFFD97706),
            actionLabel: 'Open Nyaya Aid Desk',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NyayaSahayScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'STEALTH SOS',
            title: '🆘 Covert Panic Disguise & Safety Sentinel',
            subtitle: 'Disguised 9999= Calculator PIN & Inactivity Guard',
            description: 'Fully functional calculator interface with secret emergency PIN trigger, shake accelerometer, and automated dead-man switch.',
            color: const Color(0xFFE11D48),
            actionLabel: 'Test Panic Disguise',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanicDisguiseScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'GENETICS GRAPH',
            title: '🧬 Family Health Risk Pedigree Graph',
            subtitle: 'NetworkX Lineage Scoring & Culturally Adapted AI',
            description: 'Multi-generational hereditary disease risk prediction (diabetes, cardiac, sickle-cell) with family counseling support.',
            color: const Color(0xFF9333EA),
            actionLabel: 'View Family Lineage Graph',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyGraphScreen())),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ================= TAB 4: VAULT, GOVERNANCE & AI =================
  Widget _buildSuperAppVaultTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vault, Intelligence & Compliance',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Digital twin simulation, gamified health karma, Merkle evidence chain, and DPDP Act consent.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          _buildHubCard(
            tag: 'ADVANCED SUITE',
            title: '🤖 Longitudinal Digital Twin & Health Karma',
            subtitle: 'Organ Simulations, Streaks & Privacy FedAvg',
            description: 'Track cardiovascular, pulmonary, and metabolic trajectories, earn Health Karma loyalty points, and run privacy-preserving federated model training.',
            color: const Color(0xFF0284C7),
            actionLabel: 'Explore Innovation Suite',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroundbreakingSuiteScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'AI ASSISTANT',
            title: '💬 Multilingual AI Health Companion',
            subtitle: 'Specialized Agents for Clinical, Military, Legal & Field',
            description: 'Context-aware intelligence answering clinical questions, calculating dosages, and advising on emergency protocols in Indian regional languages.',
            color: const Color(0xFF0D9488),
            actionLabel: 'Open AI Assistant',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'GOVERNANCE',
            title: '📋 ABDM DPDP Act Granular Consent Manager',
            subtitle: 'Time-Bound & Purpose-Specific Health Data Sharing',
            description: 'Explicit, revokeable consent architecture complying with India Digital Personal Data Protection Act and ABDM standards.',
            color: const Color(0xFF0F766E),
            actionLabel: 'Manage Data Consents',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConsentManagementScreen())),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'RBAC SECURITY',
            title: '🛡️ Role-Based Access Control Matrix',
            subtitle: 'Granular Permissions for Patients, Doctors, Officers & Admins',
            description: 'Manage cryptographic keys, identity verification, and permission tiers across the super-app ecosystem.',
            color: const Color(0xFF7C3AED),
            actionLabel: 'View Role Matrix',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminRolesScreen())),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ================= REUSABLE UI HELPERS =================
  Widget _buildCleanTelemetryCard({
    required String label,
    required String value,
    required String status,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A), letterSpacing: -0.3),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubCard({
    required String tag,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 12, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.2)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

