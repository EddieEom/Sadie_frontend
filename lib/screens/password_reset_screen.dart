import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';

class PasswordResetScreen extends StatefulWidget {
  final String userId;
  const PasswordResetScreen({super.key, required this.userId});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isCodeSent = false;
  bool _isLoading = false;

  final Color primaryColor = const Color.fromARGB(255, 182, 144, 253);

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleRequestCode() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/request-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId, 
          'email': _emailController.text.trim()
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _isCodeSent = true);
        _showSnackBar("인증번호가 발송되었습니다.");
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        _showSnackBar(errorData['detail'] ?? "오류가 발생했습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 연결을 확인해주세요.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyAndReset() async {
    if (_codeController.text.isEmpty || _newPasswordController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/verify-and-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'code': _codeController.text.trim(),
          'new_password': _newPasswordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("비밀번호가 성공적으로 변경되었습니다.");
        
        // 중요: 비동기 작업 후 mounted 체크 필수
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        _showSnackBar(errorData['detail'] ?? "인증에 실패했습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 연결을 확인해주세요.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("비밀번호 재설정")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "이메일", hintText: "가입 시 등록한 이메일"),
              enabled: !_isCodeSent,
            ),
            if (_isCodeSent) ...[
              const SizedBox(height: 16),
              TextField(controller: _codeController, decoration: const InputDecoration(labelText: "인증번호")),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController, 
                decoration: const InputDecoration(labelText: "새 비밀번호"),
                obscureText: true,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_isCodeSent ? _handleVerifyAndReset : _handleRequestCode),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(_isCodeSent ? "변경 완료" : "인증번호 요청", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}