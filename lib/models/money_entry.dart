class MoneyEntry {
  int? id;
  String type;
  String personOrBill;
  double amount;
  String? note;
  bool isPaid;
  DateTime dueDate;
  bool isRecurring;
  String? recurringType;
  DateTime createdAt;

  MoneyEntry({
    this.id,
    required this.type,
    required this.personOrBill,
    required this.amount,
    this.note,
    this.isPaid = false,
    required this.dueDate,
    this.isRecurring = false,
    this.recurringType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'personOrBill': personOrBill,
        'amount': amount,
        'note': note,
        'isPaid': isPaid ? 1 : 0,
        'dueDate': dueDate.toIso8601String(),
        'isRecurring': isRecurring ? 1 : 0,
        'recurringType': recurringType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MoneyEntry.fromMap(Map<String, dynamic> m) => MoneyEntry(
        id: m['id'],
        type: m['type'],
        personOrBill: m['personOrBill'],
        amount: m['amount'],
        note: m['note'],
        isPaid: m['isPaid'] == 1,
        dueDate: DateTime.parse(m['dueDate']),
        isRecurring: m['isRecurring'] == 1,
        recurringType: m['recurringType'],
        createdAt: DateTime.parse(m['createdAt']),
      );
}
