import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/note_item.dart';
import '../services/database_service.dart';
import '../widgets/shared_cards.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchCtrl = TextEditingController();
  List<NoteItem> _notes = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final notes = await DatabaseService.instance.getNotes();
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  List<NoteItem> get _filteredNotes {
    if (_query.isEmpty) return _notes;
    return _notes
        .where((n) => n.title.toLowerCase().contains(_query) || n.content.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final notes = _filteredNotes;
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search notes',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingIndicator()
              : notes.isEmpty
                  ? const EmptyState(message: 'No notes yet', icon: Icons.notes_outlined)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: notes.length,
                      itemBuilder: (_, i) => _NoteCard(note: notes[i], onRefresh: _load),
                    ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(context: context, builder: (_) => const AddNoteDialog());
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onRefresh;
  const _NoteCard({required this.note, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final color = Color(note.color);
    return Card(
      color: color.withOpacity(0.14),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await showDialog(context: context, builder: (_) => AddNoteDialog(note: note));
          onRefresh();
        },
        onLongPress: () async {
          await DatabaseService.instance.deleteNote(note.id!);
          onRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kText)),
              ),
              IconButton(
                tooltip: note.isPinned ? 'Unpin' : 'Pin',
                icon: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: kPrimary),
                onPressed: () async {
                  note.isPinned = !note.isPinned;
                  await DatabaseService.instance.updateNote(note);
                  onRefresh();
                },
              ),
            ]),
            if (note.content.isNotEmpty)
              Text(note.content, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kSubText)),
            const SizedBox(height: 8),
            Text(DateFormat('dd MMM yyyy').format(note.createdAt), style: const TextStyle(fontSize: 11, color: kSubText)),
          ]),
        ),
      ),
    );
  }
}

class AddNoteDialog extends StatefulWidget {
  final NoteItem? note;
  const AddNoteDialog({super.key, this.note});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  late int _color;
  late bool _isPinned;

  static const _colors = [0xFF1A73E8, 0xFF34A853, 0xFFFBBC04, 0xFFEA4335, 0xFF9AA0A6];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleCtrl.text = note?.title ?? '';
    _contentCtrl.text = note?.content ?? '';
    _color = note?.color ?? _colors.first;
    _isPinned = note?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    return AlertDialog(
      title: Text(editing ? 'Edit Note' : 'Add Note'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final colorValue in _colors)
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _color = colorValue),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(color: _color == colorValue ? kText : Colors.transparent, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pin to top'),
            value: _isPinned,
            onChanged: (v) => setState(() => _isPinned = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
          onPressed: () async {
            if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) return;
            final title = _titleCtrl.text.trim().isEmpty ? 'Untitled' : _titleCtrl.text.trim();
            final existing = widget.note;
            if (existing == null) {
              await DatabaseService.instance.insertNote(NoteItem(
                title: title,
                content: _contentCtrl.text.trim(),
                color: _color,
                isPinned: _isPinned,
                createdAt: DateTime.now(),
              ));
            } else {
              existing.title = title;
              existing.content = _contentCtrl.text.trim();
              existing.color = _color;
              existing.isPinned = _isPinned;
              await DatabaseService.instance.updateNote(existing);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
