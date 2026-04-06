import 'package:flutter/material.dart'; // 1. 플러터 기본 위젯들 사용을 위해 필수
import 'package:frontend/core/theme/app_style.dart'; // 2. AppStyle 경로에 맞춰 수정 필요

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: AppStyle.authInputDecoration(label: label, icon: icon),
    );
  }
}