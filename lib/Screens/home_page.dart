import 'package:flutter/material.dart';
import 'package:keepset/Screens/note_detail_page.dart';
import 'package:keepset/db/notes_database.dart';
import 'package:keepset/model/note.dart';
import 'package:keepset/widget/home_compact_card.dart';

import '../theme/keepset_colors.dart';
import '../utils/premium_gate.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onCreateNote;
  final bool Function(
    PremiumAction action, {
    required VoidCallback onAllowed,
  }) runPremiumAction;

  const HomePage({
    super.key,
    required this.onCreateNote,
    required this.runPremiumAction,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Note> _homeNotes = [];
  final Set<int> _expandedNotes = {};

  DateTime? _lastFetch;
  static const Duration _minRefreshGap = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadHomeNotes(force: true);
  }

  Future<void> _loadHomeNotes({bool force = false}) async {
    final now = DateTime.now();

    if (!force &&
        _lastFetch != null &&
        now.difference(_lastFetch!) < _minRefreshGap) {
      return;
    }

    final notes = await NotesDatabase.instance.readByLifecycle({
      LifecycleState.active,
      LifecycleState.done,
    });

    if (!mounted) return;

    _lastFetch = now;

    // Home rule: ACTIVE first, DONE visible but secondary
    final active =
        notes.where((n) => n.lifecycleState == LifecycleState.active).take(3);

    final done =
        notes.where((n) => n.lifecycleState == LifecycleState.done).take(2);

    setState(() {
      _homeNotes = [...active, ...done];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KeepsetColors.base,
      body: RefreshIndicator(
        onRefresh: () => _loadHomeNotes(force: true),
        child: _homeNotes.isEmpty
            ? _emptyState()
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                itemCount: _homeNotes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _sectionLabel('In focus');
                  }

                  final note = _homeNotes[index - 1];
                  return _buildCard(note);
                },
              ),
      ),
    );
  }

  Widget _buildCard(Note note) {
    final isExpanded = _expandedNotes.contains(note.id);

    return HomeCompactCard(
      key: ValueKey(note.id),
      note: note,
      expanded: isExpanded,
      onToggle: () {
        setState(() {
          isExpanded
              ? _expandedNotes.remove(note.id)
              : _expandedNotes.add(note.id!);
        });
      },
      onOpen: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoteDetailPage(noteId: note.id!),
          ),
        );
        _loadHomeNotes(force: true);
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: KeepsetColors.textMuted,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Center(
          child: Icon(
            Icons.bookmark_border_rounded,
            size: 88,
            color: KeepsetColors.textMuted.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'This is your focus space.\nChoose what deserves your attention.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: KeepsetColors.textMuted.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Only ACTIVE and DONE items appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: KeepsetColors.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
