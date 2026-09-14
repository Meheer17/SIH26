import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/role_dashboard_screen.dart';
import 'features/chat/ai_chat_screen.dart';
import 'features/storage_demo/storage_demo_screen.dart';
import 'features/sos_demo/sos_demo_screen.dart';
import 'features/creative/cin_screen.dart';
import 'features/creative/cough_screening_screen.dart';
import 'features/creative/panic_disguise_screen.dart';
import 'features/creative/family_graph_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SvasthyaSetu Unified App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/dashboard',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/chat': (context) => const AiChatScreen(),
        '/dashboard': (context) => const RoleDashboardScreen(),
        '/storage-demo': (context) => const StorageDemoScreen(),
        '/sos-demo': (context) => const SosDemoScreen(),
        '/cin': (context) => const CommunityImmunityNetworkScreen(),
        '/cough-screening': (context) => const CoughScreeningScreen(),
        '/panic-disguise': (context) => const PanicDisguiseScreen(),
        '/family-graph': (context) => const FamilyGraphScreen(),
      },
    );
  }
}
