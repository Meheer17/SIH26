import 'package:flutter/material.dart';
import 'screens/vitals_companion_tab.dart';
import 'screens/ai_anomalies_tab.dart';
import 'screens/disaster_sentinel_tab.dart';
import 'screens/emergency_care_tab.dart';
import 'screens/meds_telemedicine_tab.dart';
import 'screens/caregiver_provider_tab.dart';
import '../../twin/digital_twin_screen.dart';

class PersonalHealthAppShell extends StatefulWidget {
  const PersonalHealthAppShell({super.key});

  @override
  State<PersonalHealthAppShell> createState() => _PersonalHealthAppShellState();
}

class _PersonalHealthAppShellState extends State<PersonalHealthAppShell> {
  int _currentTabIndex = 0;

  final List<Widget> _tabs = const [
    VitalsCompanionTab(),
    AiAnomaliesTab(),
    DisasterSentinelTab(),
    EmergencyCareTab(),
    MedsTelemedicineTab(),
    CaregiverProviderTab(),
  ];

  final List<String> _tabTitles = const [
    'Continuous Vitals & Risk Score',
    'Edge AI Anomaly Detection Engine',
    'Disaster & Environmental Sentinel',
    'Emergency SOS & Lockscreen Medical ID',
    'Medications, Tele-Sanjeevani & Records',
    'Caregiver Portal, ASHA Copilot & ABDM',
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
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Color(0xFFDB2777), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Personal Health Companion (PHC)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7F3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'EDGE AI',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFDB2777)),
                  ),
                ),
              ],
            ),
            Text(
              _tabTitles[_currentTabIndex],
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '3D Patient Digital Twin',
            icon: const Icon(Icons.hub_rounded, color: Color(0xFFDB2777)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DigitalTwinScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),

      // Bottom Navigation Bar with All PHC Modules
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
          selectedFontSize: 10,
          unselectedFontSize: 9,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart),
              label: 'Vitals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology),
              label: 'AI Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined),
              activeIcon: Icon(Icons.wb_sunny),
              label: 'Disaster',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency),
              label: 'SOS & ID',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication_outlined),
              activeIcon: Icon(Icons.medication),
              label: 'Rx & Tele',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom_outlined),
              activeIcon: Icon(Icons.family_restroom),
              label: 'Caregiver',
            ),
          ],
        ),
      ),
    );
  }
}
