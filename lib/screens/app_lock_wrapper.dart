import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'set_pin_screen.dart';
import 'lock_screen.dart';
import 'main_screen.dart';

class AppLockWrapper extends StatefulWidget {
  const AppLockWrapper({super.key});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _pinSet = false;
  bool _loading = true;
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only re-lock when the app was truly backgrounded (paused), not when it
    // briefly loses focus for an in-app system dialog like the biometric
    // prompt (which cycles resumed -> inactive -> resumed without pausing).
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed) {
      if (_wasPaused && _pinSet) {
        setState(() => _isAuthenticated = false);
      }
      _wasPaused = false;
    }
  }

  Future _checkPin() async {
    try {
      await DatabaseService.instance.database;
      await DatabaseService.instance.carryForwardTasks();
      await NotificationService.instance.init();
      await NotificationService.instance.scheduleAll();
    } catch (e, st) {
      debugPrint('Startup bootstrap failed: $e\n$st');
    }

    final set = await AuthService.isPinSet();
    if (!mounted) return;
    setState(() {
      _pinSet = set;
      _loading = false;
      if (!set) _isAuthenticated = true;
    });
  }

  void _onAuthenticated() {
    setState(() => _isAuthenticated = true);
  }

  void _onPinCreated() {
    setState(() {
      _pinSet = true;
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kPrimary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (!_pinSet) return SetPinScreen(onPinCreated: _onPinCreated);
    if (!_isAuthenticated) return LockScreen(onAuthenticated: _onAuthenticated);
    return const MainScreen();
  }
}
