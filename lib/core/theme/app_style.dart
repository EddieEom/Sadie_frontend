import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyle {
  // 텍스트 필드 스타일
  static InputDecoration authInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textSub),
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  // 카드 스타일 (마음 온도, 프로필 카드용)
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      )
    ],
  );
}