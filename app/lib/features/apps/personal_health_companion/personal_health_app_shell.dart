import 'package:flutter/material.dart';
import 'screens/vitals_anomaly_tab.dart';
import 'screens/disaster_environment_tab.dart';
import 'screens/dashboard_emergency_tab.dart';
import 'screens/patients_edge_ai_tab.dart';

class PersonalHealthAppShell extends StatefulWidget {
  const PersonalHealthAppShell({super.key});

  @override
  State<PersonalHealthAppShell> createState() => _PersonalHealthAppShellState();
}

class _PersonalHealthAppShellState extends State<PersonalHealthAppShell> {
  int _currentTabIndex = 0;

  final List<Widget> _tabs = const [
    VitalsAnomalyTab(),
    DisasterEnvironmentTab(),
    DashboardEmergencyTab(),
    PatientsEdgeAiTab(),
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
                Icon(Icons.health_and_safety, color: Color(0xFFDB2777), size: 20),
                SizedBox(width: 8),
                Text(
                  'Arogya Companion • Personal Health & Disaster AI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              'Continuous Vitals • On-Device Edge AI • Disaster Health Advisories • Fall & Emergency SOS',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),

      // App 4 Specific Bottom Navigation Bar (Light Theme)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (idx) => setState(() => _currentTabIndex = idx),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFDB2777),
          unselectedItemColor: const Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart),
              label: 'Vitals & AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_outlined),
              activeIcon: Icon(Icons.warning_amber),
              label: 'Disaster Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard & SOS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Patients & Edge AI',
            ),
          ],
        ),
      ),
    );
  }
}
