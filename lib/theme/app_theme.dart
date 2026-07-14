import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light([Color? accentColor]) => _build(
    brightness: Brightness.light,
    bg: const Color(0xFFEEF2FF), // soft lavender
    surface: Colors.white,
    navBg: const Color(0xFF6D28D9), // deep purple sidebar
    navFg: Colors.white,
    border: const Color(0xFFE5E7EB),
    text: const Color(0xFF1E1B4B), // dark navy
    subtext: const Color(0xFF6B7280),
    accent: accentColor ?? const Color(0xFF7C3AED), // violet
  );

  static ThemeData dark([Color? accentColor]) => _build(
    brightness: Brightness.dark,
    bg: const Color(0xFF0D0B1A), // very dark violet
    surface: const Color(0xFF16132B), // dark purple-tinted
    navBg: const Color(0xFF1A1733), // dark purple sidebar
    navFg: Colors.white,
    border: const Color(0xFF2E2A4A),
    text: const Color(0xFFE2E8F0),
    subtext: const Color(0xFF94A3B8),
    accent: accentColor ?? const Color(0xFF8B5CF6), // lighter violet for dark
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color navBg,
    required Color navFg,
    required Color border,
    required Color text,
    required Color subtext,
    required Color accent,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: subtext,
        onSecondary: bg,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: surface,
        onSurface: text,
        outline: border,
        outlineVariant: border.withValues(alpha: 0.5),
        tertiary: subtext,
        onTertiary: bg,
        primaryContainer: accent.withValues(alpha: 0.15),
        onPrimaryContainer: accent,
        secondaryContainer: surface,
        onSecondaryContainer: text,
        surfaceContainerHighest: isDark
            ? const Color(0xFF201D3B)
            : const Color(0xFFF3F0FF),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: subtext, size: 20),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: subtext,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navBg,
        selectedIconTheme: IconThemeData(color: navFg, size: 20),
        unselectedIconTheme: IconThemeData(
          color: navFg.withValues(alpha: 0.55),
          size: 20,
        ),
        selectedLabelTextStyle: TextStyle(
          color: navFg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: navFg.withValues(alpha: 0.55),
          fontSize: 11,
        ),
        indicatorColor: navFg.withValues(alpha: 0.15),
        useIndicator: true,
        minWidth: 68,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 0),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent.withValues(alpha: 0.12),
        disabledColor: surface,
        labelStyle: TextStyle(fontSize: 12, color: text),
        secondaryLabelStyle: TextStyle(
          fontSize: 12,
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: TextStyle(color: subtext, fontSize: 13),
        hintStyle: TextStyle(color: subtext, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: text, fontSize: 14),
        bodyMedium: TextStyle(color: text, fontSize: 13),
        bodySmall: TextStyle(color: subtext, fontSize: 12),
        titleLarge: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(color: subtext, fontSize: 12),
        labelSmall: TextStyle(color: subtext, fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: subtext, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 8,
        shadowColor: accent.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 0.5),
        ),
        textStyle: TextStyle(color: text, fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(0, 36),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.5)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(0, 36),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: subtext),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? const Color(0xFF4A4670) : const Color(0xFFCBD5E1);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return isDark ? const Color(0xFF2E2A4A) : const Color(0xFFE2E8F0);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        side: BorderSide(color: border, width: 1.5),
      ),
    );
  }

  // ── Status colors ─────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'ongoing':
        return const Color(0xFF7C3AED); // violet
      case 'finished':
        return const Color(0xFF10B981); // emerald
      case 'dropped':
        return const Color(0xFFEF4444); // red
      case 'not started':
        return const Color(0xFF6B7280); // gray
      default:
        return const Color(0xFF6B7280);
    }
  }

  // ── Category colors (hash-stable) ─────────────────────────────
  static const _categoryPalette = [
    Color(0xFF8B5CF6), // violet
    Color(0xFF6366F1), // indigo
    Color(0xFF3B82F6), // blue
    Color(0xFF06B6D4), // cyan
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFFEC4899), // pink
  ];

  static Color categoryColor(String category) {
    final index =
        category.toLowerCase().hashCode.abs() % _categoryPalette.length;
    return _categoryPalette[index];
  }
}
