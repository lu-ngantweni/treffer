import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Soundscape design system
// Deep-space audio aesthetic
// ─────────────────────────────────────────────

class SColors {
  SColors._();

  // Background depth layers — elevation expressed through darkness
  static const void_bg     = Color(0xFF0f0f18); // deepest — page background
  static const surface      = Color(0xFF16213e); // cards, list tiles
  static const elevated     = Color(0xFF1a1a2e); // inputs, search bars

  // Accent — one colour, used sparingly
  static const pulse        = Color(0xFF6C63FF); // primary accent
  static const pulseDeep    = Color(0xFF4c1d95); // artwork gradients, covers
  static const pulseGlow    = Color(0xFFa78bfa); // subtle highlights

  // Glass — translucent overlay tint
  static const glass        = Color(0x0FFFFFFF); // 6% white overlay

  // Text hierarchy
  static const textPrimary  = Color(0xFFFFFFFF);
  static const textSecondary = Color(0x99FFFFFF); // 60%
  static const textHint     = Color(0x40FFFFFF); // 25%

  // Semantic
  static const danger       = Color(0xFFFF5252);
  static const success      = Color(0xFF1DB954);
}

class SDurations {
  SDurations._();
  static const fast    = Duration(milliseconds: 180);
  static const normal  = Duration(milliseconds: 300);
  static const slide   = Duration(milliseconds: 350);
  static const slow    = Duration(milliseconds: 500);
}

class SCurves {
  SCurves._();
  static const slide   = Curves.easeOutCubic;   // screen transitions
  static const settle  = Curves.easeInOutCubic;  // progress, volume
  static const spring  = Curves.elasticOut;       // follow/like buttons (scale 0→1)
}

class SRadius {
  SRadius._();
  static const xs  = BorderRadius.all(Radius.circular(6));
  static const sm  = BorderRadius.all(Radius.circular(10));
  static const md  = BorderRadius.all(Radius.circular(12));
  static const lg  = BorderRadius.all(Radius.circular(16));
  static const xl  = BorderRadius.all(Radius.circular(22));
  static const full = BorderRadius.all(Radius.circular(999));
}

class STextStyles {
  STextStyles._();

  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: SColors.pulse,
    letterSpacing: -0.5,
  );

  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: SColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: SColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: SColors.textSecondary,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SColors.textHint,
    letterSpacing: 0.3,
  );

  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: SColors.textHint,
    letterSpacing: 0.08,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.dark(
      primary: SColors.pulse,
      surface: SColors.surface,
    ),
    scaffoldBackgroundColor: SColors.void_bg,
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: SColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: STextStyles.title,
      iconTheme: IconThemeData(color: SColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SColors.pulse,
        foregroundColor: SColors.textPrimary,
        shape: const RoundedRectangleBorder(borderRadius: SRadius.md),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SColors.elevated,
      hintStyle: const TextStyle(color: SColors.textHint),
      border: OutlineInputBorder(
        borderRadius: SRadius.md,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SRadius.md,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SRadius.md,
        borderSide: const BorderSide(color: SColors.pulse, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerColor: Colors.white.withOpacity(0.06),
  );
}
