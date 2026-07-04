import 'package:flutter_test/flutter_test.dart';
import 'package:mylife/models/task.dart';
import 'package:mylife/models/money_entry.dart';
import 'package:mylife/models/note_item.dart';

void main() {
  group('Task', () {
    test('toMap/fromMap round trip preserves all fields', () {
      final task = Task(
        id: 1,
        title: 'Buy groceries',
        category: 'personal',
        priority: 'high',
        isDone: true,
        dueDate: DateTime(2026, 7, 4),
        createdAt: DateTime(2026, 7, 1),
        carriedFrom: DateTime(2026, 7, 2),
        reminderAt: DateTime(2026, 7, 4, 9, 30),
      );

      final restored = Task.fromMap(task.toMap());

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.category, task.category);
      expect(restored.priority, task.priority);
      expect(restored.isDone, task.isDone);
      expect(restored.dueDate, task.dueDate);
      expect(restored.createdAt, task.createdAt);
      expect(restored.carriedFrom, task.carriedFrom);
      expect(restored.reminderAt, task.reminderAt);
    });

    test('nullable fields round-trip as null', () {
      final task = Task(
        title: 'No reminder',
        category: 'work',
        priority: 'low',
        dueDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
      );

      final restored = Task.fromMap(task.toMap());

      expect(restored.carriedFrom, isNull);
      expect(restored.reminderAt, isNull);
    });
  });

  group('MoneyEntry', () {
    test('toMap/fromMap round trip preserves all fields', () {
      final entry = MoneyEntry(
        id: 5,
        type: 'bill',
        personOrBill: 'Electricity',
        amount: 1234.5,
        note: 'March bill',
        isPaid: true,
        dueDate: DateTime(2026, 3, 15),
        isRecurring: true,
        recurringType: 'monthly',
        createdAt: DateTime(2026, 3, 1),
      );

      final restored = MoneyEntry.fromMap(entry.toMap());

      expect(restored.id, entry.id);
      expect(restored.type, entry.type);
      expect(restored.personOrBill, entry.personOrBill);
      expect(restored.amount, entry.amount);
      expect(restored.note, entry.note);
      expect(restored.isPaid, entry.isPaid);
      expect(restored.dueDate, entry.dueDate);
      expect(restored.isRecurring, entry.isRecurring);
      expect(restored.recurringType, entry.recurringType);
      expect(restored.createdAt, entry.createdAt);
    });
  });

  group('NoteItem', () {
    test('toMap/fromMap round trip preserves all fields', () {
      final note = NoteItem(
        id: 2,
        title: 'Idea',
        content: 'Ship the refactor',
        color: 0xFF34A853,
        isPinned: true,
        createdAt: DateTime(2026, 6, 20),
      );

      final restored = NoteItem.fromMap(note.toMap());

      expect(restored.id, note.id);
      expect(restored.title, note.title);
      expect(restored.content, note.content);
      expect(restored.color, note.color);
      expect(restored.isPinned, note.isPinned);
      expect(restored.createdAt, note.createdAt);
    });
  });
}
