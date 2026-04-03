import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour Palette ──

class ZenithColors {
  // Primary — rich deep pastel purple
  static const primary = Color(0xFF7B68AE);
  static const primaryLight = Color(0xFFA594C9);
  static const primaryPale = Color(0xFFD4CCE3);
  static const primaryDeep = Color(0xFF5E4D8C);

  // Pastels
  static const lavender = Color(0xFFB8A9C9);
  static const blush = Color(0xFFD4A9B8);
  static const peach = Color(0xFFDEB8A6);
  static const sky = Color(0xFFA9BCD4);
  static const mint = Color(0xFFA9C9B8);

  // Warm accents
  static const gold = Color(0xFFC4A882);
  static const lightGold = Color(0xFFD4C5A9);
  static const warmGray = Color(0xFFB8A99A);
  static const amber = Color(0xFFD4A24E);

  // Backgrounds — warm cream with a hint of lilac
  static const bg = Color(0xFFF6F4F8);
  static const bgMid = Color(0xFFF0ECF3);
  static const bgDark = Color(0xFFEAE5F0);
  // Keep old names as aliases so nothing breaks during migration
  static const cream = bg;
  static const creamMid = bgMid;
  static const creamDark = bgDark;

  // Surfaces
  static const card = Color(0xFFFFFEFF);
  static const cardBorder = Color(0x0A000000); // 4 % black

  // Text
  static const text = Color(0xFF2A2A32);
  static const textLight = Color(0xFF8E8E9A);
  static const textMuted = Color(0xFFAAAAAF);
  static const label = Color(0xFFA09AAE);

  // Navigation
  static const navInactive = Color(0xFFC4BFD0);

  // XP / progress
  static const xp = Color(0xFF7C6FA0);

  // Danger
  static const danger = Color(0xFFC27070);

  // Garden (keep greens for the living garden widget)
  static const sage = Color(0xFF8B9E8B);
  static const greenLight = Color(0xFFA0AE90);
  static const greenMid = Color(0xFFA8B8A0);
  static const greenPale = Color(0xFFC8D4C0);
  static const bark = Color(0xFF8B7B6B);
  static const leafDark = Color(0xFF7A8B6B);
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
  }) =>
      GoogleFonts.cormorantGaramond(
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
  }) =>
      GoogleFonts.dmSans(
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
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  // ── Glass card decoration ──

  static BoxDecoration glassCard({
    double borderRadius = 20,
    Color? borderColor,
    Color? fill,
  }) =>
      BoxDecoration(
        color: fill ?? Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? ZenithColors.cardBorder,
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          color: ZenithColors.textMuted,
        ),
        labelStyle: GoogleFonts.dmSans(
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
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ZenithColors.primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Outlined buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZenithColors.primary,
          side: BorderSide(color: ZenithColors.primary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ZenithColors.text,
        ),
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: ZenithColors.textLight,
          height: 1.55,
        ),
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: ZenithColors.primaryPale.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ZenithColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Scrollbar ──
      scrollbarTheme: ScrollbarThemeData(
        thumbColor:
            WidgetStatePropertyAll(ZenithColors.primary.withValues(alpha: 0.2)),
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
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ZenithColors.text,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ZenithColors.text,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ZenithColors.text,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ZenithColors.text,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ZenithColors.textLight,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ZenithColors.text,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ZenithColors.textLight,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: ZenithColors.label,
        letterSpacing: 1.5,
      ),
    );
  }
}
