import 'package:flutter/material.dart';
import 'screens/patient_kiosk_tab.dart';
import 'screens/physician_emr_tab.dart';
import 'screens/opd_operations_tab.dart';
import 'screens/system_admin_tab.dart';

class OpdKioskAppShell extends StatefulWidget {
  const OpdKioskAppShell({super.key});

  @override
  State<OpdKioskAppShell> createState() => _OpdKioskAppShellState();
}

class _OpdKioskAppShellState extends State<OpdKioskAppShell> {
  int _currentTabIndex = 0;

  final List<Widget> _tabs = const [
    PatientKioskTab(),
    PhysicianEmrTab(),
    OpdOperationsTab(),
    SystemAdminTab(),
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
                Icon(Icons.local_hospital, color: Color(0xFF059669), size: 20),
                SizedBox(width: 8),
                Text(
                  'Arogya Sathi • Patient Kiosk & OPD Health Intelligence',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              'Patient Intake Kiosk • Physician EMR • OPD Triage Operations • ABDM System Admin',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),

      // App 3 Specific Bottom Navigation Bar (Light Theme)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (idx) => setState(() => _currentTabIndex = idx),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF059669),
          unselectedItemColor: const Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.touch_app_outlined),
              activeIcon: Icon(Icons.touch_app),
              label: 'Patient Kiosk',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge),
              label: 'Physician EMR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined),
              activeIcon: Icon(Icons.local_hospital),
              label: 'OPD Operations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'System Admin',
            ),
          ],
        ),
      ),
    );
  }
}
