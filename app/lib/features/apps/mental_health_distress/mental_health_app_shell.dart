import 'package:flutter/material.dart';
import 'auth/mental_health_auth_screen.dart';
import 'screens/checkin_stealth_tab.dart';
import 'screens/ddi_analytics_tab.dart';
import 'screens/welfare_intervention_tab.dart';
import 'screens/admin_xai_tab.dart';
import '../../../../core/auth/auth_service.dart';

class MentalHealthAppShell extends StatefulWidget {
  const MentalHealthAppShell({super.key});

  @override
  State<MentalHealthAppShell> createState() => _MentalHealthAppShellState();
}

class _MentalHealthAppShellState extends State<MentalHealthAppShell> {
  final _authService = AuthService();
  int _currentTabIndex = 0;

  final List<Widget> _tabs = const [
    CheckInStealthTab(),
    DdiAnalyticsTab(),
    WelfareInterventionTab(),
    AdminXaiTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.psychology_rounded, color: Color(0xFF0D9488), size: 22),
                SizedBox(width: 8),
                Text(
                  'Mental Health & Distress Support',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.4),
                ),
              ],
            ),
            Text(
              user != null ? 'Active Role: ${user.primaryRole} (${user.fullName})' : 'NHAA 14566 Distress Support',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Color(0xFF0D9488)),
            tooltip: 'Switch Role / Login',
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
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (idx) => setState(() => _currentTabIndex = idx),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0D9488),
          unselectedItemColor: const Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_none),
              activeIcon: Icon(Icons.mic),
              label: 'Check-In & Stealth',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'DDI Risk AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety_outlined),
              activeIcon: Icon(Icons.health_and_safety),
              label: 'Welfare Relief',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin & XAI',
            ),
          ],
        ),
      ),
    );
  }
}
