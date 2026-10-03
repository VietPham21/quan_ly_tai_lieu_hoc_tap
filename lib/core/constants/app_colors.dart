import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand palette (phong cách hiện đại, thanh lịch)
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryContainer = Color(0xFFDBEAFE);

  // Secondary accents
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color secondaryContainer = Color(0xFFCCFBF1);

  // Background & Surface
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // State colors
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0284C7);

  // File type specific badge colors
  static const Color pdfColor = Color(0xFFEF4444); // Red
  static const Color docxColor = Color(0xFF2563EB); // Blue
  static const Color pptxColor = Color(0xFFEA580C); // Orange
  static const Color xlsxColor = Color(0xFF16A34A); // Green
  static const Color codeColor = Color(0xFF8B5CF6); // Purple
  static const Color zipColor = Color(0xFF6B7280); // Gray
  static const Color otherColor = Color(0xFF0D9488); // Teal
}
