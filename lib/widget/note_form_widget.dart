import 'package:flutter/material.dart';

import '../theme/keepset_colors.dart';

class NoteFormWidget extends StatelessWidget {
  final String title;
  final String description;
  final ValueChanged<String> onChangedTitle;
  final ValueChanged<String> onChangedDescription;

  const NoteFormWidget({
    super.key,
    required this.title,
    required this.description,
    required this.onChangedTitle,
    required this.onChangedDescription,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titleField(),
          const SizedBox(height: 16),
          _bodyField(),
        ],
      ),
    );
  }

  Widget _titleField() {
    return TextFormField(
      initialValue: title,
      style: TextStyle(
        color: KeepsetColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Title',
        hintStyle: TextStyle(
          color: KeepsetColors.textMuted,
          fontSize: 26,
        ),
        border: InputBorder.none,
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
      onChanged: onChangedTitle,
    );
  }

  Widget _bodyField() {
    return TextFormField(
      initialValue: description,
      maxLines: null,
      style: TextStyle(
        color: KeepsetColors.textSecondary,
        fontSize: 17,
        height: 1.45,
      ),
      decoration: InputDecoration(
        hintText:
            'Write freely.\n\nUse:\n• "- " for checklists\n• "# " for sections',
        hintStyle: TextStyle(
          color: KeepsetColors.textMuted,
          height: 1.5,
        ),
        border: InputBorder.none,
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Note cannot be empty' : null,
      onChanged: onChangedDescription,
    );
  }
}
