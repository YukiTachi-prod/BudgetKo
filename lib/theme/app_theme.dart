import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Color Tokens: Light (Warm Minimalist) ────────────────────────
  static const Color lightBg = Color(0xFFF9F8F6); // Warm off-white
  static const Color lightCard = Color(0xFFF2F2F0); // Soft gray cards
  static const Color lightBorder = Color(0xFFE8E7E4); // Thin borders
  static const Color lightText = Color(0xFF3A3A38); // Warm dark gray
  static const Color lightSubtext = Color(0xFF6B6B68); // Lighter slate
  static const Color lightAccent = Color(0xFFA3A6A8); // Desaturated accent

  // ── Color Tokens: Dark (Warm Charcoal Minimalist) ───────────────
  static const Color darkBg = Color(0xFF1E1E1C);
  static const Color darkCard = Color(0xFF262624);
  static const Color darkBorder = Color(0xFF383835);
  static const Color darkText = Color(0xFFF0EFEB);
  static const Color darkSubtext = Color(0xFFA1A09C);
  static const Color darkAccent = Color(0xFFB5B8B9);

  // ── Shared Corner Radii (4-6px, strictly no pill shapes) ────────
  static const double radius = 6.0;
  static const double buttonRadius = 5.0;

  // ── Clean Sans-Serif Font Fallbacks ──────────────────────────────
  static const String fontFamily = 'Inter';
  static const List<String> fontFamilyFallback = [
    'Helvetica Neue',
    'Helvetica',
    'Arial',
    'sans-serif',
  ];

  static ThemeData light([Color? accentColor]) => _build(
    brightness: Brightness.light,
    bg: lightBg,
    surface: lightCard,
    border: lightBorder,
    text: lightText,
    subtext: lightSubtext,
    accent: accentColor ?? lightAccent,
  );

  static ThemeData dark([Color? accentColor]) => _build(
    brightness: Brightness.dark,
    bg: darkBg,
    surface: darkCard,
    border: darkBorder,
    text: darkText,
    subtext: darkSubtext,
    accent: accentColor ?? darkAccent,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
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
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: isDark ? const Color(0xFF1E1E1C) : Colors.white,
        secondary: subtext,
        onSecondary: isDark ? const Color(0xFF1E1E1C) : Colors.white,
        error: const Color(0xFFC2554D),
        onError: Colors.white,
        surface: surface,
        onSurface: text,
        outline: border,
        outlineVariant: border,
        tertiary: subtext,
        onTertiary: bg,
        primaryContainer: accent.withValues(alpha: 0.12),
        onPrimaryContainer: text,
        secondaryContainer: surface,
        onSecondaryContainer: text,
        surfaceContainerHighest: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: subtext, size: 20),
        shape: Border(bottom: BorderSide(color: border, width: 1.0)),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: border,
        indicatorColor: text,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: text,
        unselectedLabelColor: subtext,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: text,
        unselectedItemColor: subtext,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1.0, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent.withValues(alpha: 0.15),
        disabledColor: surface,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: text,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          color: text,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: border, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: border, width: 1.0),
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: border, width: 1.0),
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent, width: 1.2),
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: subtext,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: subtext,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: false,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 14,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 13,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: subtext,
          fontSize: 12,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: subtext,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: subtext,
          fontSize: 11,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: subtext,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border, width: 1.0),
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontFamilyFallback: fontFamilyFallback,
          color: text,
          fontSize: 13,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? const Color(0xFF1E1E1C) : Colors.white,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          minimumSize: const Size(0, 38),
          elevation: 0,
          shadowColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          enableFeedback: false,
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.transparent)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          splashFactory: NoSplash.splashFactory,
          enableFeedback: false,
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.transparent)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border, width: 1.0),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          minimumSize: const Size(0, 38),
          elevation: 0,
          splashFactory: NoSplash.splashFactory,
          enableFeedback: false,
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.transparent)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: subtext,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          enableFeedback: false,
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.transparent)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: isDark ? const Color(0xFF1E1E1C) : Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        enableFeedback: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border, width: 1.0),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? const Color(0xFF5A5A55) : const Color(0xFFCBD5E1);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return isDark ? const Color(0xFF383835) : const Color(0xFFE8E7E4);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(
          isDark ? const Color(0xFF1E1E1C) : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: border, width: 1.0),
      ),
    );
  }

  // ── Muted, Calm Category Palette ──────────────────────────────────
  static const _categoryPalette = [
    Color(0xFF7D8C7C), // Muted Sage
    Color(0xFF6C7C8C), // Soft Slate Blue
    Color(0xFFA37D6E), // Warm Terracotta
    Color(0xFF9E8A64), // Muted Ochre
    Color(0xFF9E767E), // Dusty Rose
    Color(0xFF5A6065), // Soft Charcoal
    Color(0xFF6B8A88), // Muted Teal
    Color(0xFF8A8275), // Warm Taupe
  ];

  static Color categoryColor(String category) {
    final index =
        category.toLowerCase().hashCode.abs() % _categoryPalette.length;
    return _categoryPalette[index];
  }
}
