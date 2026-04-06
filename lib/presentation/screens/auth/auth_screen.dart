import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/presentation/screens/auth/onboarding_screen.dart';
import 'package:frontend/config.dart';

// 🌸 새롭게 분리한 커스텀 위젯들 임포트
import './widgets/auth_text_field.dart';
import './widgets/social_divider.dart';
import './widgets/reset_password_dialog.dart';

class AuthScreen extends StatefulWidget {
  final Function(String) onLoginSuccess;
  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoginView = true;
  bool _isLoading = false;

  // 파스텔 테마 컬러 정의 (AppColors로 옮기셨다면 AppColors.xxx 형태로 교체 가능합니다)
  final Color primaryColor = const Color.fromARGB(255, 182, 144, 253); 
  final Color scaffoldBgColor = const Color(0xFFFDFCFE); 
  final Color textColor = const Color.fromARGB(255, 26, 25, 25); 
  final Color subTextColor = const Color(0xFF9575CD);

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating)
    );
  }

  // 🌸 비밀번호 유효성 검사 (다이얼로그와 공유하기 위해 유지)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    final passwordRegExp = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$'
    );
    if (!passwordRegExp.hasMatch(value)) {
      return '8자 이상, 영문, 숫자, 특수문자를 각각 포함해야 합니다.';
    }
    return null;
  }

  // 🌸 분리된 비밀번호 재설정 다이얼로그 호출
  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResetPasswordDialog(
        passwordValidator: _validatePassword,
      ),
    );
  }

  // 구글 로그인 처리 함수 (기존 로직 동일)
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final idToken = await GoogleAuthService().signInWithGoogle();
      
      if (idToken == null) {
        setState(() => _isLoading = false);
        return; 
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      if (!mounted) return;
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final String accessToken = data['access_token'];
        final bool isNewUser = data['is_new_user'] ?? false;
        final String googleName = data['google_name'] ?? "";
        final String? googlePicture = data['google_picture'];

        if (isNewUser) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                initialNickname: googleName,
                initialImageUrl: googlePicture,
                accessToken: accessToken,
                onComplete: () {
                  widget.onLoginSuccess(accessToken);
                },
              ),
            ),
          );
        } else {
          widget.onLoginSuccess(accessToken);
        }
      } else {
        _showSnackBar(data['detail']?.toString() ?? "구글 로그인 실패");
      }
    } catch (e) {
      _showSnackBar("서버 연결 실패");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 자체 회원가입/로그인 처리 함수 (기존 로직 동일)
  Future<void> _handleAuth() async {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();
    final email = _emailController.text.trim();

    if (id.isEmpty || pw.isEmpty || (!_isLoginView && email.isEmpty)) {
      _showSnackBar("모든 정보를 입력해주세요.");
      return;
    }

    setState(() => _isLoading = true);
    final endpoint = _isLoginView ? "/login" : "/signup";
    final body = _isLoginView 
        ? {'user_id': id, 'password': pw} 
        : {'user_id': id, 'password': pw, 'email': email};

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (!mounted) return;
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        if (_isLoginView) {
          widget.onLoginSuccess(data['access_token']);
        } else {
          _showSnackBar("가입 성공! 로그인해 주세요.");
          setState(() => _isLoginView = true);
        }
      } else {
        _showSnackBar(data['detail']?.toString() ?? "오류 발생");
      }
    } catch (e) {
      _showSnackBar("서버 연결 실패");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Icon(Icons.spa_rounded, size: 80, color: primaryColor), 
              const SizedBox(height: 20),
              Text(_isLoginView ? "Sadie" : "Join Sadie", 
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 1.2)),
              Text("당신의 마음을 들어드려요", style: TextStyle(fontSize: 14, color: subTextColor)),
              const SizedBox(height: 50),
              
              // 🌸 1. 분리한 텍스트 필드 위젯 적용 (코드량 대폭 감소)
              AuthTextField(
                controller: _idController,
                label: "아이디",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),

              if (!_isLoginView) ...[
                AuthTextField(
                  controller: _emailController,
                  label: "이메일",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 15),
              ],

              AuthTextField(
                controller: _pwController,
                label: "비밀번호",
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              
              if (_isLoginView)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetPasswordDialog, // 🌸 2. 다이얼로그 호출
                    child: Text("비밀번호를 잊으셨나요?", style: TextStyle(color: subTextColor, fontSize: 13)),
                  ),
                ),
                
              const SizedBox(height: 30),
              
              // 로그인/회원가입 버튼
              _isLoading 
                ? CircularProgressIndicator(color: primaryColor)
                : ElevatedButton(
                    onPressed: _handleAuth, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text(_isLoginView ? "로그인" : "회원가입", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                  ),

              if (_isLoginView) ...[
                const SizedBox(height: 25),

                // 🌸 3. 분리한 소셜 로그인 구분선 적용
                const SocialDivider(),

                const SizedBox(height: 25),

                // 구글 로그인 버튼
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  icon: Image.asset('assets/images/google_logo.png', height: 22),
                  label: Text(
                    "구글 계정으로 계속하기",
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                ),
              ],

              const SizedBox(height: 10),
              
              // 하단 뷰 전환 버튼
              TextButton(
                onPressed: () => setState(() => _isLoginView = !_isLoginView),
                child: Text(_isLoginView ? "처음이신가요? 계정 만들기" : "이미 계정이 있나요? 로그인하기", 
                  style: TextStyle(color: textColor.withValues(alpha: 0.7))),
              )
            ],
          ),
        ),
      ),
    );
  }
}