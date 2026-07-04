import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/money_entry.dart';

class ClaudeService {
  static const _model = 'claude-haiku-4-5';

  static Future<String> ask(String prompt, String apiKey) async {
    try {
      final res = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system':
              'You are MyLife AI assistant. Help manage personal tasks, money tracking, and daily planning. Be concise, practical, and friendly.',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['content'][0]['text'];
      }
      return 'Error: ${res.statusCode}';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  static Future<String> getDailySummary(
      List<Task> tasks, List<MoneyEntry> money, String apiKey) async {
    final today = DateTime.now();
    final todayTasks = tasks.where((t) =>
        t.dueDate.day == today.day &&
        t.dueDate.month == today.month &&
        t.dueDate.year == today.year).toList();
    final pendingMoney = money
        .where((m) => !m.isPaid && m.dueDate.isBefore(today.add(const Duration(days: 7))))
        .toList();

    final prompt = '''
TODAY (${DateFormat('dd MMM yyyy').format(today)}):
Tasks: ${todayTasks.map((t) => '[${t.isDone ? 'DONE' : 'PENDING'}] ${t.title}').join(', ')}
Money due: ${pendingMoney.map((m) => '${m.type} ₹${m.amount.toStringAsFixed(0)} ${m.personOrBill}').join(', ')}
Give brief morning briefing under 150 words.''';
    return ask(prompt, apiKey);
  }

  static Future<String> getSpendAnalysis(
      List<MoneyEntry> money, String apiKey) async {
    final pending = money.where((m) => !m.isPaid).toList();
    final prompt = '''
PENDING PAY: ${pending.where((m) => m.type != 'collect').map((m) => '₹${m.amount.toStringAsFixed(0)} to ${m.personOrBill} by ${DateFormat('dd MMM').format(m.dueDate)}').join(', ')}
PENDING COLLECT: ${pending.where((m) => m.type == 'collect').map((m) => '₹${m.amount.toStringAsFixed(0)} from ${m.personOrBill}').join(', ')}
Analyze and suggest priority order to clear dues. Under 200 words.''';
    return ask(prompt, apiKey);
  }
}
