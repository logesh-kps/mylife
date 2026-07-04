import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../widgets/shared_cards.dart';
import 'global_search_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Task> _tasks = [];
  String _filter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future _load() async {
    final tasks = await DatabaseService.instance.getTasks();
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  List<Task> _filtered(String category) {
    return _tasks.where((t) {
      final catMatch = t.category == category;
      final statusMatch = _filter == 'all' ||
          (_filter == 'pending' && !t.isDone) ||
          (_filter == 'done' && t.isDone);
      return catMatch && statusMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: '💼 Work'), Tab(text: '🏠 Personal')],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => openGlobalSearch(context)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'done', child: Text('Done')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : TabBarView(
        controller: _tab,
        children: ['work', 'personal'].map((cat) {
          final tasks = _filtered(cat);
          if (tasks.isEmpty) {
            return EmptyState(message: 'No $cat tasks', icon: Icons.task_alt);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (_, i) => _TaskCard(task: tasks[i], onRefresh: _load),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
              context: context,
              builder: (_) => AddTaskDialog(category: _tab.index == 0 ? 'work' : 'personal'));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onRefresh;
  const _TaskCard({required this.task, required this.onRefresh});

  Color get _priorityColor => task.priority == 'high' ? kDanger : task.priority == 'medium' ? kWarning : kAccent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          GestureDetector(
            onTap: () async {
              task.isDone = !task.isDone;
              await DatabaseService.instance.updateTask(task);
              onRefresh();
            },
            child: Icon(task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.isDone ? kAccent : kSubText, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                      color: task.isDone ? kSubText : kText)),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: _priorityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(task.priority.toUpperCase(),
                      style: TextStyle(fontSize: 10, color: _priorityColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today, size: 12, color: kSubText),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM').format(task.dueDate),
                    style: const TextStyle(fontSize: 12, color: kSubText)),
                if (task.reminderAt != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.alarm, size: 12, color: kPrimary),
                  const SizedBox(width: 4),
                  Text(DateFormat('HH:mm').format(task.reminderAt!),
                      style: const TextStyle(
                          fontSize: 12,
                          color: kPrimary,
                          fontWeight: FontWeight.bold)),
                ],
                if (task.carriedFrom != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Carried from ${DateFormat('dd MMM').format(task.carriedFrom!)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: kWarning)),
                  ),
                ],
              ]),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: kPrimary),
            onPressed: () async {
              await showDialog(context: context, builder: (_) => AddTaskDialog(task: task));
              onRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kDanger),
            onPressed: () async {
              await DatabaseService.instance.deleteTask(task.id!);
              onRefresh();
            },
          ),
        ]),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final String? category;
  final Task? task;
  const AddTaskDialog({super.key, this.category, this.task});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleCtrl = TextEditingController();
  String _priority = 'medium';
  DateTime _dueDate = DateTime.now();
  late String _category;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleCtrl.text = task.title;
      _priority = task.priority;
      _dueDate = task.dueDate;
      _category = task.category;
      _reminderAt = task.reminderAt;
    } else {
      _category = widget.category ?? 'work';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.task != null;
    return AlertDialog(
      title: Text(editing ? 'Edit Task' : 'Add Task'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Task title', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'work', child: Text('💼 Work')),
              DropdownMenuItem(value: 'personal', child: Text('🏠 Personal')),
            ],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'high', child: Text('🔴 High')),
              DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
              DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
            ],
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due Date'),
            subtitle: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
            trailing: const Icon(Icons.calendar_today, color: kPrimary),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _dueDate = d);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reminder Date & Time'),
            subtitle: Text(_reminderAt == null
                ? 'Not set'
                : DateFormat('dd MMM yyyy HH:mm').format(_reminderAt!)),
            trailing: const Icon(Icons.alarm, color: kPrimary),
            onTap: _selectReminderDateTime,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () async {
            if (_titleCtrl.text.trim().isEmpty) return;
            final existing = widget.task;
            if (existing == null) {
              await DatabaseService.instance.insertTask(Task(
                title: _titleCtrl.text.trim(),
                category: _category,
                priority: _priority,
                dueDate: _dueDate,
                createdAt: DateTime.now(),
                reminderAt: _reminderAt,
              ));
            } else {
              existing.title = _titleCtrl.text.trim();
              existing.category = _category;
              existing.priority = _priority;
              existing.dueDate = _dueDate;
              existing.reminderAt = _reminderAt;
              await DatabaseService.instance.updateTask(existing);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _selectReminderDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
    );
    if (pickedTime == null) return;

    setState(() {
      _reminderAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }
}
