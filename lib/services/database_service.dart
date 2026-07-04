import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/task.dart';
import '../models/money_entry.dart';
import '../models/note_item.dart';
import 'notification_service.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'mylife.db');
    return openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL,
        isDone INTEGER NOT NULL DEFAULT 0,
        dueDate TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        carriedFrom TEXT,
        reminderAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE money(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        personOrBill TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        isPaid INTEGER NOT NULL DEFAULT 0,
        dueDate TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurringType TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
    await _createNotesTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN carriedFrom TEXT');
      } catch (_) {}
      await _createNotesTable(db);
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN reminderAt TEXT');
      } catch (_) {}
    }
  }

  Future _createNotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        color INTEGER NOT NULL,
        isPinned INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTask(Task t) async {
    final db = await database;
    final id = await db.insert('tasks', t.toMap());
    await NotificationService.instance.scheduleAll();
    return id;
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'dueDate ASC');
    return maps.map(Task.fromMap).toList();
  }

  Future updateTask(Task t) async {
    final db = await database;
    await db.update('tasks', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    await NotificationService.instance.scheduleAll();
  }

  Future deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    await NotificationService.instance.scheduleAll();
  }

  Future<void> carryForwardTasks() async {
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final tasks = await getTasks();
    for (final task in tasks) {
      final taskDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      if (!task.isDone && taskDay.isBefore(startToday)) {
        task.carriedFrom ??= task.dueDate;
        task.dueDate = startToday;
        await updateTask(task);
      }
    }
  }

  Future<int> insertMoney(MoneyEntry m) async {
    final db = await database;
    final id = await db.insert('money', m.toMap());
    await NotificationService.instance.scheduleAll();
    return id;
  }

  Future<List<MoneyEntry>> getMoneyEntries() async {
    final db = await database;
    final maps = await db.query('money', orderBy: 'dueDate ASC');
    return maps.map(MoneyEntry.fromMap).toList();
  }

  Future updateMoney(MoneyEntry m) async {
    final db = await database;
    final oldRows = m.id == null ? <Map<String, dynamic>>[] : await db.query('money', where: 'id = ?', whereArgs: [m.id]);
    final wasPaid = oldRows.isNotEmpty && oldRows.first['isPaid'] == 1;
    await db.update('money', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
    if (!wasPaid && m.isPaid && m.isRecurring) {
      await _createNextRecurringMoney(m);
    }
    await NotificationService.instance.scheduleAll();
  }

  Future deleteMoney(int id) async {
    final db = await database;
    await db.delete('money', where: 'id = ?', whereArgs: [id]);
    await NotificationService.instance.scheduleAll();
  }

  Future<void> _createNextRecurringMoney(MoneyEntry entry) async {
    final db = await database;
    final nextDue = entry.recurringType == 'weekly'
        ? entry.dueDate.add(const Duration(days: 7))
        : DateTime(entry.dueDate.year, entry.dueDate.month + 1, entry.dueDate.day);
    final existing = await db.query(
      'money',
      where: 'type = ? AND personOrBill = ? AND amount = ? AND dueDate = ? AND isRecurring = 1',
      whereArgs: [entry.type, entry.personOrBill, entry.amount, nextDue.toIso8601String()],
    );
    if (existing.isNotEmpty) return;
    await db.insert(
      'money',
      MoneyEntry(
        type: entry.type,
        personOrBill: entry.personOrBill,
        amount: entry.amount,
        note: entry.note,
        dueDate: nextDue,
        isRecurring: true,
        recurringType: entry.recurringType,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<int> insertNote(NoteItem note) async {
    final db = await database;
    return db.insert('notes', note.toMap());
  }

  Future<List<NoteItem>> getNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'isPinned DESC, createdAt DESC');
    return maps.map(NoteItem.fromMap).toList();
  }

  Future updateNote(NoteItem note) async {
    final db = await database;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
