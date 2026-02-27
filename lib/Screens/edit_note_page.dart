import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:keepset/db/notes_database.dart';
import 'package:keepset/model/block.dart';
import 'package:keepset/model/note.dart';

import '../theme/keepset_colors.dart';

enum InsertBlockType { text, checklist, section }

class AddEditNotePage extends StatefulWidget {
  final Note? note;

  const AddEditNotePage({super.key, this.note});

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _titleController = TextEditingController();
  late List<Block> _blocks;

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _blocks = List<Block>.from(widget.note!.blocks);
    } else {
      _blocks = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KeepsetColors.base,
      appBar: AppBar(
        backgroundColor: KeepsetColors.base,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: KeepsetColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildBlocks(),
              ],
            ),
          ),
          _EditorInsertBar(onInsert: _insertBlock),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Block rendering
  // ─────────────────────────────────────────

  List<Widget> _buildBlocks() {
    return List.generate(_blocks.length, (index) {
      final block = _blocks[index];

      if (block is SectionBlock) {
        return _blockField(
          initial: block.title,
          style: TextStyle(
            color: KeepsetColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
          onChanged: (v) {
            _replaceBlock(index, SectionBlock(title: v));
          },
        );
      }

      if (block is ChecklistBlock) {
        final item = block.items.first;
        return _blockField(
          initial: item.text,
          prefix: Icons.check_box_outline_blank,
          onChanged: (v) {
            _replaceBlock(
              index,
              ChecklistBlock(
                items: [
                  ChecklistItem(
                    text: v,
                    checked: item.checked,
                  ),
                ],
              ),
            );
          },
        );
      }

      if (block is TextBlock) {
        return _blockField(
          initial: block.text,
          onChanged: (v) {
            _replaceBlock(index, TextBlock(text: v));
          },
        );
      }

      return const SizedBox.shrink();
    });
  }

  Widget _blockField({
    required String initial,
    required ValueChanged<String> onChanged,
    TextStyle? style,
    IconData? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix != null) ...[
            Icon(prefix, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextFormField(
              initialValue: initial,
              onChanged: onChanged,
              style: style,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _replaceBlock(int index, Block block) {
    setState(() {
      _blocks[index] = block;
    });
  }

  // ─────────────────────────────────────────
  // Insert
  // ─────────────────────────────────────────

  void _insertBlock(InsertBlockType type) {
    setState(() {
      switch (type) {
        case InsertBlockType.text:
          _blocks.add(TextBlock(text: ''));
          break;
        case InsertBlockType.section:
          _blocks.add(SectionBlock(title: ''));
          break;
        case InsertBlockType.checklist:
          _blocks.add(
            ChecklistBlock(
              items: [
                ChecklistItem(text: '', checked: false),
              ],
            ),
          );
          break;
      }
    });
  }

  // ─────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty && _blocks.isEmpty) return;

    final now = DateTime.now();

    if (widget.note == null) {
      await NotesDatabase.instance.create(
        Note(
          title: title.isEmpty ? 'Untitled' : title,
          blocks: _blocks,
          createdTime: now,
          updatedAt: now,
          lifecycleState: LifecycleState.active,
        ),
      );
    } else {
      await NotesDatabase.instance.update(
        widget.note!.copy(
          title: title,
          blocks: _blocks,
          updatedAt: now,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

// ─────────────────────────────────────────
// Insert Bar
// ─────────────────────────────────────────

class _EditorInsertBar extends StatelessWidget {
  final void Function(InsertBlockType) onInsert;

  const _EditorInsertBar({required this.onInsert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: KeepsetColors.base,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _InsertChip(
            icon: Iconsax.text,
            label: 'Text',
            onTap: () => onInsert(InsertBlockType.text),
          ),
          _InsertChip(
            icon: Iconsax.tick_square,
            label: 'Checklist',
            onTap: () => onInsert(InsertBlockType.checklist),
          ),
          _InsertChip(
            icon: Iconsax.layer,
            label: 'Section',
            onTap: () => onInsert(InsertBlockType.section),
          ),
        ],
      ),
    );
  }
}

class _InsertChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InsertChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: KeepsetColors.layer1,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: KeepsetColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: KeepsetColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
