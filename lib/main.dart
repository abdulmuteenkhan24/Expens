import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'providers/auth_state.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const ExpensApp());
}

class ExpensApp extends StatefulWidget {
  const ExpensApp({super.key});

  @override
  State<ExpensApp> createState() => _ExpensAppState();
}

class _ExpensAppState extends State<ExpensApp> with WidgetsBindingObserver {
  final AppState _appState = AppState();
  final AuthState _authState = AuthState();
  DateTime? _pausedAt;

  /// Re-lock only when PIN is enabled and app was backgrounded this long.
  static const _lockAfter = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appState.load();
    // Auth is optional — failures never block the app.
    _authState.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appState.dispose();
    _authState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only re-lock if the user enabled PIN in Settings.
    if (!_authState.pinEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      _pausedAt = null;
      if (paused != null &&
          DateTime.now().difference(paused) >= _lockAfter) {
        _authState.lock();
      }
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _authState.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appState),
        ChangeNotifierProvider.value(value: _authState),
      ],
      child: Consumer2<AppState, AuthState>(
        builder: (context, app, auth, _) {
          // Don't wait on auth — PIN is optional and off by default.
          final ready = app.isLoaded;
          final showLock = ready && auth.needsLock;

          return MaterialApp(
            title: 'Expens',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: app.themeMode,
            home: !ready
                ? const _SplashBody()
                : showLock
                    ? const LockScreen()
                    : const AppBootstrap(),
          );
        },
      ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 88, glow: true),
            const SizedBox(height: 16),
            Text(
              'Expens',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your money, under control',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
