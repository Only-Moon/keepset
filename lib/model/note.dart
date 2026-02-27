import 'block.dart';

final String tableNotes = 'notes';

class NoteFields {
  static const String id = '_id';
  static const String title = 'title';
  static const String blocks = 'blocks';
  static const String time = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String lifecycle = 'lifecycle_state';
  static const String disableAutoDone = 'disable_auto_done';
}

enum LifecycleState {
  active,
  done,
  archived,
}

class Note {
  final int? id;
  final String title;
  final List<Block> blocks;
  final DateTime createdTime;
  final DateTime updatedAt;
  final LifecycleState lifecycleState;

  /// If true, checklist completion will NOT auto-move lifecycle
  final bool disableAutoDone;

  const Note({
    this.id,
    required this.title,
    required this.blocks,
    required this.createdTime,
    required this.updatedAt,
    this.lifecycleState = LifecycleState.active,
    this.disableAutoDone = false,
  });

  Note copy({
    int? id,
    String? title,
    List<Block>? blocks,
    DateTime? createdTime,
    DateTime? updatedAt,
    LifecycleState? lifecycleState,
    bool? disableAutoDone,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      blocks: blocks ?? this.blocks,
      createdTime: createdTime ?? this.createdTime,
      updatedAt: updatedAt ?? this.updatedAt,
      lifecycleState: lifecycleState ?? this.lifecycleState,
      disableAutoDone: disableAutoDone ?? this.disableAutoDone,
    );
  }

  // ───────────────── JSON

  static Note fromJson(Map<String, Object?> json) {
    final rawBlocks = json[NoteFields.blocks] as String?;

    return Note(
      id: json[NoteFields.id] as int?,
      title: json[NoteFields.title] as String,
      blocks: rawBlocks == null || rawBlocks.isEmpty
          ? <Block>[]
          : Block.listFromJson(rawBlocks),
      createdTime: DateTime.parse(json[NoteFields.time] as String),
      updatedAt: DateTime.parse(json[NoteFields.updatedAt] as String),
      lifecycleState: LifecycleState.values.firstWhere(
        (e) => e.name.toUpperCase() == json[NoteFields.lifecycle],
        orElse: () => LifecycleState.active,
      ),
      disableAutoDone: (json[NoteFields.disableAutoDone] as int) == 1,
    );
  }

  Map<String, Object?> toJson() {
    return {
      NoteFields.id: id,
      NoteFields.title: title,
      NoteFields.blocks: Block.listToJson(blocks),
      NoteFields.time: createdTime.toIso8601String(),
      NoteFields.updatedAt: updatedAt.toIso8601String(),
      NoteFields.lifecycle: lifecycleState.name.toUpperCase(),
      NoteFields.disableAutoDone: disableAutoDone ? 1 : 0,
    };
  }
}
