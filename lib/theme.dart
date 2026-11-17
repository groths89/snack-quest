import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0B1326);
  static const bg2 = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const coral = Color(0xFFFF5451);
  static const cyan = Color(0xFF06B6D4);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const text = Color(0xFFF1F5F9);
  static const muted = Color(0xFF94A3B8);
}

class AppText {
  static TextStyle inter(double size,
          {FontWeight weight = FontWeight.w600, Color color = AppColors.text}) =>
      GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          decoration: TextDecoration.none);

  static TextStyle mono(double size,
          {FontWeight weight = FontWeight.w700, Color color = AppColors.text}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size,
          fontWeight: weight,
          color: color,
          decoration: TextDecoration.none);
}
