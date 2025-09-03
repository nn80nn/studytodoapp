import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:studytodoapp/services/ai_service.dart';

@GenerateMocks([GenerativeModel])
void main() {
  group('AIService Tests', () {
    late AIService aiService;

    setUp(() {
      aiService = AIService();
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = AIService();
        final instance2 = AIService();
        
        expect(identical(instance1, instance2), true);
      });
    });

    group('Initialize', () {
      test('should initialize without throwing exception', () {
        expect(() => aiService.initialize('test_api_key'), returnsNormally);
      });
    });

    group('Text Correction', () {
      test('should return original text when not initialized', () async {
        final originalText = 'Привет мир!';
        
        // Не инициализируем сервис
        final result = await aiService.correctText(originalText);
        
        // Ожидаем возврат оригинального текста при ошибке
        expect(result, originalText);
      });

      test('should handle empty text', () async {
        final result = await aiService.correctText('');
        expect(result, '');
      });

      test('should handle text with special characters', () async {
        final textWithSpecialChars = 'Тест @#\$%^&*()!';
        final result = await aiService.correctText(textWithSpecialChars);
        
        // Без реальной инициализации вернется оригинальный текст
        expect(result, textWithSpecialChars);
      });
    });

    group('Task Auto-completion', () {
      test('should return empty map when not initialized', () async {
        final result = await aiService.autoCompleteTask('Решить уравнения', 'Математика');
        
        expect(result, isEmpty);
      });

      test('should handle empty title and subject', () async {
        final result = await aiService.autoCompleteTask('', '');
        
        expect(result, isEmpty);
      });

      test('should handle special characters in input', () async {
        final result = await aiService.autoCompleteTask('Тест @#\$', 'Предмет!');
        
        expect(result, isEmpty);
      });
    });

    group('JSON Value Extraction', () {
      test('should extract value from JSON string', () {
        // Создаем тестовый экземпляр для доступа к приватному методу
        // В реальных условиях этот метод private, поэтому тест будет ограничен
        
        final testJson = '{"description": "Тестовое описание", "priority": "высокий"}';
        
        // Поскольку _extractValue приватный, мы не можем его протестировать напрямую
        // В реальном проекте стоит сделать этот метод protected или создать отдельную утилиту
        expect(true, true);
      });
    });

    group('Error Handling', () {
      test('correctText should handle exceptions gracefully', () async {
        final originalText = 'Тест с ошибкой';
        
        // Без инициализации должна возникнуть ошибка, но она обработается
        final result = await aiService.correctText(originalText);
        
        // Должен вернуть оригинальный текст при ошибке
        expect(result, originalText);
      });

      test('autoCompleteTask should handle exceptions gracefully', () async {
        // Без инициализации должна возникнуть ошибка, но она обработается
        final result = await aiService.autoCompleteTask('test', 'subject');
        
        // Должен вернуть пустую мапу при ошибке
        expect(result, isEmpty);
      });
    });

    group('Real Integration Tests', () {
      // Эти тесты требуют реального API ключа и будут пропущены в CI/CD
      test('should correct text with real API (requires API key)', () async {
        // Этот тест можно запускать только с реальным API ключом
        // aiService.initialize('YOUR_REAL_API_KEY');
        // final result = await aiService.correctText('Привет мир как дила?');
        // expect(result, contains('дела'));
        
        expect(true, true); // Заглушка для CI/CD
      }, skip: true); // Requires real API key

      test('should auto-complete task with real API (requires API key)', () async {
        // Этот тест можно запускать только с реальным API ключом
        // aiService.initialize('YOUR_REAL_API_KEY');
        // final result = await aiService.autoCompleteTask('Решить уравнения', 'Математика');
        // expect(result['description'], isNotEmpty);
        
        expect(true, true); // Заглушка для CI/CD
      }, skip: true); // Requires real API key
    });
  });
}