import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/claude_service.dart';
import '../services/secure_storage_service.dart';
import 'settings_screen.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future _loadApiKey() async {
    final key = await SecureStorageService.getApiKey();
    setState(() => _apiKey = key);
  }

  Future<void> _openSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    _loadApiKey();
  }

  Future _send(String text) async {
    if (text.trim().isEmpty || _apiKey.isEmpty || _isLoading) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();
    final tasks = await DatabaseService.instance.getTasks();
    final money = await DatabaseService.instance.getMoneyEntries();
    final contextPrompt = '''
Context: ${tasks.length} tasks (${tasks.where((t) => !t.isDone).length} pending), pending pay: ₹${money.where((m) => !m.isPaid && m.type != 'collect').fold(0.0, (s, m) => s + m.amount).toStringAsFixed(0)}, pending collect: ₹${money.where((m) => !m.isPaid && m.type == 'collect').fold(0.0, (s, m) => s + m.amount).toStringAsFixed(0)}
Question: $text''';
    final reply = await ClaudeService.ask(contextPrompt, _apiKey);
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future _getDailySummary() async {
    if (_apiKey.isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    final tasks = await DatabaseService.instance.getTasks();
    final money = await DatabaseService.instance.getMoneyEntries();
    final summary = await ClaudeService.getDailySummary(tasks, money, _apiKey);
    setState(() {
      _messages.add({'role': 'user', 'content': '📋 Daily Briefing'});
      _messages.add({'role': 'assistant', 'content': summary});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future _getSpendAnalysis() async {
    if (_apiKey.isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    final money = await DatabaseService.instance.getMoneyEntries();
    final analysis = await ClaudeService.getSpendAnalysis(money, _apiKey);
    setState(() {
      _messages.add({'role': 'user', 'content': '💰 Spend Analysis'});
      _messages.add({'role': 'assistant', 'content': analysis});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [IconButton(icon: const Icon(Icons.key), onPressed: _openSettings)],
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _apiKey.isEmpty || _isLoading ? null : _getDailySummary,
                icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                label: const Text('Daily Briefing', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _apiKey.isEmpty || _isLoading ? null : _getSpendAnalysis,
                icon: const Icon(Icons.analytics_outlined, size: 16),
                label: const Text('Spend Analysis', style: TextStyle(fontSize: 12)),
              ),
            ),
          ]),
        ),
        if (_apiKey.isEmpty)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: kWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kWarning)),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: kWarning),
              const SizedBox(width: 8),
              const Expanded(child: Text('Set your Claude API key to use AI features', style: TextStyle(fontSize: 13))),
              TextButton(onPressed: _openSettings, child: const Text('Set Key')),
            ]),
          ),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.auto_awesome, size: 60, color: kPrimary),
                    SizedBox(height: 12),
                    Text('Ask me anything!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• What tasks are pending this week?', style: TextStyle(color: kSubText)),
                    Text('• Who do I owe money to?', style: TextStyle(color: kSubText)),
                    Text('• How to clear my dues fast?', style: TextStyle(color: kSubText)),
                  ]),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) {
                      return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    final msg = _messages[i];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isUser ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                        ),
                        child: Text(msg['content']!, style: TextStyle(color: isUser ? Colors.white : kText)),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: _isLoading ? null : _send,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: _isLoading ? kSubText : kPrimary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: _isLoading ? null : () => _send(_msgCtrl.text),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
