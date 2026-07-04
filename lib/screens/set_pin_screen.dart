import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../widgets/pin_pad.dart';

class SetPinScreen extends StatefulWidget {
  final VoidCallback onPinCreated;
  const SetPinScreen({super.key, required this.onPinCreated});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String _error = '';

  void _onKey(String digit) {
    setState(() {
      _error = '';
      if (!_confirming) {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 300), () {
              setState(() => _confirming = true);
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            _validatePin();
          }
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = '';
      if (!_confirming) {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  Future _validatePin() async {
    if (_pin == _confirmPin) {
      await AuthService.setPin(_pin);
      widget.onPinCreated();
    } else {
      setState(() {
        _error = 'PINs do not match! Try again.';
        _confirmPin = '';
        _pin = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      const Icon(Icons.lock_outline, color: Colors.white, size: 60),
                      const SizedBox(height: 20),
                      Text(
                        _confirming ? 'Confirm PIN' : 'Set PIN for MyLife',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _confirming ? 'Re-enter your 4-digit PIN' : 'Choose a 4-digit PIN to secure your data',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 40),
                      PinDots(length: _confirming ? _confirmPin.length : _pin.length),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(_error, style: const TextStyle(color: Colors.red, fontSize: 14)),
                      ],
                      const Spacer(),
                      Keypad(onKey: _onKey, onDelete: _onDelete),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
