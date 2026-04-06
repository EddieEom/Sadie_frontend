import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config.dart'; // API URL을 별도의 파일로 분리

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return '비밀번호를 입력해주세요.';
  }
  
  // 8자 이상, 영문, 숫자, 특수문자(!@#$...) 포함 정규식
  final passwordRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$'
  );
  
  if (!passwordRegExp.hasMatch(value)) {
    return '8자 이상, 영문, 숫자, 특수문자를 각각 포함해야 합니다.';
  }
  return null;
}

class PasswordChangeScreen extends StatefulWidget {
  final String token;
  const PasswordChangeScreen({super.key, required this.token});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_newPwController.text != _confirmPwController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("새 비밀번호가 일치하지 않습니다."))
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'current_password': _currentPwController.text,
          'new_password': _newPwController.text,
        }),
      );

      // 🔥 [핵심] 비동기 작업(await) 직후에 이 체크를 넣어줍니다.
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호가 변경되었습니다."))
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['detail'] ?? "변경 실패"))
        );
      }
    } catch (e) {
      // 🔥 여기도 비동기 작업 이후이므로 mounted 체크가 필요할 수 있습니다.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("네트워크 오류"))
      );
    } finally {
      // setState를 쓰기 전에도 체크하는 것이 안전합니다.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("비밀번호 변경")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _currentPwController, obscureText: true, decoration: const InputDecoration(labelText: "현재 비밀번호")),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPwController, 
                obscureText: true, 
                decoration: const InputDecoration(
                  labelText: "새 비밀번호",
                  helperText: "8자 이상, 영문/숫자/특수문자 조합",
                ),
                validator: validatePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPwController, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: "새 비밀번호 확인"),
                validator: (value) {
                  if (value != _newPwController.text) return '비밀번호가 일치하지 않습니다.';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _handleChangePassword, child: const Text("변경하기")),
            ],
          ),
        ),
      ),
    );
  }
}