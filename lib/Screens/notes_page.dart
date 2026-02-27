import 'package:flutter/material.dart';
import 'package:keepset/Screens/note_detail_page.dart';
import 'package:keepset/db/notes_database.dart';
import 'package:keepset/model/note.dart';
import 'package:keepset/widget/note_card_widget.dart';

import '../utils/premium_gate.dart';
import 'edit_note_page.dart';

class NotesPage extends StatefulWidget {
  final VoidCallback? onCreateNote;
  final bool Function(
    PremiumAction action, {
    required VoidCallback onAllowed,
  }) runPremiumAction;

  const NotesPage(
      {super.key, required this.onCreateNote, required this.runPremiumAction});

  static void openCreate(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditNotePage(),
      ),
    );
  }

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _active = [];
  List<Note> _archived = [];

  bool _loading = false;
  bool _showArchived = false;

  DateTime? _lastRefresh;
  static const _minRefreshGap = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _refresh(force: true);
  }

  Future<void> _refresh({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastRefresh != null &&
        now.difference(_lastRefresh!) < _minRefreshGap) {
      return;
    }

    _lastRefresh = now;
    setState(() => _loading = true);

    final all =
        await NotesDatabase.instance.readItemsNotes(includeArchived: true);

    setState(() {
      _active = all
          .where((n) => n.lifecycleState != LifecycleState.archived)
          .toList();
      _archived = all
          .where((n) => n.lifecycleState == LifecycleState.archived)
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ..._active.map(_noteTile),
          if (_archived.isNotEmpty) ...[
            const SizedBox(height: 16),
            _archiveHeader(),
            if (_showArchived) ..._archived.map(_noteTile),
          ],
        ],
      ),
    );
  }

  Widget _noteTile(Note note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteDetailPage(noteId: note.id!),
            ),
          );
          _refresh(force: true);
        },
        child: NoteCardWidget(
          note: note,
          onChanged: () => _refresh(force: true),
        ),
      ),
    );
  }

  Widget _archiveHeader() {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _showArchived = !_showArchived),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.onSurface.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Text(
              'Archived',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const Spacer(),
            Icon(
              _showArchived
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 20,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }
}
