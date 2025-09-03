import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytodoapp/models/subject.dart';

void main() {
  group('Subject Model Tests', () {
    final DateTime testCreatedAt = DateTime(2024, 3, 1);
    const Color testColor = Color(0xFF26C6DA);

    Subject createTestSubject() {
      return Subject(
        id: 'test_subject_id',
        name: 'Математика',
        color: testColor,
        description: 'Изучение высшей математики',
        createdAt: testCreatedAt,
      );
    }

    test('should create Subject with required fields only', () {
      final subject = Subject(
        id: 'test_subject_id',
        name: 'Физика',
        color: Colors.blue,
        createdAt: testCreatedAt,
      );

      expect(subject.id, 'test_subject_id');
      expect(subject.name, 'Физика');
      expect(subject.color, Colors.blue);
      expect(subject.description, isNull);
      expect(subject.createdAt, testCreatedAt);
    });

    test('should create Subject with all fields', () {
      final subject = createTestSubject();

      expect(subject.id, 'test_subject_id');
      expect(subject.name, 'Математика');
      expect(subject.color, testColor);
      expect(subject.description, 'Изучение высшей математики');
      expect(subject.createdAt, testCreatedAt);
    });

    test('should convert to JSON correctly', () {
      final subject = createTestSubject();
      final json = subject.toJson();

      expect(json['id'], 'test_subject_id');
      expect(json['name'], 'Математика');
      expect(json['color'], testColor.value);
      expect(json['description'], 'Изучение высшей математики');
      expect(json['createdAt'], testCreatedAt.millisecondsSinceEpoch);
    });

    test('should convert to JSON with null description', () {
      final subject = Subject(
        id: 'test_subject_id',
        name: 'Химия',
        color: Colors.green,
        createdAt: testCreatedAt,
      );
      final json = subject.toJson();

      expect(json['id'], 'test_subject_id');
      expect(json['name'], 'Химия');
      expect(json['color'], Colors.green.value);
      expect(json['description'], isNull);
      expect(json['createdAt'], testCreatedAt.millisecondsSinceEpoch);
    });

    test('should create Subject from JSON correctly', () {
      final json = {
        'id': 'test_subject_id',
        'name': 'Математика',
        'color': testColor.value,
        'description': 'Изучение высшей математики',
        'createdAt': testCreatedAt.millisecondsSinceEpoch,
      };

      final subject = Subject.fromJson(json);

      expect(subject.id, 'test_subject_id');
      expect(subject.name, 'Математика');
      expect(subject.color, testColor);
      expect(subject.description, 'Изучение высшей математики');
      expect(subject.createdAt, testCreatedAt);
    });

    test('should create Subject from JSON with null description', () {
      final json = {
        'id': 'test_subject_id',
        'name': 'История',
        'color': Colors.red.value,
        'description': null,
        'createdAt': testCreatedAt.millisecondsSinceEpoch,
      };

      final subject = Subject.fromJson(json);

      expect(subject.id, 'test_subject_id');
      expect(subject.name, 'История');
      expect(subject.color.value, Colors.red.value);
      expect(subject.description, isNull);
      expect(subject.createdAt, testCreatedAt);
    });

    test('should handle different color values in JSON', () {
      final colorValues = [
        Colors.red.value,
        Colors.blue.value,
        Colors.green.value,
        0xFF123456,
        0xFFFFFFFF,
        0xFF000000,
      ];

      for (final colorValue in colorValues) {
        final json = {
          'id': 'test_id',
          'name': 'Test Subject',
          'color': colorValue,
          'createdAt': testCreatedAt.millisecondsSinceEpoch,
        };

        final subject = Subject.fromJson(json);
        expect(subject.color.value, colorValue);
      }
    });

    test('should serialize and deserialize correctly (round trip)', () {
      final originalSubject = createTestSubject();
      final json = originalSubject.toJson();
      final deserializedSubject = Subject.fromJson(json);

      expect(deserializedSubject.id, originalSubject.id);
      expect(deserializedSubject.name, originalSubject.name);
      expect(deserializedSubject.color.value, originalSubject.color.value);
      expect(deserializedSubject.description, originalSubject.description);
      expect(deserializedSubject.createdAt, originalSubject.createdAt);
    });

    test('should serialize and deserialize with null description (round trip)', () {
      final originalSubject = Subject(
        id: 'test_id',
        name: 'Test Subject',
        color: Colors.purple,
        createdAt: testCreatedAt,
      );
      final json = originalSubject.toJson();
      final deserializedSubject = Subject.fromJson(json);

      expect(deserializedSubject.id, originalSubject.id);
      expect(deserializedSubject.name, originalSubject.name);
      expect(deserializedSubject.color.value, originalSubject.color.value);
      expect(deserializedSubject.description, originalSubject.description);
      expect(deserializedSubject.createdAt, originalSubject.createdAt);
    });

    test('should handle edge cases in color values', () {
      final edgeCaseColors = [
        0x00000000, // Transparent
        0xFFFFFFFF, // White
        0xFF000000, // Black
        0x80FF0000, // Semi-transparent red
      ];

      for (final colorValue in edgeCaseColors) {
        final subject = Subject(
          id: 'test_id',
          name: 'Test',
          color: Color(colorValue),
          createdAt: testCreatedAt,
        );

        final json = subject.toJson();
        final deserializedSubject = Subject.fromJson(json);

        expect(deserializedSubject.color.value, colorValue);
      }
    });
  });
}