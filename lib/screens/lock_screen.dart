import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/pin_pad.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const LockScreen({super.key, required this.onAuthenticated});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String _error = '';
  int _failCount = 0;
  int _lockSeconds = 0;
  bool _biometricAvailable = false;
  bool _biometricInProgress = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future _init() async {
    final fails = await AuthService.getFailCount();
    final lockSecs = await AuthService.getLockSecondsRemaining();
    final bioAvail = await AuthService.isBiometricAvailable();
    final bioEnabled = await AuthService.isBiometricEnabled();
    setState(() {
      _failCount = fails;
      _lockSeconds = lockSecs;
      _biometricAvailable = bioAvail && bioEnabled;
    });
    if (lockSecs > 0) _startLockTimer();
  }

  void _startLockTimer() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;
      final secs = await AuthService.getLockSecondsRemaining();
      setState(() => _lockSeconds = secs);
      if (secs > 0) _startLockTimer();
    });
  }

  Future _tryBiometric() async {
    if (_biometricInProgress || _lockSeconds > 0) return;
    setState(() => _biometricInProgress = true);
    final success = await AuthService.authenticateWithBiometric();
    if (!mounted) return;
    setState(() => _biometricInProgress = false);
    if (success) widget.onAuthenticated();
  }

  void _onKey(String digit) {
    if (_lockSeconds > 0) return;
    setState(() {
      _error = '';
      if (_pin.length < 4) {
        _pin += digit;
        if (_pin.length == 4) _verifyPin();
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = '';
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future _verifyPin() async {
    final correct = await AuthService.verifyPin(_pin);
    if (correct) {
      widget.onAuthenticated();
    } else {
      final fails = await AuthService.getFailCount();
      final lockSecs = await AuthService.getLockSecondsRemaining();
      setState(() {
        _pin = '';
        _failCount = fails;
        _lockSeconds = lockSecs;
        _error = lockSecs > 0
            ? 'Too many attempts! Wait $_lockSeconds seconds.'
            : 'Wrong PIN! ${3 - fails} attempts left.';
      });
      if (lockSecs > 0) _startLockTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.lock, color: Colors.white, size: 60),
                  const SizedBox(height: 20),
                  const Text('MyLife', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    _lockSeconds > 0 ? 'Locked for $_lockSeconds seconds' : 'Enter your PIN',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  PinDots(length: _pin.length),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(_error,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center),
                    ),
                  ],
                  const Spacer(),
                  if (_biometricAvailable) ...[
                    GestureDetector(
                      onTap: _biometricInProgress ? null : _tryBiometric,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            _biometricInProgress ? Icons.hourglass_empty : Icons.fingerprint,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _biometricInProgress ? 'Checking...' : 'Use Fingerprint',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Keypad(onKey: _onKey, onDelete: _onDelete, disabled: _lockSeconds > 0),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => _showResetDialog(),
                    child: const Text('Forgot PIN?', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text('Resetting PIN will NOT delete your data. You will need to set a new PIN.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDanger, foregroundColor: Colors.white),
            onPressed: () async {
              await AuthService.resetPin();
              if (mounted) Navigator.pop(context);
              setState(() {
                _pin = '';
                _failCount = 0;
                _lockSeconds = 0;
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
