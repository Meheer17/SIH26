import 'package:flutter/material.dart';
import 'rakshak_mitra_screen.dart';
import '../creative/panic_disguise_screen.dart';

class WitnessShieldAppShell extends StatefulWidget {
  const WitnessShieldAppShell({super.key});

  @override
  State<WitnessShieldAppShell> createState() => _WitnessShieldAppShellState();
}

class _WitnessShieldAppShellState extends State<WitnessShieldAppShell> {
  int _currentTabIndex = 0;

  final List<Widget> _screens = const [
    RakshakMitraScreen(),
    PanicDisguiseScreen(),
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
          selectedItemColor: const Color(0xFFDB2777),
          unselectedItemColor: const Color(0xFF64748B),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'Rakshak Witness Shield',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.enhanced_encryption_outlined),
              activeIcon: Icon(Icons.enhanced_encryption),
              label: 'Stealth Camouflage Mode',
            ),
          ],
        ),
      ),
    );
  }
}
