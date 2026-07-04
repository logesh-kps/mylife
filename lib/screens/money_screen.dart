import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/money_entry.dart';
import '../services/database_service.dart';
import '../services/report_service.dart';
import '../widgets/shared_cards.dart';
import 'global_search_screen.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<MoneyEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future _load() async {
    final entries = await DatabaseService.instance.getMoneyEntries();
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  List<MoneyEntry> _filtered(String type) => _entries.where((e) => e.type == type).toList();
  double _total(String type) => _entries.where((e) => e.type == type && !e.isPaid).fold(0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => openGlobalSearch(context)),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportReport),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Pay'), Tab(text: 'Collect'), Tab(text: 'Bills'), Tab(text: 'Summary')],
        ),
      ),
      body: Column(children: [
        Container(
          color: kPrimary.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _MoneyChip(label: 'I Owe', amount: _total('pay') + _total('bill'), color: kDanger),
            const SizedBox(width: 8),
            _MoneyChip(label: 'To Collect', amount: _total('collect'), color: kAccent),
            const SizedBox(width: 8),
            _MoneyChip(label: 'Net', amount: _total('collect') - (_total('pay') + _total('bill')), color: kPrimary),
          ]),
        ),
        Expanded(
          child: _loading
              ? const LoadingIndicator()
              : TabBarView(
            controller: _tab,
            children: [
              ...['pay', 'collect', 'bill'].map((type) {
                final entries = _filtered(type);
                if (entries.isEmpty) {
                  return EmptyState(
                    message: 'No ${type == 'pay' ? 'payments' : type == 'collect' ? 'collections' : 'bills'}',
                    icon: Icons.account_balance_wallet_outlined,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _MoneyCard(entry: entries[i], onRefresh: _load),
                );
              }),
              _MoneySummaryChart(entries: _entries),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final types = ['pay', 'collect', 'bill'];
          final type = _tab.index < types.length ? types[_tab.index] : 'bill';
          await showDialog(context: context, builder: (_) => AddMoneyDialog(defaultType: type));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _exportReport() async {
    final path = await ReportService.exportMonthlyMoneyPdf(_entries);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF exported: $path')));
  }
}

class _MoneySummaryChart extends StatelessWidget {
  final List<MoneyEntry> entries;
  const _MoneySummaryChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final maxY = months.fold<double>(0, (max, month) {
      final spend = _monthTotal(month, spend: true);
      final collect = _monthTotal(month, spend: false);
      return [max, spend, collect].reduce((a, b) => a > b ? a : b);
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Monthly Spend vs Collect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kText)),
        const SizedBox(height: 6),
        const Text('Last 6 months', style: TextStyle(color: kSubText)),
        const SizedBox(height: 24),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 100 : maxY * 1.2,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= months.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(DateFormat('MMM').format(months[index]), style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(toY: _monthTotal(months[i], spend: true), color: kDanger, width: 9),
                      BarChartRodData(toY: _monthTotal(months[i], spend: false), color: kAccent, width: 9),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: const [
          _LegendDot(color: kDanger, label: 'Spend'),
          SizedBox(width: 16),
          _LegendDot(color: kAccent, label: 'Collect'),
        ]),
      ],
    );
  }

  double _monthTotal(DateTime month, {required bool spend}) {
    return entries.where((e) {
      final typeMatch = spend ? e.type == 'pay' || e.type == 'bill' : e.type == 'collect';
      return typeMatch && e.dueDate.year == month.year && e.dueDate.month == month.month;
    }).fold<double>(0, (sum, e) => sum + e.amount);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: kSubText)),
    ]);
  }
}

class _MoneyChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _MoneyChip({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text('₹${amount.abs().toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  final MoneyEntry entry;
  final VoidCallback onRefresh;
  const _MoneyCard({required this.entry, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isOverdue = !entry.isPaid && entry.dueDate.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.personOrBill, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (entry.note != null && entry.note!.isNotEmpty)
                  Text(entry.note!, style: const TextStyle(color: kSubText, fontSize: 12)),
              ]),
            ),
            Text('₹${entry.amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: entry.type == 'collect' ? kAccent : kDanger)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today, size: 12, color: isOverdue ? kDanger : kSubText),
            const SizedBox(width: 4),
            Text('Due: ${DateFormat('dd MMM yyyy').format(entry.dueDate)}',
                style: TextStyle(fontSize: 12, color: isOverdue ? kDanger : kSubText)),
            if (isOverdue) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(4)),
                child: const Text('OVERDUE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () async {
                entry.isPaid = !entry.isPaid;
                await DatabaseService.instance.updateMoney(entry);
                onRefresh();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.isPaid ? kAccent : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(entry.isPaid ? '✓ Paid' : 'Mark Paid',
                    style: TextStyle(
                        fontSize: 12,
                        color: entry.isPaid ? Colors.white : kSubText,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                await showDialog(context: context, builder: (_) => AddMoneyDialog(entry: entry));
                onRefresh();
              },
              child: const Icon(Icons.edit_outlined, color: kPrimary, size: 20),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                await DatabaseService.instance.deleteMoney(entry.id!);
                onRefresh();
              },
              child: const Icon(Icons.delete_outline, color: kDanger, size: 20),
            ),
          ]),
        ]),
      ),
    );
  }
}

class AddMoneyDialog extends StatefulWidget {
  final String? defaultType;
  final MoneyEntry? entry;
  const AddMoneyDialog({super.key, this.defaultType, this.entry});

  @override
  State<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<AddMoneyDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late String _type;
  DateTime _dueDate = DateTime.now();
  bool _isRecurring = false;
  String _recurringType = 'monthly';

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry != null) {
      _type = entry.type;
      _nameCtrl.text = entry.personOrBill;
      _amountCtrl.text = entry.amount.toStringAsFixed(0);
      _noteCtrl.text = entry.note ?? '';
      _dueDate = entry.dueDate;
      _isRecurring = entry.isRecurring;
      _recurringType = entry.recurringType ?? 'monthly';
    } else {
      _type = widget.defaultType ?? 'pay';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.entry != null;
    return AlertDialog(
      title: Text(editing ? 'Edit Money Entry' : 'Add Money Entry'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'pay', child: Text('💸 Pay (I owe someone)')),
              DropdownMenuItem(value: 'collect', child: Text('💰 Collect (someone owes me)')),
              DropdownMenuItem(value: 'bill', child: Text('🧾 Bill (EB, rent, EMI)')),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: _type == 'collect' ? 'Person name' : _type == 'pay' ? 'Person name' : 'Bill name',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
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
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _dueDate = d);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Recurring?'),
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),
          if (_isRecurring)
            DropdownButtonFormField<String>(
              value: _recurringType,
              decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              ],
              onChanged: (v) => setState(() => _recurringType = v!),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) return;
            final amount = double.tryParse(_amountCtrl.text.trim());
            if (amount == null) return;
            final existing = widget.entry;
            if (existing == null) {
              await DatabaseService.instance.insertMoney(MoneyEntry(
                type: _type,
                personOrBill: _nameCtrl.text.trim(),
                amount: amount,
                note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                dueDate: _dueDate,
                isRecurring: _isRecurring,
                recurringType: _isRecurring ? _recurringType : null,
                createdAt: DateTime.now(),
              ));
            } else {
              existing.type = _type;
              existing.personOrBill = _nameCtrl.text.trim();
              existing.amount = amount;
              existing.note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
              existing.dueDate = _dueDate;
              existing.isRecurring = _isRecurring;
              existing.recurringType = _isRecurring ? _recurringType : null;
              await DatabaseService.instance.updateMoney(existing);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
