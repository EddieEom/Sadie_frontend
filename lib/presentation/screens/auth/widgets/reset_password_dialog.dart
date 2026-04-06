import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart';

class ResetPasswordDialog extends StatefulWidget {
  final FormFieldValidator<String>? passwordValidator;

  const ResetPasswordDialog({super.key, required this.passwordValidator});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _idConfirmController = TextEditingController();
  final _emailConfirmController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPwController = TextEditingController();
  final _resetFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isCodeSent = false;

  Future<void> _requestResetCode() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/request-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _idConfirmController.text.trim(),
          'email': _emailConfirmController.text.trim()
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _isCodeSent = true);
      } else {
        _showSnackBar("정보가 일치하지 않습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류가 발생했습니다.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndReset() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/verify-and-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _idConfirmController.text.trim(),
          'code': _codeController.text.trim(),
          'new_password': _newPwController.text.trim()
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context);
        _showSnackBar("비밀번호가 변경되었습니다.");
      } else {
        _showSnackBar("인증번호가 틀렸거나 만료되었습니다.");
      }
    } catch (e) {
      _showSnackBar("오류가 발생했습니다.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("비밀번호 재설정", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _resetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isCodeSent) ...[
                const Text("가입하신 아이디와 이메일을 입력해주세요."),
                const SizedBox(height: 15),
                TextFormField(controller: _idConfirmController, decoration: const InputDecoration(labelText: "아이디")),
                const SizedBox(height: 10),
                TextFormField(controller: _emailConfirmController, decoration: const InputDecoration(labelText: "이메일")),
              ] else ...[
                const Text("인증번호 6자리를 입력하세요."),
                const SizedBox(height: 15),
                TextFormField(controller: _codeController, decoration: const InputDecoration(labelText: "인증번호")),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _newPwController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "새 비밀번호", hintText: "8자 이상 + 영문/숫자/특수문자"),
                  validator: widget.passwordValidator,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
        ElevatedButton(
          onPressed: _isLoading ? null : () {
            if (_isCodeSent && !_resetFormKey.currentState!.validate()) return;
            _isCodeSent ? _verifyAndReset() : _requestResetCode();
          },
          child: _isLoading ? const CircularProgressIndicator() : Text(_isCodeSent ? "변경완료" : "인증번호 받기"),
        ),
      ],
    );
  }
}