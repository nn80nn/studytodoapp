import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Subject extends Equatable {
  final String id;
  final String userId;
  final String name;
  final int color; // Color.value
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  const Subject({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        color,
        description,
        createdAt,
        updatedAt,
        isDeleted,
        deletedAt,
      ];

  Subject copyWith({
    String? id,
    String? userId,
    String? name,
    int? color,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'color': color,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDeleted': isDeleted ? 1 : 0,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      color: json['color'] as int,
      description: json['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      isDeleted: (json['isDeleted'] as int) == 1,
      deletedAt: json['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt'] as int)
          : null,
    );
  }

  // Для совместимости с Firebase (когда нужно)
  factory Subject.fromFirestore(Map<String, dynamic> data) {
    return Subject.fromJson(data);
  }

  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  Color get colorValue => Color(color);

  String get abbreviation => name.isNotEmpty ? name[0].toUpperCase() : '?';

  // Предустановленные цвета для предметов
  static const List<Color> predefinedColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFF44336), // Red
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF009688), // Teal
    Color(0xFFCDDC39), // Lime
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF827717), // Olive
    Color(0xFF880E4F), // Dark Pink
    Color(0xFF1A237E), // Dark Blue
  ];

  static Color getRandomColor() {
    return predefinedColors[
        DateTime.now().millisecondsSinceEpoch % predefinedColors.length];
  }
}