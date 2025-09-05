import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    createdAt: _parseDateTime(json['createdAt']),
  );

  static DateTime _parseDateTime(dynamic dateTime) {
    try {
      if (dateTime is Timestamp) {
        return dateTime.toDate();
      } else if (dateTime is int) {
        // Проверка на разумные границы для предотвращения переполнения
        if (dateTime < 0 || dateTime > 4102444800000) { // 1 января 2100
          return DateTime.now();
        }
        return DateTime.fromMillisecondsSinceEpoch(dateTime);
      } else if (dateTime is String) {
        return DateTime.parse(dateTime);
      }
    } catch (e) {
      // В случае ошибки парсинга возвращаем текущее время
      return DateTime.now();
    }
    return DateTime.now();
  }
}