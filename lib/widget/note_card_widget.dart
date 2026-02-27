import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:keepset/db/notes_database.dart';
import 'package:keepset/model/note.dart';

class NoteCardWidget extends StatelessWidget {
  final Note note;
  final Future<void> Function() onChanged;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: _surfaceAlpha()),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          if (note.blocks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _preview(context),
          ],
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 8),
          _footer(context),
        ],
      ),
    );
  }

  // ───────────────── HEADER
  Widget _header(BuildContext context) {
    return Row(
      children: [
        _lifecycleIcon(context),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── PREVIEW
  Widget _preview(BuildContext context) {
    final lines =
        note.blocks; //.split('\n').where((l) => l.trim().isNotEmpty).take(2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '• $line',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ───────────────── FOOTER
  Widget _footer(BuildContext context) {
    return Row(
      children: [
        Text(
          _editedLabel(),
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const Spacer(),
        _overflowMenu(context),
      ],
    );
  }

  // ───────────────── ICON
  Widget _lifecycleIcon(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    IconData icon;
    Color color;

    switch (note.lifecycleState) {
      case LifecycleState.active:
        icon = Iconsax.document_text;
        color = scheme.primary;
        break;
      case LifecycleState.done:
        icon = Iconsax.tick_circle;
        color = Colors.green;
        break;
      case LifecycleState.archived:
        icon = Iconsax.archive;
        color = scheme.onSurface.withValues(alpha: 0.45);
        break;
    }

    return Icon(icon, size: 20, color: color);
  }

  // ───────────────── MENU
  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      icon: Icon(
        Iconsax.more,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      onSelected: (action) async {
        if (note.id == null) return;

        switch (action) {
          case _MenuAction.done:
            await NotesDatabase.instance.updateLifecycle(
              note.id!,
              LifecycleState.done,
            );
            break;
          case _MenuAction.restore:
            await NotesDatabase.instance.updateLifecycle(
              note.id!,
              LifecycleState.active,
            );
            break;
          case _MenuAction.archive:
            await NotesDatabase.instance.updateLifecycle(
              note.id!,
              LifecycleState.archived,
            );
            break;
          case _MenuAction.delete:
            await NotesDatabase.instance.delete(note.id!);
            break;
        }

        await onChanged();
      },
      itemBuilder: (_) => _menuItems(),
    );
  }

  List<PopupMenuEntry<_MenuAction>> _menuItems() {
    switch (note.lifecycleState) {
      case LifecycleState.active:
        return const [
          PopupMenuItem(
            value: _MenuAction.done,
            child: _MenuRow(Iconsax.tick_circle, 'Mark done'),
          ),
          PopupMenuItem(
            value: _MenuAction.archive,
            child: _MenuRow(Iconsax.archive, 'Archive'),
          ),
          PopupMenuItem(
            value: _MenuAction.delete,
            child: _MenuRow(Iconsax.trash, 'Delete'),
          ),
        ];

      case LifecycleState.done:
        return const [
          PopupMenuItem(
            value: _MenuAction.restore,
            child: _MenuRow(Iconsax.arrow_square, 'Restore'),
          ),
          PopupMenuItem(
            value: _MenuAction.archive,
            child: _MenuRow(Iconsax.archive, 'Archive'),
          ),
          PopupMenuItem(
            value: _MenuAction.delete,
            child: _MenuRow(Iconsax.trash, 'Delete'),
          ),
        ];

      case LifecycleState.archived:
        return const [
          PopupMenuItem(
            value: _MenuAction.restore,
            child: _MenuRow(Iconsax.arrow_swap, 'Restore'),
          ),
          PopupMenuItem(
            value: _MenuAction.delete,
            child: _MenuRow(Iconsax.trash, 'Delete'),
          ),
        ];
    }
  }

  // ───────────────── HELPERS
  double _surfaceAlpha() {
    switch (note.lifecycleState) {
      case LifecycleState.active:
        return 0.95;
      case LifecycleState.done:
        return 0.85;
      case LifecycleState.archived:
        return 0.75;
    }
  }

  String _editedLabel() {
    final diff = DateTime.now().difference(note.createdTime).inDays;
    if (diff == 0) return 'Edited today';
    if (diff == 1) return 'Edited yesterday';
    if (diff < 7) return 'Edited $diff days ago';
    return 'Edited ${DateFormat.yMMMd().format(note.createdTime)}';
  }
}

enum _MenuAction {
  done,
  restore,
  archive,
  delete,
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
