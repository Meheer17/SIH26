import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/api/api_client.dart';
import 'screens/victim_view_screen.dart';
import 'screens/counsellor_view_screen.dart';
import 'screens/district_magistrate_view_screen.dart';
import 'screens/state_nodal_view_screen.dart';
import 'screens/national_admin_view_screen.dart';
import 'auth/mental_health_auth_screen.dart';

class MentalHealthAppShell extends StatefulWidget {
  const MentalHealthAppShell({super.key});

  @override
  State<MentalHealthAppShell> createState() => _MentalHealthAppShellState();
}

class _MentalHealthAppShellState extends State<MentalHealthAppShell> {
  final _authService = AuthService();
  final _apiClient = ApiClient();

  // Active Role State (0: Victim, 1: Counsellor, 2: District Magistrate / SP, 3: State Nodal, 4: National Admin)
  int _activeRoleIndex = 0;
  bool _backendConnected = true;

  final List<Map<String, dynamic>> _roles = [
    {
      'index': 0,
      'roleKey': 'VICTIM',
      'label': 'Victim / Complainant',
      'fullTitle': '⚖️ SC/ST Victim (NHAA 14566)',
      'email': 'victim_scst@district.gov.in',
      'subtitle': 'Acoustic Voice Check-In • AI Companion • Relief Tracker • SOS Beacon',
      'color': const Color(0xFF7C3AED),
      'badge': 'BENEFICIARY',
      'icon': Icons.person_pin,
    },
    {
      'index': 1,
      'roleKey': 'COUNSELOR',
      'label': 'Clinical Psychologist / Counsellor',
      'fullTitle': '👨‍⚕️ Clinical Psychologist / Counsellor',
      'email': 'legal_officer@district.gov.in',
      'subtitle': 'Caseload Triage • Real-Time Alerts • SHAP XAI • Clinical Dispatch',
      'color': const Color(0xFF059669),
      'badge': 'DMHP / NIMHANS',
      'icon': Icons.psychology,
    },
    {
      'index': 2,
      'roleKey': 'DISTRICT_MAGISTRATE',
      'label': 'District Magistrate & Police SP',
      'fullTitle': '🛡️ District Magistrate & Police SP',
      'email': 'dm_varanasi@up.gov.in',
      'subtitle': 'District Heatmap • Fast-Track Relief Approvals • Witness Escorts',
      'color': const Color(0xFFD97706),
      'badge': 'DISTRICT CELL',
      'icon': Icons.security,
    },
    {
      'index': 3,
      'roleKey': 'STATE_NODAL_OFFICER',
      'label': 'State SC/ST Welfare Officer',
      'fullTitle': '🏛️ State SC/ST Welfare Officer',
      'email': 'nodal_state@up.gov.in',
      'subtitle': '75 Districts Comparative League • Atrocity Trends • Resource Rebalance',
      'color': const Color(0xFF2563EB),
      'badge': 'STATE SJD',
      'icon': Icons.account_balance,
    },
    {
      'index': 4,
      'roleKey': 'NATIONAL_ADMINISTRATOR',
      'label': 'National Administrator (Ministry / NCSC)',
      'fullTitle': '🇮🇳 National Administrator (Ministry / NCSC)',
      'email': 'national_admin@gov.in',
      'subtitle': 'Pan-India Overview • Parliamentary Reporting • DPDP Act Governance',
      'color': const Color(0xFF4F46E5),
      'badge': 'CENTRAL APEX',
      'icon': Icons.hub_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkBackendAndSync();
  }

  Future<void> _checkBackendAndSync() async {
    try {
      final res = await _apiClient.get('health');
      if (mounted) {
        setState(() {
          _backendConnected = res is Map && res['status'] == 'healthy';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _backendConnected = false);
    }
  }

  Future<void> _switchRole(int index) async {
    final target = _roles[index];
    setState(() => _activeRoleIndex = index);

    try {
      await _authService.login(
        emailOrPhone: target['email'] as String,
        password: 'demo123456',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: target['color'] as Color,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                Icon(target['icon'] as IconData, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active Role: ${target["fullTitle"]} (${_authService.currentUser?.fullName})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      // Offline fallback
    }
  }

  void _showRoleSelectorDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Select Operational Role / Persona',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Syncs live data with role permissions & backend DB',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ...List.generate(_roles.length, (idx) {
                final r = _roles[idx];
                final isSelected = _activeRoleIndex == idx;
                final color = r['color'] as Color;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(r['icon'] as IconData, color: color, size: 20),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            r['fullTitle'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                              color: isSelected ? color : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r['badge'] as String,
                            style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3.0),
                      child: Text(
                        r['subtitle'] as String,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: color, size: 20)
                        : const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      _switchRole(idx);
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRoleScreen() {
    switch (_activeRoleIndex) {
      case 0:
        return const VictimViewScreen();
      case 1:
        return const CounsellorViewScreen();
      case 2:
        return const DistrictMagistrateViewScreen();
      case 3:
        return const StateNodalViewScreen();
      case 4:
        return const NationalAdminViewScreen();
      default:
        return const VictimViewScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = _roles[_activeRoleIndex];
    final activeColor = activeRole['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: InkWell(
            onTap: _showRoleSelectorDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: activeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(activeRole['icon'] as IconData, color: activeColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activeRole['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: activeColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: activeColor, size: 18),
                ],
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Nyaya-Manas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
            ),
            Text(
              'SC/ST (PoA) Act AI Distress Surveillance',
              style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _backendConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _backendConnected ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 3,
                  backgroundColor: _backendConnected ? const Color(0xFF15803D) : const Color(0xFFB45309),
                ),
                const SizedBox(width: 4),
                Text(
                  _backendConnected ? 'DB Synced' : 'Offline Edge',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _backendConnected ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF475569)),
            tooltip: 'Quick Switch Role',
            onPressed: _showRoleSelectorDialog,
          ),
          IconButton(
            icon: const Icon(Icons.login, color: Color(0xFF475569)),
            tooltip: 'Direct Login',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MentalHealthAuthScreen(
                    onLoginSuccess: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildActiveRoleScreen(),
    );
  }
}
