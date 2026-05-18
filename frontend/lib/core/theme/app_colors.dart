import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Editorial palette (v2) ───────────────────────────────────
  static const background           = Color(0xFFF2EEE5);
  static const surface              = Color(0xFFFBF9F3);
  static const surfaceContainerLow  = Color(0xFFF5F0E3);
  static const surfaceContainer     = Color(0xFFEEE8D9);
  static const surfaceContainerHigh = Color(0xFFE5DFCF);

  static const ink       = Color(0xFF0B1118);
  static const inkSubtle = Color(0xFF2A2E36);
  static const inkMuted  = Color(0xFF5A574F);
  static const inkDim    = Color(0xFF8A857C);

  static const hairline       = Color(0xFFDDD5C5);
  static const hairlineStrong = Color(0xFFC8BFA9);

  static const primary          = Color(0xFF0E2A47);
  static const onPrimary        = Color(0xFFFBF9F3);
  static const primaryContainer = Color(0xFFD7E0EE);

  static const oxblood            = Color(0xFF8E2330);
  static const oxbloodContainer   = Color(0xFFF3D9DC);
  static const onOxbloodContainer = Color(0xFF480912);

  static const gold            = Color(0xFFA47B3A);
  static const goldContainer   = Color(0xFFF1E2B9);
  static const onGoldContainer = Color(0xFF3A2A06);

  static const success          = Color(0xFF1F6B3A);
  static const successContainer = Color(0xFFD2EAD8);

  static const error          = Color(0xFF9C1F25);
  static const errorContainer = Color(0xFFF4DCDD);

  // ── Legacy aliases ───────────────────────────────────────────
  static const navy      = primary;
  static const navyLight = surfaceContainerLow;
  static const navySurf  = surfaceContainer;
  static const offWhite  = surface;
  static const subtle    = inkMuted;
  static const sky       = Color(0xFF2E6DB4);
}
