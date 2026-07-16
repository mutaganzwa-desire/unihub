import 'package:flutter/material.dart';

/// Brand palette. A calm indigo-violet primary (energetic but professional,
/// suited to a student/startup audience) with soft category accents.
abstract final class AppColors {
  static const primary = Color(0xFF6C5CE7);
  static const primaryDark = Color(0xFF4B3FBF);
  static const secondary = Color(0xFF00B894);
  static const accentPeach = Color(0xFFFAB1A0);
  static const accentAmber = Color(0xFFFDCB6E);

  static const surfaceLight = Color(0xFFF7F7FB);
  static const surfaceDark = Color(0xFF121218);
  static const cardDark = Color(0xFF1C1C26);

  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFF39C12);
  static const danger = Color(0xFFE74C3C);
  static const info = Color(0xFF0984E3);

  /// Status colors used across applications / internships / verification.
  static Color statusColor(String status) => switch (status) {
        'accepted' || 'verified' || 'open' => success,
        'underReview' || 'pending' || 'interview' || 'shortlisted' => warning,
        'rejected' || 'closed' || 'withdrawn' => danger,
        'paused' || 'draft' || 'archived' => Colors.blueGrey,
        _ => info,
      };
}
