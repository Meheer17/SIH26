import 'package:flutter/material.dart';
import 'master_home_screen.dart';
import 'mental_health_distress/mental_health_app_shell.dart';
import 'personnel_wellness/personnel_wellness_app_shell.dart';
import 'opd_kiosk_intelligence/opd_kiosk_app_shell.dart';
import 'personal_health_companion/personal_health_app_shell.dart';
import 'legal_aid_app_shell.dart';
import 'witness_shield_app_shell.dart';
import 'health_intelligence_app_shell.dart';

class ProblemStatementShell extends StatefulWidget {
  const ProblemStatementShell({super.key});

  @override
  State<ProblemStatementShell> createState() => _ProblemStatementShellState();
}

class _ProblemStatementShellState extends State<ProblemStatementShell> {
  int _selectedAppIndex = 0; // 0: Home / All Features Overview, 1: Mental Health, 2: Personnel Wellness, 3: OPD Kiosk, 4: Health Companion

  final List<Map<String, dynamic>> _problemApps = [
    {
      'index': 0,
      'title': 'Master Overview',
      'subtitle': 'Unified Platform Overview & Workspace Hub',
      'icon': Icons.grid_view_rounded,
      'color': const Color(0xFF0D9488),
      'badge': 'ALL MODULES',
    },
    {
      'index': 1,
      'title': 'Mental Health & Distress Support',
      'subtitle': 'NHAA 14566 • DDI Score • Acoustic Biomarkers • AI Check-In',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF7C3AED),
      'badge': 'DISTRESS CARE',
    },
    {
      'index': 2,
      'title': 'Personnel Defence & Wellness',
      'subtitle': 'Sentinel View • Commander HRMS • Sentinels & Field Security',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFF0284C7),
      'badge': 'DEFENCE',
    },
    {
      'index': 3,
      'title': 'OPD Kiosk & Clinical Health',
      'subtitle': 'Patient Intake Kiosk • Physician EMR • Dual Prescription',
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFF059669),
      'badge': 'CLINICAL EMR',
    },
    {
      'index': 4,
      'title': 'Personal Health & Field Companion',
      'subtitle': 'Continuous Vitals • ASHA Copilot • Heat Alerts • Digital Twin',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFFDB2777),
      'badge': 'FIELD CARE',
    },
  ];

  Widget _buildSelectedScreen() {
    switch (_selectedAppIndex) {
      case 1:
        return const MentalHealthAppShell();
      case 2:
        return const PersonnelWellnessAppShell();
      case 3:
        return const OpdKioskAppShell();
      case 4:
        return const PersonalHealthAppShell();
      case 0:
      default:
        return MasterHomeScreen(
          onSelectApp: (index) {
            setState(() => _selectedAppIndex = index);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x0F0F172A),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Text(
                'NHAA 14566',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _problemApps[_selectedAppIndex]['title'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedAppIndex != 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  backgroundColor: const Color(0xFFEEF2FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.home_outlined, size: 16),
                label: const Text('ALL FEATURES HOME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() => _selectedAppIndex = 0),
              ),
            ),
        ],
      ),
      drawer: _buildLeftDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildSidebarRail(),
          Expanded(child: _buildSelectedScreen()),
        ],
      ),
    );
  }

  Widget _buildLeftDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'SvasthyaSetu',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Unified Health & Legal System',
                    style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _problemApps.map((app) {
                  final isSelected = _selectedAppIndex == app['index'];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? (app['color'] as Color).withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? app['color'] as Color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: (app['color'] as Color).withValues(alpha: 0.15),
                        child: Icon(app['icon'] as IconData, color: app['color'] as Color, size: 18),
                      ),
                      title: Text(
                        app['title'] as String,
                        style: TextStyle(
                          color: isSelected ? app['color'] as Color : const Color(0xFF0F172A),
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        app['subtitle'] as String,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (app['color'] as Color).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          app['badge'] as String,
                          style: TextStyle(color: app['color'] as Color, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedAppIndex = app['index'] as int);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarRail() {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'PROBLEM STATEMENTS',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Click to switch mobile app context',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _problemApps.map((app) {
                final isSelected = _selectedAppIndex == app['index'];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? (app['color'] as Color).withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? app['color'] as Color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(app['icon'] as IconData, color: app['color'] as Color, size: 20),
                    title: Text(
                      app['title'] as String,
                      style: TextStyle(
                        color: isSelected ? app['color'] as Color : const Color(0xFF0F172A),
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      app['subtitle'] as String,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      setState(() => _selectedAppIndex = app['index'] as int);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
