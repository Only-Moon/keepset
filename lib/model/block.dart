import 'dart:convert';

/// ─────────────────────────────────────────
/// Block base
/// ─────────────────────────────────────────

abstract class Block {
  String get type;
  Map<String, dynamic> toJson();

  static Block fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case TextBlock.typeConst:
        return TextBlock.fromJson(json);
      case ChecklistBlock.typeConst:
        return ChecklistBlock.fromJson(json);
      case SectionBlock.typeConst:
        return SectionBlock.fromJson(json);
      case ImageRefBlock.typeConst:
        return ImageRefBlock.fromJson(json);
      case LinkRefBlock.typeConst:
        return LinkRefBlock.fromJson(json);
      default:
        throw UnsupportedError('Unknown block type: ${json['type']}');
    }
  }

  static List<Block> listFromJson(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Block.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static String listToJson(List<Block> blocks) {
    return jsonEncode(blocks.map((b) => b.toJson()).toList());
  }
}

/// ─────────────────────────────────────────
/// TextBlock
/// ─────────────────────────────────────────

class TextBlock extends Block {
  static const String typeConst = 'text';

  @override
  String get type => typeConst;

  final String text;

  TextBlock({required this.text});

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(text: json['text'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
      };
}

/// ─────────────────────────────────────────
/// ChecklistBlock
/// ─────────────────────────────────────────

class ChecklistItem {
  final String text;
  final bool checked;

  ChecklistItem({
    required this.text,
    required this.checked,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      text: json['text'] as String,
      checked: json['checked'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'checked': checked,
      };
}

class ChecklistBlock extends Block {
  static const String typeConst = 'checklist';

  @override
  String get type => typeConst;

  final List<ChecklistItem> items;

  ChecklistBlock({required this.items});

  factory ChecklistBlock.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>;
    return ChecklistBlock(
      items: raw
          .map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

/// ─────────────────────────────────────────
/// SectionBlock
/// ─────────────────────────────────────────

class SectionBlock extends Block {
  static const String typeConst = 'section';

  @override
  String get type => typeConst;

  final String title;

  SectionBlock({required this.title});

  factory SectionBlock.fromJson(Map<String, dynamic> json) {
    return SectionBlock(title: json['title'] as String);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
      };
}

/// ─────────────────────────────────────────
/// ImageRefBlock
/// ─────────────────────────────────────────

class ImageRefBlock extends Block {
  static const String typeConst = 'image';

  @override
  String get type => typeConst;

  final String uri;
  final String? caption;

  ImageRefBlock({
    required this.uri,
    this.caption,
  });

  factory ImageRefBlock.fromJson(Map<String, dynamic> json) {
    return ImageRefBlock(
      uri: json['uri'] as String,
      caption: json['caption'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'uri': uri,
        if (caption != null) 'caption': caption,
      };
}

/// ─────────────────────────────────────────
/// LinkRefBlock
/// ─────────────────────────────────────────

class LinkRefBlock extends Block {
  static const String typeConst = 'link';

  @override
  String get type => typeConst;

  final String url;
  final String? title;
  final String? subtitle;

  LinkRefBlock({
    required this.url,
    this.title,
    this.subtitle,
  });

  factory LinkRefBlock.fromJson(Map<String, dynamic> json) {
    return LinkRefBlock(
      url: json['url'] as String,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
      };
}
