import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import 'set_pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricSupported = false;
  bool _biometricEnabled = true;
  String _apiKey = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supported = await AuthService.isBiometricAvailable();
    final enabled = await AuthService.isBiometricEnabled();
    final apiKey = await SecureStorageService.getApiKey();
    setState(() {
      _biometricSupported = supported;
      _biometricEnabled = enabled;
      _apiKey = apiKey;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    await AuthService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _changePin() async {
    final currentPinCtrl = TextEditingController();
    final verified = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm current PIN'),
        content: TextField(
          controller: currentPinCtrl,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(labelText: 'Current PIN', counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              final ok = await AuthService.verifyPin(currentPinCtrl.text.trim());
              if (context.mounted) Navigator.pop(context, ok);
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (verified != true) {
      if (verified == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPinScreen(onPinCreated: () => Navigator.of(context).pop()),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN updated')),
      );
    }
  }

  Future<void> _editApiKey() async {
    final ctrl = TextEditingController(text: _apiKey);
    final saved = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Claude API Key'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Stored only on your device.', style: TextStyle(fontSize: 12, color: kSubText)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder(), prefixIcon: Icon(Icons.key)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == null) return;
    await SecureStorageService.setApiKey(saved);
    setState(() => _apiKey = saved);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('App Lock', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kSubText)),
          ),
          ListTile(
            leading: const Icon(Icons.password, color: kPrimary),
            title: const Text('Change PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePin,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: kPrimary),
            title: const Text('Use fingerprint to unlock'),
            subtitle: _biometricSupported
                ? null
                : const Text('Not available on this device', style: TextStyle(fontSize: 12)),
            value: _biometricEnabled && _biometricSupported,
            onChanged: _biometricSupported ? _toggleBiometric : null,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('AI Assistant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kSubText)),
          ),
          ListTile(
            leading: const Icon(Icons.key, color: kPrimary),
            title: const Text('Claude API Key'),
            subtitle: Text(_apiKey.isEmpty ? 'Not set' : '••••${_apiKey.length > 4 ? _apiKey.substring(_apiKey.length - 4) : _apiKey}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editApiKey,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kSubText)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: kPrimary),
            title: Text('MyLife'),
            subtitle: Text('Personal life management app · local-first & privacy-focused'),
          ),
        ],
      ),
    );
  }
}
