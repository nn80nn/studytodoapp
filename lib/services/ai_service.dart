import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  GenerativeModel? _model;
  
  bool get isInitialized => _model != null;

  void initialize(String? apiKey) {
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
      );
    } else {
      _model = null;
    }
  }

  Future<String> correctText(String text) async {
    if (_model == null) return text;
    
    try {
      final prompt = '''
Исправь орфографические и грамматические ошибки в следующем тексте, сохраняя его смысл:
"$text"

Верни только исправленный текст без дополнительных комментариев.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim() ?? text;
    } catch (e) {
      return text; // Возвращаем оригинальный текст при ошибке
    }
  }

  Future<Map<String, String>> autoCompleteTask(String title, String subjectName) async {
    if (_model == null) return {};
    
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
      final response = await _model!.generateContent(content);
      
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

  Future<String> improveTaskDescription(String description, String taskTitle, String subjectName) async {
    if (_model == null) return description;
    
    try {
      final prompt = '''
Улучши описание учебной задачи с учётом всего контекста:

Предмет: "$subjectName"
Название задачи: "$taskTitle"
Текущее описание: "$description"

Твоя задача:
1. Исправить орфографические и грамматические ошибки
2. Улучшить структуру и читаемость текста
3. Добавить конкретные шаги или подзадачи если это уместно
4. Сделать описание более подробным и полезным для студента
5. Учесть контекст предмета и названия задачи
6. Сохранить основной смысл и содержание

Верни только улучшенное описание без дополнительных комментариев и объяснений.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim() ?? description;
    } catch (e) {
      return description;
    }
  }

  Future<String> improveSubjectDescription(String description, String subjectName) async {
    if (_model == null) return description;
    
    try {
      final prompt = '''
Улучши описание учебного предмета:

Название предмета: "$subjectName"
Текущее описание: "$description"

Твоя задача:
1. Исправить орфографические и грамматические ошибки
2. Сделать описание более информативным и полезным
3. Добавить краткую информацию о том, что изучается в этом предмете
4. Структурировать текст для лучшего восприятия
5. Сохранить основной смысл и содержание

Верни только улучшенное описание без дополнительных комментариев и объяснений.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim() ?? description;
    } catch (e) {
      return description;
    }
  }

  String _extractValue(String text, String key) {
    final regex = RegExp('"$key"\\s*:\\s*"([^"]*)"');
    final match = regex.firstMatch(text);
    return match?.group(1) ?? '';
  }
}