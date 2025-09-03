import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final Color color;
  final String? description;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'description': description,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'],
    name: json['name'],
    color: Color(json['color']),
    description: json['description'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
  );
}