import 'package:flutter/material.dart';
import 'services/raksha_setu_service.dart';
import 'screens/personnel_home_tab.dart';
import 'screens/assessment_hub_tab.dart';
import 'screens/wellness_tracker_tab.dart';
import 'screens/sahayak_chat_tab.dart';
import 'screens/tactical_resources_tab.dart';
import 'screens/gamification_tab.dart';
import 'screens/counseling_support_tab.dart';
import 'screens/biometric_wearables_tab.dart';
import 'screens/family_connect_tab.dart';
import 'screens/commander_dashboard_tab.dart';
import 'screens/admin_governance_tab.dart';

class PersonnelWellnessAppShell extends StatefulWidget {
  const PersonnelWellnessAppShell({super.key});

  @override
  State<PersonnelWellnessAppShell> createState() => _PersonnelWellnessAppShellState();
}

class _PersonnelWellnessAppShellState extends State<PersonnelWellnessAppShell> {
  final RakshaSetuService _service = RakshaSetuService();

  int _currentTabIndex = 0;
  String _selectedForce = 'CRPF';
  bool _isCommanderMode = false;

  final List<String> _forces = [
    'CRPF',
    'BSF',
    'CISF',
    'ITBP',
    'SSB',
    'Indian Army',
    'Indian Navy',
    'Indian Air Force'
  ];

  void _triggerEmergencySos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_share, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'EMERGENCY DISTRESS SOS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Silent distress alert dispatched with real-time GPS coordinates to Base Ops Room and Unit Medical Officer.',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Text(
                      'GPS: 34.0837° N, 74.7973° E (Kupwara Sector)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tele-MANAS Armed Forces Helpline: 14416',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _service.triggerSos(
                      latitude: 34.0837,
                      longitude: 74.7973,
                      locationName: 'Kupwara Forward Outpost',
                      note: 'Soldier activated mobile emergency SOS beacon',
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SOS BEACON CONFIRMED! Unit Medical Officer & Commander alerted.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('CONFIRM EMERGENCY BEACON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel / False Alarm', style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return PersonnelHomeTab(
          onNavigate: _navigateToTab,
          onTriggerSos: _triggerEmergencySos,
        );
      case 1:
        return AssessmentHubTab(
          onTriggerSos: _triggerEmergencySos,
        );
      case 2:
        return const WellnessTrackerTab();
      case 3:
        return SahayakChatTab(
          onTriggerSos: _triggerEmergencySos,
        );
      case 4:
        return const TacticalResourcesTab();
      case 5:
        return const GamificationTab();
      case 6:
        return CounselingSupportTab(
          onTriggerSos: _triggerEmergencySos,
        );
      case 7:
        return const BiometricWearablesTab();
      case 8:
        return const FamilyConnectTab();
      case 9:
        return const CommanderDashboardTab();
      case 10:
        return const AdminGovernanceTab();
      default:
        return PersonnelHomeTab(
          onNavigate: _navigateToTab,
          onTriggerSos: _triggerEmergencySos,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x0F0F172A),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Color(0xFF0284C7), size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Raksha Setu • रक्षा सेतु',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'AI Personnel Stress & Welfare System • $_selectedForce',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Force Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedForce,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, size: 18),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              items: _forces.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedForce = val);
              },
            ),
          ),
          const SizedBox(width: 6),

          // Emergency SOS Quick Button
          IconButton(
            icon: const Icon(Icons.emergency_share, color: Colors.red),
            tooltip: 'Emergency SOS',
            onPressed: _triggerEmergencySos,
          ),

          // More Modules Drawer Button
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.apps_rounded, color: Color(0xFF0284C7)),
              tooltip: 'All 11 Modules',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // End Drawer with All 11 Modules
      endDrawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield, color: Color(0xFF38BDF8), size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Raksha Setu Hub',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Armed Forces Welfare & Resilience Platform • $_selectedForce',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            _buildDrawerTile(Icons.dashboard_outlined, 'Home Dashboard (होम)', 0),
            _buildDrawerTile(Icons.assignment_turned_in_outlined, 'Clinical Assessments (PHQ-9 / GAD-7)', 1),
            _buildDrawerTile(Icons.mood_outlined, 'Mood, Sleep & Voice Journal (ट्रैकर)', 2),
            _buildDrawerTile(Icons.smart_toy_outlined, 'AI Counselor "Sahayak" (सहायक AI)', 3),
            _buildDrawerTile(Icons.air_rounded, 'Tactical 4-4-4-4 Breathing & Yoga', 4),
            _buildDrawerTile(Icons.military_tech_outlined, 'Points, Badges & Leaderboard', 5),
            _buildDrawerTile(Icons.medical_services_outlined, 'Psychologist & Peer Buddy Support', 6),
            _buildDrawerTile(Icons.watch_outlined, 'Smartwatch & Biometric Sync', 7),
            _buildDrawerTile(Icons.family_restroom_outlined, 'Family Connect & Welfare Grants', 8),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'COMMAND & GOVERNANCE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
              ),
            ),
            _buildDrawerTile(Icons.security, 'Unit Commander & Heatmap Console', 9),
            _buildDrawerTile(Icons.admin_panel_settings_outlined, 'DPDP Act 2023 Consent & Profile', 10),
          ],
        ),
      ),

      body: _buildBody(),

      // Persistent Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex < 5 ? _currentTabIndex : 0,
          onTap: (idx) {
            setState(() => _currentTabIndex = idx);
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: const Color(0xFF64748B),
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: 'Assess',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy_outlined),
              activeIcon: Icon(Icons.smart_toy),
              label: 'Sahayak',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.air_rounded),
              activeIcon: Icon(Icons.air),
              label: 'Breathe',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, int targetTab) {
    final isSelected = _currentTabIndex == targetTab;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF475569), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        setState(() => _currentTabIndex = targetTab);
      },
    );
  }
}
