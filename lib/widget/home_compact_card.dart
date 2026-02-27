import 'package:flutter/material.dart';
import 'package:keepset/theme/keepset_colors.dart';

import '../model/block.dart';
import '../model/note.dart';

class HomeCompactCard extends StatelessWidget {
  final Note note;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final Widget? trailing;

  const HomeCompactCard({
    super.key,
    required this.note,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: KeepsetColors.layer1,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: KeepsetColors.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: KeepsetColors.textPrimary.withValues(alpha: 0.5),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              Text(
                _extractPreview(note.blocks),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: KeepsetColors.textPrimary.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  GestureDetector(
                    onTap: onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      'Open',
                      style: TextStyle(
                        color: KeepsetColors.layer2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Block-safe, DB-v1-correct preview extractor
  String _extractPreview(List<Block> blocks) {
    final lines = <String>[];

    for (final block in blocks) {
      _appendFromBlock(block, lines);
      if (lines.length >= 3) break;
    }

    return lines.join('\n');
  }

  void _appendFromBlock(Block block, List<String> buffer) {
    if (block is TextBlock) {
      _appendText(block.text, buffer);
      return;
    }

    if (block is ChecklistBlock) {
      _appendChecklist(block.items, buffer);
      return;
    }
  }

  void _appendText(String text, List<String> buffer) {
    final value = text.trim();
    if (value.isNotEmpty) {
      buffer.add(value);
    }
  }

  void _appendChecklist(List<ChecklistItem> items, List<String> buffer) {
    for (final item in items) {
      if (buffer.length >= 3) return;

      final value = item.text.trim();
      if (value.isNotEmpty) {
        buffer.add('• $value');
      }
    }
  }
}
