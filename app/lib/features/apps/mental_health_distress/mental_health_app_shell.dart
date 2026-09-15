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
        elevation: 1,
        shadowColor: const Color(0x0F0F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.psychology, color: Color(0xFF4F46E5), size: 20),
                SizedBox(width: 8),
                Text(
                  'NHAA 14566 Distress System',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              user != null ? 'Role: ${user.primaryRole} (${user.fullName})' : 'Role: Victim / Witness Context',
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Color(0xFF4F46E5)),
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

      // App 1 Specific Bottom Navigation Bar (Light Theme)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (idx) => setState(() => _currentTabIndex = idx),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4F46E5),
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
