import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'section_model.g.dart';

@JsonSerializable()
class Section {
  final int? id;
  final String title;
  final String content;
  
  @JsonKey(name: 'imageUrl')
  final String imageUrl;
  
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;
  
  Section({
    this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Section.fromJson(Map<String, dynamic> json) => _$SectionFromJson(json);
  Map<String, dynamic> toJson() => _$SectionToJson(this);
}
