import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screens.dart';
import 'home_screens.dart';
import 'services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce));
  runApp(const GameStackApp());
}

class GameStackApp extends StatelessWidget {
  const GameStackApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(title: 'Game Stack',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scrollBehavior: const _NoGlow(),
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
        home: const AuthGate(),
      );
}

/// Removes the coloured Android overscroll glow (the green line at list edges).
class _NoGlow extends MaterialScrollBehavior {
  const _NoGlow();
  @override
  Widget buildOverscrollIndicator(BuildContext c, Widget child, ScrollableDetails d) => child;
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext c) => StreamBuilder<AuthState>(
        stream: sb.auth.onAuthStateChange,
        builder: (c, __) {
          if (sb.auth.currentSession == null) {
            store.clear();
            return const WelcomeScreen();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (c.mounted) Navigator.of(c).popUntil((r) => r.isFirst);
          });
          return const Shell();
        },
      );
}
