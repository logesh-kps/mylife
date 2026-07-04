class NoteItem {
  int? id;
  String title;
  String content;
  int color;
  bool isPinned;
  DateTime createdAt;

  NoteItem({
    this.id,
    required this.title,
    required this.content,
    required this.color,
    this.isPinned = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'color': color,
        'isPinned': isPinned ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteItem.fromMap(Map<String, dynamic> m) => NoteItem(
        id: m['id'],
        title: m['title'],
        content: m['content'],
        color: m['color'],
        isPinned: m['isPinned'] == 1,
        createdAt: DateTime.parse(m['createdAt']),
      );
}
