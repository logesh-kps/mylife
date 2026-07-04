import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart';
import '../models/money_entry.dart';

class ReportService {
  static Future<String> exportMonthlyMoneyPdf(List<MoneyEntry> entries) async {
    final now = DateTime.now();
    final monthEntries =
        entries.where((e) => e.dueDate.year == now.year && e.dueDate.month == now.month).toList();
    final spend = monthEntries
        .where((e) => e.type == 'pay' || e.type == 'bill')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final collect = monthEntries.where((e) => e.type == 'collect').fold<double>(0, (sum, e) => sum + e.amount);
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('MyLife Money Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(DateFormat('MMMM yyyy').format(now)),
          pw.SizedBox(height: 20),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Spend: Rs ${spend.toStringAsFixed(0)}')),
            pw.Expanded(child: pw.Text('Collect: Rs ${collect.toStringAsFixed(0)}')),
            pw.Expanded(child: pw.Text('Net: Rs ${(collect - spend).toStringAsFixed(0)}')),
          ]),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Type', 'Name', 'Amount', 'Status'],
            data: monthEntries
                .map((e) => [
                      DateFormat('dd MMM').format(e.dueDate),
                      e.type,
                      e.personOrBill,
                      'Rs ${e.amount.toStringAsFixed(0)}',
                      e.isPaid ? 'Paid' : 'Pending',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    final dbPath = await getDatabasesPath();
    final reportsDir = Directory(p.join(dbPath, 'reports'));
    if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
    final fileName = 'mylife_money_${DateFormat('yyyy_MM').format(now)}.pdf';
    final file = File(p.join(reportsDir.path, fileName));
    await file.writeAsBytes(await doc.save());
    return file.path;
  }
}
