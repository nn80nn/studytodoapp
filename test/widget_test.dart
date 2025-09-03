import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytodoapp/main.dart';

void main() {
  testWidgets('StudyTodo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(StudyTodoApp());

    // Verify that our app displays the title.
    expect(find.text('StudyTodo'), findsOneWidget);
  });
}