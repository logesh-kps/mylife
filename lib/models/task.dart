class Task {
  int? id;
  String title;
  String category;
  String priority;
  bool isDone;
  DateTime dueDate;
  DateTime createdAt;
  DateTime? carriedFrom;
  DateTime? reminderAt;

  Task({
    this.id,
    required this.title,
    required this.category,
    required this.priority,
    this.isDone = false,
    required this.dueDate,
    required this.createdAt,
    this.carriedFrom,
    this.reminderAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'priority': priority,
        'isDone': isDone ? 1 : 0,
        'dueDate': dueDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'carriedFrom': carriedFrom?.toIso8601String(),
        'reminderAt': reminderAt?.toIso8601String(),
      };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        id: m['id'],
        title: m['title'],
        category: m['category'],
        priority: m['priority'],
        isDone: m['isDone'] == 1,
        dueDate: DateTime.parse(m['dueDate']),
        createdAt: DateTime.parse(m['createdAt']),
        carriedFrom: m['carriedFrom'] == null ? null : DateTime.parse(m['carriedFrom']),
        reminderAt: m['reminderAt'] == null ? null : DateTime.parse(m['reminderAt']),
      );
}
