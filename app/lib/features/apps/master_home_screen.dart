import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/api/api_client.dart';
import '../creative/voice_stress_studio_screen.dart';
import '../creative/panic_disguise_screen.dart';

class MasterHomeScreen extends StatefulWidget {
  final Function(int) onSelectApp;

  const MasterHomeScreen({
    super.key,
    required this.onSelectApp,
  });

  @override
  State<MasterHomeScreen> createState() => _MasterHomeScreenState();
}

class _MasterHomeScreenState extends State<MasterHomeScreen> {
  final _authService = AuthService();
  final _apiClient = ApiClient();
  bool _backendConnected = true;

  final List<Map<String, String>> _demoPersonas = const [
    {
      'role': 'Victim/Complainant',
      'email': 'victim_scst@district.gov.in',
      'label': '⚖️ SC/ST Victim (NHAA 14566)',
      'color': '#7C3AED'
    },
    {
      'role': 'District Counselor',
      'email': 'legal_officer@district.gov.in',
      'label': '👨‍⚕️ Clinical Psychologist / Counselor',
      'color': '#059669'
    },
    {
      'role': 'District Magistrate/SP',
      'email': 'dm_varanasi@up.gov.in',
      'label': '🛡️ District Magistrate / Police SP',
      'color': '#D97706'
    },
    {
      'role': 'State Nodal Officer',
      'email': 'nodal_state@up.gov.in',
      'label': '🏛️ State Nodal Authority',
      'color': '#2563EB'
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
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

  Future<void> _switchPersona(String email) async {
    try {
      await _authService.login(emailOrPhone: email, password: 'demo123456');
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            content: Text(
              '✅ Active Persona: ${_authService.currentUser?.fullName} (${_authService.currentUser?.primaryRole})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Persona switch error: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PanicDisguiseScreen()),
          );
        },
        backgroundColor: const Color(0xFFE11D48),
        elevation: 6,
        tooltip: 'Emergency SOS Dial',
        child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 24),
      ),
      body: CustomScrollView(
        slivers: [
          // App Bar Header - MindBridge Figma Design
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning 👋',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    user != null ? user.fullName : 'SvasthyaSetu Hub',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF0D9488), size: 22),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'SvasthyaSetu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D9488),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _backendConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _backendConnected ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 3.5,
                                  backgroundColor: _backendConnected ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _backendConnected ? 'API Connected' : 'Edge Standalone',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _backendConnected ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 24),
                                onPressed: () {},
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE11D48),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Role & Switcher Banner
                  _buildPersonaSection(user),
                  const SizedBox(height: 16),

                  // Quick Action Banner
                  _buildQuickActionBanner(context),
                  const SizedBox(height: 20),

                  // Section Title: Workspaces Overview
                  const Text(
                    'HEALTH & LEGAL WORKSPACES',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4 Integrated Workspaces Cards Grid
                  _buildProblemStatementCard(
                    context: context,
                    appIndex: 1,
                    title: 'Mental Health & Distress Support',
                    subtitle: 'NHAA 14566 • Acoustic Biomarkers • DDI Score • AI Check-In',
                    description:
                        'Continuous multimodal distress prediction, e-Courts sync, dialect IVRS, zero-knowledge privacy, and SC/ST PoA assistance.',
                    icon: Icons.psychology_rounded,
                    gradientColors: [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                    badgeText: 'DISTRESS CARE',
                    badgeColor: const Color(0xFF0D9488),
                    features: [
                      'Acoustic Vocal Biomarker Engine (f₀ tremor)',
                      'Dynamic Distress Index (DDI 0-100)',
                      'SHAP/LIME Explainable AI Case Inspector',
                      'Stealth "Disguised" Calculator UI & Duress PIN',
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildProblemStatementCard(
                    context: context,
                    appIndex: 2,
                    title: 'Personnel Stress & Welfare (Raksha Setu)',
                    subtitle: 'MHA Track • Validated Assessments • Sahayak AI • Commander Heatmap',
                    description:
                        'AI-powered stress & welfare monitoring for CAPF & Armed Forces with DPDP Act 2023 consent, biometric wearables, and confidential counseling.',
                    icon: Icons.shield_rounded,
                    gradientColors: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                    badgeText: 'RAKSHA SETU',
                    badgeColor: const Color(0xFF0284C7),
                    features: [
                      'Clinical Assessments (PHQ-9, GAD-7, PSS-10, MBI)',
                      'Sahayak Multilingual AI Companion & 14416 Helpline',
                      'Commander Heatmap & 30-Day Fatigue Forecast',
                      'Garmin Tactical Biometrics & Sleep Debt Sync',
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildProblemStatementCard(
                    context: context,
                    appIndex: 3,
                    title: 'OPD Kiosk & Clinical Health',
                    subtitle: 'Patient Intake Kiosk • Physician EMR • Dual Prescription',
                    description:
                        'Automated patient intake, parallel Allopathic + AYUSH dual prescriptions, OPD operations, and clinical triage.',
                    icon: Icons.local_hospital_rounded,
                    gradientColors: [const Color(0xFF059669), const Color(0xFF047857)],
                    badgeText: 'CLINICAL EMR',
                    badgeColor: const Color(0xFF059669),
                    features: [
                      'Allopathic + AYUSH Parallel Prescriptions',
                      'OPD Patient Self-Service Kiosk Intake',
                      'Physician EMR Triage & Symptom Analyzer',
                      'ABDM & HL7 FHIR Interoperability',
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildProblemStatementCard(
                    context: context,
                    appIndex: 4,
                    title: 'Personal Health & Field Companion',
                    subtitle: 'Vitals Monitoring • ASHA Copilot • Heat Alerts • Digital Twin',
                    description:
                        'Continuous vitals tracking, ASHA worker rural triage, 3D organ health twin, and environmental heat advisories.',
                    icon: Icons.health_and_safety_rounded,
                    gradientColors: [const Color(0xFFDB2777), const Color(0xFFBE185D)],
                    badgeText: 'FIELD CARE',
                    badgeColor: const Color(0xFFDB2777),
                    features: [
                      '3D Longitudinal Digital Twin Organ Scores',
                      'ASHA Worker Rural Maternal Triage',
                      'Continuous Vitals & Fall Detection SOS',
                      'Real-time WBGT Heat Stress Advisories',
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Specification Section
                  _buildSystemSpecificationSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaSection(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, color: Color(0xFF4F46E5), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user != null
                      ? 'Logged in as: ${user.fullName} (${user.primaryRole})'
                      : 'Not Logged In (Using Guest Context)',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick Switch Persona Role:',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _demoPersonas.map((p) {
                final isSelected = user?.emailOrPhone == p['email'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    selectedColor: const Color(0xFFEEF2FF),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    label: Text(
                      p['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onSelected: (_) => _switchPersona(p['email']!),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'AI System Utilities & Emergency Tools',
                style: TextStyle(
                  color: Color(0xFF1E1B4B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.graphic_eq, size: 18),
                  label: const Text('Emotions & Stress AI', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VoiceStressStudioScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE11D48),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.enhanced_encryption, size: 18),
                  label: const Text('Stealth Disguise', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PanicDisguiseScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProblemStatementCard({
    required BuildContext context,
    required int appIndex,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required String badgeText,
    required Color badgeColor,
    required List<String> features,
  }) {
    final primaryColor = gradientColors.first;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: features.map((f) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: primaryColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        f,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => widget.onSelectApp(appIndex),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Open Workspace',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSpecificationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.view_headline, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'SYSTEM SPECIFICATION MATRIX OVERVIEW',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSpecTile(
            'Adaptive Interaction & Ingestion',
            'Dialect-aware voice IVRS 14566, acoustic prosody stress markers, micro-checkin bot with empathetic prompts, disguised calculator UI.',
            Icons.record_voice_over,
            const Color(0xFF7C3AED),
          ),
          _buildSpecTile(
            'Multimodal Distress Prediction',
            'Acoustic Vocal Biomarker engine (f₀ tremor analysis), contextual semantic drift detection, and behavioral passive sensing.',
            Icons.query_stats,
            const Color(0xFF0284C7),
          ),
          _buildSpecTile(
            'Predictive Risk & Triggers',
            'Chronological e-Courts / CCTNS milestone predictor, Dynamic Distress Index (DDI 0-100), and sub-radar witness retaliation alarm.',
            Icons.timeline,
            const Color(0xFFDB2777),
          ),
          _buildSpecTile(
            'Automated Intervention & Dispatch',
            'Role-based SLA alerting, prescriptive statutory relief matcher under SC/ST (PoA) Act, one-touch SOS witness beacon.',
            Icons.notification_important,
            const Color(0xFFD97706),
          ),
          _buildSpecTile(
            'Administrative Intelligence & XAI',
            'Multi-tiered state/district heatmap dashboards, SHAP/LIME Explainable AI case inspector, and relief disbursement tracker.',
            Icons.analytics,
            const Color(0xFF059669),
          ),
          _buildSpecTile(
            'Ethics, Privacy & Trust',
            'Zero-knowledge consent architecture isolating therapy logs from court subpoenas, and trauma-informed safeguard filters.',
            Icons.lock_person,
            const Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile(String title, String desc, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
