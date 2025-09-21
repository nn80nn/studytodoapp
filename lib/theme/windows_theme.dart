import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindowsTheme {
  // Windows 11 Colors
  static const Color _primaryBlue = Color(0xFF0078D4);
  static const Color _accentBlue = Color(0xFF106EBE);
  static const Color _lightBlue = Color(0xFF40E0FF);

  static const Color _systemGray = Color(0xFFF3F3F3);
  static const Color _cardGray = Color(0xFFFAFAFA);
  static const Color _borderGray = Color(0xFFE5E5E5);
  static const Color _textGray = Color(0xFF323130);

  static const Color _darkGray = Color(0xFF202020);
  static const Color _darkCardGray = Color(0xFF2D2D2D);
  static const Color _darkBorderGray = Color(0xFF404040);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Цветовая схема Windows 11
      colorScheme: const ColorScheme.light(
        primary: _primaryBlue,
        secondary: _accentBlue,
        tertiary: _lightBlue,
        surface: _systemGray,
        surfaceContainerHighest: _cardGray,
        onSurface: _textGray,
        outline: _borderGray,
        background: Colors.white,
      ),

      // Шрифты Windows (default sans-serif)
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
      ),

      // Windows-стиль карточек с легкими тенями
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _borderGray, width: 0.5),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),

      // Современные AppBar в стиле Windows
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _textGray,
        centerTitle: false, // Windows-style left alignment
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        toolbarHeight: 48,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),

      // Windows-стиль кнопок
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Segoe UI',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryBlue,
          side: const BorderSide(color: _primaryBlue, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Segoe UI',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Segoe UI',
          ),
        ),
      ),

      // Windows-стиль полей ввода
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: _borderGray, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: _borderGray, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: _primaryBlue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        labelStyle: TextStyle(
          fontSize: 14,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
      ),

      // Современные диалоги
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
      ),

      // Windows-стиль списков
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _textGray,
          fontFamily: 'Segoe UI',
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: Color(0x80323130),
          fontFamily: 'Segoe UI',
        ),
      ),

      // Чекбоксы и радиокнопки
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryBlue;
          }
          return Colors.transparent;
        }),
      ),

      // Слайдеры
      sliderTheme: const SliderThemeData(
        activeTrackColor: _primaryBlue,
        inactiveTrackColor: _borderGray,
        thumbColor: _primaryBlue,
      ),

      // Скроллбары
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(_borderGray),
        trackColor: WidgetStateProperty.all(_systemGray),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(4),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: _lightBlue,
        secondary: _primaryBlue,
        tertiary: _accentBlue,
        surface: _darkGray,
        surfaceContainerHighest: _darkCardGray,
        onSurface: Colors.white,
        outline: _darkBorderGray,
        background: Color(0xFF1A1A1A),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: Colors.white,
          fontFamily: 'Segoe UI',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          fontFamily: 'Segoe UI',
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _darkBorderGray, width: 0.5),
        ),
        color: _darkCardGray,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: _darkGray,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Segoe UI',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightBlue,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
    );
  }

  // Дополнительные цвета для приложения
  static const Color successGreen = Color(0xFF107C10);
  static const Color warningYellow = Color(0xFFFFB900);
  static const Color errorRed = Color(0xFFD13438);

  // Приоритеты задач в Windows-стиле
  static const Color highPriority = Color(0xFFD13438);    // Красный
  static const Color mediumPriority = Color(0xFFFFB900);  // Желтый
  static const Color lowPriority = Color(0xFF107C10);     // Зеленый

  // Статусы задач
  static const Color pendingStatus = Color(0xFF605E5C);   // Серый
  static const Color progressStatus = Color(0xFF0078D4);  // Синий
  static const Color completedStatus = Color(0xFF107C10); // Зеленый
}

// Кастомные виджеты для Windows
class WindowsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const WindowsCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class WindowsButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;

  const WindowsButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
        label: Text(text),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
        label: Text(text),
      );
    }
  }
}