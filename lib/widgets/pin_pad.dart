import 'package:flutter/material.dart';

class PinDots extends StatelessWidget {
  final int length;
  const PinDots({super.key, required this.length});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < length ? Colors.white : Colors.white30,
          border: Border.all(color: Colors.white54, width: 2),
        ),
      )),
    );
  }
}

class Keypad extends StatelessWidget {
  final Function(String) onKey;
  final VoidCallback onDelete;
  final bool disabled;

  const Keypad({super.key, required this.onKey, required this.onDelete, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _keyRow(const ['1', '2', '3']),
          const SizedBox(height: 16),
          _keyRow(const ['4', '5', '6']),
          const SizedBox(height: 16),
          _keyRow(const ['7', '8', '9']),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _KeyButton(label: '0', onTap: () => onKey('0'), disabled: disabled),
              SizedBox(
                width: 72,
                height: 72,
                child: IconButton(
                  onPressed: disabled ? null : onDelete,
                  icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _KeyButton(label: k, onTap: () => onKey(k), disabled: disabled)).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  const _KeyButton({required this.label, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: disabled ? Colors.white10 : Colors.white24,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: disabled ? Colors.white30 : Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
