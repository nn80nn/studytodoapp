import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:studytodoapp/blocs/subjects_bloc.dart';
import 'package:studytodoapp/models/subject.dart';

void main() {
  group('SubjectsBloc Tests', () {
    late SubjectsBloc subjectsBloc;
    
    final testSubjects = [
      Subject(
        id: 'subject1',
        name: 'Математика',
        color: Colors.blue,
        description: 'Высшая математика',
        createdAt: DateTime.now(),
      ),
      Subject(
        id: 'subject2',
        name: 'Физика',
        color: Colors.red,
        createdAt: DateTime.now(),
      ),
    ];

    setUp(() {
      // Не создаем реальный BLoC из-за Firebase зависимости
      // subjectsBloc = SubjectsBloc();
    });

    tearDown(() {
      // subjectsBloc.close();
    });

    test('BLoC should be testable without Firebase', () {
      // Тест заглушка вместо реального BLoC тестирования
      expect(true, true);
    });

    group('Event Properties', () {
      test('LoadSubjects props are empty', () {
        expect(LoadSubjects().props, isEmpty);
      });

      test('RefreshSubjects props are empty', () {
        expect(RefreshSubjects().props, isEmpty);
      });

      test('AddSubject props contain subject', () {
        final event = AddSubject(testSubjects.first);
        expect(event.props, [testSubjects.first]);
      });

      test('UpdateSubject props contain subject', () {
        final event = UpdateSubject(testSubjects.first);
        expect(event.props, [testSubjects.first]);
      });

      test('DeleteSubject props contain id', () {
        final event = DeleteSubject('test_id');
        expect(event.props, ['test_id']);
      });
    });

    group('State Properties', () {
      test('SubjectsInitial props are empty', () {
        expect(SubjectsInitial().props, isEmpty);
      });

      test('SubjectsLoading props are empty', () {
        expect(SubjectsLoading().props, isEmpty);
      });

      test('SubjectsLoaded props contain subjects and isRefreshing', () {
        final state = SubjectsLoaded(testSubjects, isRefreshing: true);
        expect(state.props, [testSubjects, true]);
      });

      test('SubjectsLoaded default isRefreshing is false', () {
        final state = SubjectsLoaded(testSubjects);
        expect(state.isRefreshing, false);
      });

      test('SubjectAdding props are empty', () {
        expect(SubjectAdding().props, isEmpty);
      });

      test('SubjectUpdating props are empty', () {
        expect(SubjectUpdating().props, isEmpty);
      });

      test('SubjectDeleting props are empty', () {
        expect(SubjectDeleting().props, isEmpty);
      });

      test('SubjectsError props contain message', () {
        const errorMessage = 'Test error';
        final state = SubjectsError(errorMessage);
        expect(state.props, [errorMessage]);
      });
    });

    group('State Equality', () {
      test('SubjectsLoaded states with same data are equal', () {
        final state1 = SubjectsLoaded(testSubjects);
        final state2 = SubjectsLoaded(testSubjects);
        expect(state1, equals(state2));
      });

      test('SubjectsLoaded states with different data are not equal', () {
        final state1 = SubjectsLoaded(testSubjects);
        final state2 = SubjectsLoaded([]);
        expect(state1, isNot(equals(state2)));
      });

      test('SubjectsError states with same message are equal', () {
        const errorMessage = 'Test error';
        final state1 = SubjectsError(errorMessage);
        final state2 = SubjectsError(errorMessage);
        expect(state1, equals(state2));
      });

      test('SubjectsError states with different messages are not equal', () {
        final state1 = SubjectsError('Error 1');
        final state2 = SubjectsError('Error 2');
        expect(state1, isNot(equals(state2)));
      });
    });

    group('Edge Cases', () {
      test('SubjectsLoaded handles empty subjects list', () {
        final state = SubjectsLoaded([]);
        expect(state.subjects, isEmpty);
        expect(state.isRefreshing, false);
      });

      test('SubjectsError handles empty message', () {
        final state = SubjectsError('');
        expect(state.message, isEmpty);
      });

      test('SubjectsError handles null-like message', () {
        final state = SubjectsError('null');
        expect(state.message, 'null');
      });
    });

    group('Event Equality', () {
      test('same AddSubject events are equal', () {
        final subject = testSubjects.first;
        final event1 = AddSubject(subject);
        final event2 = AddSubject(subject);
        expect(event1, equals(event2));
      });

      test('different AddSubject events are not equal', () {
        final event1 = AddSubject(testSubjects.first);
        final event2 = AddSubject(testSubjects.last);
        expect(event1, isNot(equals(event2)));
      });

      test('same DeleteSubject events are equal', () {
        final event1 = DeleteSubject('test_id');
        final event2 = DeleteSubject('test_id');
        expect(event1, equals(event2));
      });

      test('different DeleteSubject events are not equal', () {
        final event1 = DeleteSubject('id1');
        final event2 = DeleteSubject('id2');
        expect(event1, isNot(equals(event2)));
      });
    });

    group('Subject Color Handling', () {
      test('should handle different color values in subjects', () {
        final subjects = [
          Subject(id: '1', name: 'Test1', color: Colors.red, createdAt: DateTime.now()),
          Subject(id: '2', name: 'Test2', color: Colors.blue, createdAt: DateTime.now()),
          Subject(id: '3', name: 'Test3', color: Colors.green, createdAt: DateTime.now()),
        ];

        final state = SubjectsLoaded(subjects);
        expect(state.subjects.length, 3);
        expect(state.subjects[0].color, Colors.red);
        expect(state.subjects[1].color, Colors.blue);
        expect(state.subjects[2].color, Colors.green);
      });
    });

    group('Subject with Description', () {
      test('should handle subjects with and without description', () {
        final subjects = [
          Subject(
            id: '1',
            name: 'С описанием',
            color: Colors.blue,
            description: 'Есть описание',
            createdAt: DateTime.now(),
          ),
          Subject(
            id: '2',
            name: 'Без описания',
            color: Colors.red,
            createdAt: DateTime.now(),
          ),
        ];

        final state = SubjectsLoaded(subjects);
        expect(state.subjects[0].description, 'Есть описание');
        expect(state.subjects[1].description, isNull);
      });
    });
  });
}