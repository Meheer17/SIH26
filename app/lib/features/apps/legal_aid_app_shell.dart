import 'package:flutter/material.dart';
import 'nyaya_sahay_screen.dart';
import 'sc_st_relief_screen.dart';

class LegalAidAppShell extends StatefulWidget {
  const LegalAidAppShell({super.key});

  @override
  State<LegalAidAppShell> createState() => _LegalAidAppShellState();
}

class _LegalAidAppShellState extends State<LegalAidAppShell> {
  int _currentTabIndex = 0;

  final List<Widget> _screens = [
    const NyayaSahayScreen(),
    const SCSTReliefScreen(),
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
          selectedItemColor: const Color(0xFF0284C7),
          unselectedItemColor: const Color(0xFF64748B),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.gavel_outlined),
              activeIcon: Icon(Icons.gavel),
              label: 'Nyaya Sahay Legal AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate),
              label: 'Statutory Relief Fund',
            ),
          ],
        ),
      ),
    );
  }
}
