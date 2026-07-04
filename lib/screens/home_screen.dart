import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/task.dart';
import '../models/money_entry.dart';
import '../services/database_service.dart';
import '../widgets/shared_cards.dart';
import 'global_search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _todayTasks = [];
  List<MoneyEntry> _dueToday = [];
  int _pendingTasks = 0;
  double _totalOwed = 0;
  double _totalToCollect = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future _load() async {
    final today = DateTime.now();
    final tasks = await DatabaseService.instance.getTasks();
    final money = await DatabaseService.instance.getMoneyEntries();

    setState(() {
      _todayTasks = tasks.where((t) =>
          t.dueDate.day == today.day &&
          t.dueDate.month == today.month &&
          t.dueDate.year == today.year).toList();
      _dueToday = money.where((m) =>
          !m.isPaid &&
          m.dueDate.day == today.day &&
          m.dueDate.month == today.month &&
          m.dueDate.year == today.year).toList();
      _pendingTasks = tasks.where((t) => !t.isDone).length;
      _totalOwed = money.where((m) => !m.isPaid && (m.type == 'pay' || m.type == 'bill')).fold(0, (s, m) => s + m.amount);
      _totalToCollect = money.where((m) => !m.isPaid && m.type == 'collect').fold(0, (s, m) => s + m.amount);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyLife', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => openGlobalSearch(context)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kText)),
              Text(DateFormat('EEEE, dd MMMM yyyy').format(now), style: const TextStyle(color: kSubText)),
              const SizedBox(height: 20),
              Row(children: [
                StatCard(label: 'Pending Tasks', value: '$_pendingTasks', color: kPrimary, icon: Icons.task_alt),
                const SizedBox(width: 12),
                StatCard(label: 'I Owe', value: '₹${_totalOwed.toStringAsFixed(0)}', color: kDanger, icon: Icons.arrow_upward),
                const SizedBox(width: 12),
                StatCard(label: 'To Collect', value: '₹${_totalToCollect.toStringAsFixed(0)}', color: kAccent, icon: Icons.arrow_downward),
              ]),
              const SizedBox(height: 20),
              SectionHeader(title: "Today's Tasks", count: _todayTasks.length),
              if (_todayTasks.isEmpty)
                const EmptyState(message: 'No tasks for today 🎉')
              else
                ..._todayTasks.map((t) => MiniTaskCard(
                    task: t,
                    onToggle: () async {
                      t.isDone = !t.isDone;
                      await DatabaseService.instance.updateTask(t);
                      _load();
                    })),
              const SizedBox(height: 20),
              SectionHeader(title: 'Payments Due Today', count: _dueToday.length),
              if (_dueToday.isEmpty)
                const EmptyState(message: 'No payments due today')
              else
                ..._dueToday.map((m) => MiniMoneyCard(entry: m)),
            ],
          ),
        ),
      ),
    );
  }
}
