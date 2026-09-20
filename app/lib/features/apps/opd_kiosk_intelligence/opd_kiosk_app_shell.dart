import 'package:flutter/material.dart';
import 'screens/patient_kiosk_tab.dart';
import 'screens/all_patients_tab.dart';
import 'screens/physician_emr_tab.dart';
import 'screens/triage_nursing_tab.dart';
import 'screens/opd_operations_tab.dart';
import 'screens/system_admin_tab.dart';

class OpdKioskAppShell extends StatefulWidget {
  const OpdKioskAppShell({super.key});

  @override
  State<OpdKioskAppShell> createState() => _OpdKioskAppShellState();
}

class _OpdKioskAppShellState extends State<OpdKioskAppShell> {
  int _currentTabIndex = 0;

  late final List<Widget> _tabs = [
    const PatientKioskTab(),
    AllPatientsTab(
      onSwitchToEmr: () => setState(() => _currentTabIndex = 2),
      onSwitchToKiosk: () => setState(() => _currentTabIndex = 0),
    ),
    const PhysicianEmrTab(),
    const TriageNursingTab(),
    const OpdOperationsTab(),
    const SystemAdminTab(),
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
                Icon(Icons.local_hospital_rounded, color: Color(0xFF059669), size: 20),
                SizedBox(width: 8),
                Text(
                  'MediKiosk • AI Clinical History & OPD Intelligence',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            Text(
              'Pre-Consultation Intake • Multilingual Voice • Medical OCR • Physician Dual-EMR • ABDM FHIR',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),

      // App 3 Bottom Navigation Bar with All Stakeholder Roles & All Patients Hub
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
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: 'All Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'Physician EMR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency),
              label: 'Triage Nurse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Hospital Admin',
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
