import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/money_entry.dart';
import '../services/database_service.dart';
import '../widgets/shared_cards.dart';

void openGlobalSearch(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));
}

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _queryCtrl = TextEditingController();
  List<Task> _tasks = [];
  List<MoneyEntry> _money = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _queryCtrl.addListener(() => setState(() => _query = _queryCtrl.text.trim().toLowerCase()));
  }

  Future<void> _load() async {
    final tasks = await DatabaseService.instance.getTasks();
    final money = await DatabaseService.instance.getMoneyEntries();
    setState(() {
      _tasks = tasks;
      _money = money;
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskResults = _tasks.where((t) {
      return _query.isEmpty ||
          t.title.toLowerCase().contains(_query) ||
          t.category.toLowerCase().contains(_query) ||
          t.priority.toLowerCase().contains(_query);
    }).toList();
    final moneyResults = _money.where((m) {
      return _query.isEmpty ||
          m.personOrBill.toLowerCase().contains(_query) ||
          (m.note ?? '').toLowerCase().contains(_query) ||
          m.type.toLowerCase().contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _queryCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search tasks and money',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(title: 'Tasks', count: taskResults.length),
          if (taskResults.isEmpty)
            const EmptyState(message: 'No matching tasks')
          else
            ...taskResults.map((t) => MiniTaskCard(task: t, onToggle: () async {
                  t.isDone = !t.isDone;
                  await DatabaseService.instance.updateTask(t);
                  _load();
                })),
          const SizedBox(height: 16),
          SectionHeader(title: 'Money', count: moneyResults.length),
          if (moneyResults.isEmpty)
            const EmptyState(message: 'No matching money entries')
          else
            ...moneyResults.map((m) => MiniMoneyCard(entry: m)),
        ],
      ),
    );
  }
}
