import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/task.dart';
import '../models/money_entry.dart';

class StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const StatCard({super.key, required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: kSubText)),
        ]),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const SectionHeader({super.key, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  const EmptyState({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Text(message, style: const TextStyle(color: kSubText), textAlign: TextAlign.center),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: kSubText),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: kSubText)),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: kPrimary));
  }
}

class MiniTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  const MiniTaskCard({super.key, required this.task, required this.onToggle});

  Color get _priorityColor => task.priority == 'high' ? kDanger : task.priority == 'medium' ? kWarning : kAccent;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: GestureDetector(
          onTap: onToggle,
          child: Icon(task.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: task.isDone ? kAccent : kSubText),
        ),
        title: Text(task.title,
            style: TextStyle(
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                color: task.isDone ? kSubText : kText)),
        subtitle: task.carriedFrom == null
            ? null
            : Text('Carried from ${DateFormat('dd MMM yyyy').format(task.carriedFrom!)}',
                style: const TextStyle(fontSize: 11, color: kWarning)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _priorityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(task.priority, style: TextStyle(fontSize: 10, color: _priorityColor)),
          ),
          const SizedBox(width: 4),
          Icon(task.category == 'work' ? Icons.work_outline : Icons.home_outlined, size: 16, color: kSubText),
        ]),
      ),
    );
  }
}

class MiniMoneyCard extends StatelessWidget {
  final MoneyEntry entry;
  const MiniMoneyCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isCollect = entry.type == 'collect';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCollect ? kAccent.withOpacity(0.1) : kDanger.withOpacity(0.1),
          child: Icon(isCollect ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCollect ? kAccent : kDanger, size: 18),
        ),
        title: Text(entry.personOrBill),
        subtitle: Text(isCollect ? 'Collect from' : 'Pay to', style: const TextStyle(fontSize: 12)),
        trailing: Text('₹${entry.amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isCollect ? kAccent : kDanger)),
      ),
    );
  }
}
