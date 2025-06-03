import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'section_model.g.dart';

/// Section model representing content sections in the BAG Wiki
@JsonSerializable()
class Section {
  /// Unique identifier for the section
  final int? id;
  
  /// Title of the section
  final String title;
  
  /// Content text of the section
  final String content;
  
  /// URL to the section's image
  @JsonKey(name: 'imageUrl')
  final String imageUrl;
  
  /// Creation timestamp
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;
  
  /// Last update timestamp
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;
  
  /// Constructor
  Section({
    this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });
  
  /// Create a Section from JSON
  factory Section.fromJson(Map<String, dynamic> json) => _$SectionFromJson(json);
  
  /// Convert Section to JSON
  Map<String, dynamic> toJson() => _$SectionToJson(this);
  
  /// Create a Section from a database row
  factory Section.fromDatabase(Map<String, dynamic> row) {
    return Section(
      id: row['id'] as int,
      title: row['title'] as String,
      content: row['content'] as String,
      imageUrl: row['imageUrl'] as String,
      createdAt: row['createdAt'] != null ? DateTime.parse(row['createdAt'].toString()) : null,
      updatedAt: row['updatedAt'] != null ? DateTime.parse(row['updatedAt'].toString()) : null,
    );
  }
  
  /// Convert Section to a database row
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
    };
  }
  
  /// Create a copy of this Section with modified fields
  Section copyWith({
    int? id,
    String? title,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Section(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  String toString() {
    return 'Section{id: $id, title: $title, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}..., imageUrl: $imageUrl}';
  }
}
