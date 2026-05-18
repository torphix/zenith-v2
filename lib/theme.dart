import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour Palette ──

class ZenithColors {
  // Primary — refined sage
  static const primary = Color(0xFF7A8F7A);
  static const primaryLight = Color(0xFF9DAE9D);
  static const primaryPale = Color(0xFFC5D1C5);
  static const primaryDeep = Color(0xFF3D4F3D);

  // Pastels — harmonised with sage
  static const lavender = Color(0xFFA6A0B6);
  static const blush = Color(0xFFC8A89C);
  static const peach = Color(0xFFD0B8A4);
  static const sky = Color(0xFF96ADB8);
  static const mint = Color(0xFF94B8A6);

  // Warm accents — antique gold & champagne
  static const gold = Color(0xFFC9A84C);
  static const lightGold = Color(0xFFE2D5A8);
  static const warmGray = Color(0xFFA89E90);
  static const amber = Color(0xFFD4A040);

  // Backgrounds — sage-kissed ivory
  static const bg = Color(0xFFF8F9F6);
  static const bgMid = Color(0xFFEFF1EC);
  static const bgDark = Color(0xFFE3E7DE);
  // Keep old names as aliases so nothing breaks during migration
  static const cream = bg;
  static const creamMid = bgMid;
  static const creamDark = bgDark;

  // Surfaces
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color(0x12000000); // 7 % black

  // Text — sage-tinted
  static const text = Color(0xFF1A1F1A);
  static const textLight = Color(0xFF6E7A6E);
  static const textMuted = Color(0xFF9AA69A);
  static const label = Color(0xFF8A948A);

  // Navigation
  static const navInactive = Color(0xFFB8C0B8);

  // XP / progress
  static const xp = Color(0xFF7A8F7A);

  // Danger
  static const danger = Color(0xFFC25048);

  // Garden — deeper botanical tones
  static const sage = Color(0xFF7A8F7A);
  static const greenLight = Color(0xFF8BA27E);
  static const greenMid = Color(0xFF92A88C);
  static const greenPale = Color(0xFFB4C6AE);
  static const bark = Color(0xFF6E5F4E);
  static const leafDark = Color(0xFF5E7652);
}

// ── Typography helpers ──

class ZenithTheme {
  static TextStyle cormorant({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ZenithColors.text,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.cormorantGaramond(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontStyle: fontStyle,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ZenithColors.text,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.outfit(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontStyle: fontStyle,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    Color color = ZenithColors.text,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );

  // ── Glass card decoration ──

  static BoxDecoration glassCard({
    double borderRadius = 20,
    Color? borderColor,
    Color? fill,
  }) => BoxDecoration(
    color: fill ?? Colors.white.withValues(alpha: 0.55),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: borderColor ?? ZenithColors.cardBorder),
  );

  // ── Full ThemeData ──

  static ThemeData themeData() {
    final base = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: ZenithColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ZenithColors.primary,
        primary: ZenithColors.primary,
        onPrimary: Colors.white,
        secondary: ZenithColors.lavender,
        onSecondary: ZenithColors.text,
        tertiary: ZenithColors.blush,
        surface: ZenithColors.bg,
        onSurface: ZenithColors.text,
        error: ZenithColors.danger,
      ),
    );

    return base.copyWith(
      // ── App bar ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: ZenithColors.bgMid,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: ZenithColors.text,
        ),
        iconTheme: const IconThemeData(color: ZenithColors.text, size: 22),
      ),

      // ── Text ──
      textTheme: _textTheme(),

      // ── Input fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ZenithColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ZenithColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ZenithColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.outfit(
          fontSize: 15,
          color: ZenithColors.textMuted,
        ),
        labelStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: ZenithColors.textLight,
        ),
      ),

      // ── Elevated buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZenithColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Text buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ZenithColors.primary,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Outlined buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZenithColors.primary,
          side: BorderSide(color: ZenithColors.primary.withValues(alpha: 0.25)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: ZenithColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ZenithColors.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom sheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ZenithColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: ZenithColors.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ZenithColors.text,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 14,
          color: ZenithColors.textLight,
          height: 1.55,
        ),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: ZenithColors.primaryPale.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ZenithColors.primary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.04),
        thickness: 1,
        space: 0,
      ),

      // ── Progress indicator ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ZenithColors.primary,
        linearTrackColor: ZenithColors.primaryPale,
      ),

      // ── Snack bar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ZenithColors.text,
        contentTextStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          ZenithColors.primary.withValues(alpha: 0.2),
        ),
        radius: const Radius.circular(4),
      ),

      // ── Splash / highlight ──
      splashColor: ZenithColors.primary.withValues(alpha: 0.08),
      highlightColor: ZenithColors.primary.withValues(alpha: 0.04),
    );
  }

  // ── Private: build text theme from Google Fonts ──

  static TextTheme _textTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.cormorantGaramond(
        fontSize: 38,
        fontWeight: FontWeight.w400,
        color: ZenithColors.text,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: ZenithColors.text,
      ),
      displaySmall: GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      headlineSmall: GoogleFonts.cormorantGaramond(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ZenithColors.text,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ZenithColors.text,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ZenithColors.text,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ZenithColors.textLight,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ZenithColors.text,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ZenithColors.textLight,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ZenithColors.label,
        letterSpacing: 1.5,
      ),
    );
  }
}
