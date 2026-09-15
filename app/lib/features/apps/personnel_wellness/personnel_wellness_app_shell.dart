import 'package:flutter/material.dart';
import 'screens/personnel_wellness_tab.dart';
import 'screens/commander_dashboard_tab.dart';
import 'screens/medical_welfare_tab.dart';
import 'screens/admin_governance_tab.dart';

class PersonnelWellnessAppShell extends StatefulWidget {
  const PersonnelWellnessAppShell({super.key});

  @override
  State<PersonnelWellnessAppShell> createState() => _PersonnelWellnessAppShellState();
}

class _PersonnelWellnessAppShellState extends State<PersonnelWellnessAppShell> {
  int _currentTabIndex = 0;

  final List<Widget> _tabs = const [
    PersonnelWellnessTab(),
    CommanderDashboardTab(),
    MedicalWelfareTab(),
    AdminGovernanceTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x0F0F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.shield, color: Color(0xFF0284C7), size: 20),
                SizedBox(width: 8),
                Text(
                  'Rakshak Mitra • Defense Personnel Wellness',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              'Military & Armed Forces Operational Readiness & Mental Health System',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),

      // App 2 Specific Bottom Navigation Bar (Light Theme)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (idx) => setState(() => _currentTabIndex = idx),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: const Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Personnel View',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.military_tech_outlined),
              activeIcon: Icon(Icons.military_tech),
              label: 'Commander View',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'Medical & Welfare',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin & Security',
            ),
          ],
        ),
      ),
    );
  }
}
