import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late final GenerativeModel _model;

  void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  Future<String> correctText(String text) async {
    try {
      final prompt = '''
Исправь орфографические и грамматические ошибки в следующем тексте, сохраняя его смысл:
"$text"

Верни только исправленный текст без дополнительных комментариев.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text?.trim() ?? text;
    } catch (e) {
      return text; // Возвращаем оригинальный текст при ошибке
    }
  }

  Future<Map<String, String>> autoCompleteTask(String title, String subjectName) async {
    try {
      final prompt = '''
Для предмета "$subjectName" и задачи с названием "$title" предложи:
1. Подробное описание (что нужно сделать)
2. Примерное время выполнения
3. Приоритет (низкий/средний/высокий)

Ответь в формате JSON:
{
  "description": "описание задачи",
  "estimatedTime": "время в часах",
  "priority": "приоритет"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      // Простое парсинг JSON из ответа
      final text = response.text ?? '';
      return {
        'description': _extractValue(text, 'description'),
        'estimatedTime': _extractValue(text, 'estimatedTime'),
        'priority': _extractValue(text, 'priority'),
      };
    } catch (e) {
      return {};
    }
  }

  String _extractValue(String text, String key) {
    final regex = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = regex.firstMatch(text);
    return match?.group(1) ?? '';
  }
}