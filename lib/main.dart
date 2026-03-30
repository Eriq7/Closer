// main.dart
// App entry point. Initializes Supabase, sets up go_router with auth-aware
// redirect logic, and defines the route tree.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/email_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/setup_name_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

const _supabaseUrl = 'https://yaknivkhuzqyjrijqdss.supabase.co';
const _supabaseAnonKey =
    'sb_publishable_R9LQZz4Vjro1L1s6JXjQjQ_K9tLBQFQ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  await NotificationService.init();
  runApp(const CloserApp());
}

final _authScreens = {'/login', '/verify', '/setup-name'};

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuthed = session != null;
    final onAuth = _authScreens.contains(state.matchedLocation);

    if (!isAuthed && !onAuth) return '/login';
    if (isAuthed && state.matchedLocation == '/login') return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const EmailScreen()),
    GoRoute(
      path: '/verify',
      builder: (_, state) => OtpScreen(email: state.extra as String),
    ),
    GoRoute(path: '/setup-name', builder: (_, __) => const SetupNameScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
  ],
);

class CloserApp extends StatelessWidget {
  const CloserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Closer',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
