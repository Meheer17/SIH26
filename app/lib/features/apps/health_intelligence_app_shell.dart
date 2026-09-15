import 'package:flutter/material.dart';
import 'arogya_sathi_screen.dart';
import 'medikiosk_screen.dart';

class HealthIntelligenceAppShell extends StatefulWidget {
  const HealthIntelligenceAppShell({super.key});

  @override
  State<HealthIntelligenceAppShell> createState() => _HealthIntelligenceAppShellState();
}

class _HealthIntelligenceAppShellState extends State<HealthIntelligenceAppShell> {
  int _currentTabIndex = 0;

  final List<Widget> _screens = [
    const ArogyaSathiScreen(),
    const MediKioskScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _screens,
      ),
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
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Arogya Sathi Health Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined),
              activeIcon: Icon(Icons.local_hospital),
              label: 'MediKiosk Tele-Psychiatry',
            ),
          ],
        ),
      ),
    );
  }
}
