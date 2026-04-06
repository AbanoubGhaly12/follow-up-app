import 'package:equatable/equatable.dart';

enum TemplateType { birthday, marriage, condolences, generic }

class TemplateModel extends Equatable {
  final String id;
  final String title;
  final TemplateType type;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateModel({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, title, type, content, createdAt, updatedAt];

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    return TemplateModel(
      id: map['id'] as String,
      title: map['title'] as String,
      type: TemplateType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TemplateModel copyWith({
    String? id,
    String? title,
    TemplateType? type,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
