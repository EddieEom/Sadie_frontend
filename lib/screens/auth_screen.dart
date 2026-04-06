import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/screens/onboarding_screen.dart';
import 'package:frontend/config.dart'; 

String? validatePassword(String? value) {
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
  bool _isCodeSent = false; 

  // 파스텔 테마 컬러 정의 (통일)
  final Color primaryColor = const Color.fromARGB(255, 182, 144, 253); // 라벤더
  final Color scaffoldBgColor = const Color(0xFFFDFCFE); // 연보라빛 화이트
  final Color textColor = const Color.fromARGB(255, 26, 25, 25); // 짙은 퍼플
  final Color subTextColor = const Color(0xFF9575CD);

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating)
    );
  }

// 구글 로그인 처리 함수
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
      // 1. 백엔드에서 준 정보 추출
      final String accessToken = data['access_token'];
      final bool isNewUser = data['is_new_user'] ?? false; // 신규 가입 여부
      final String googleName = data['google_name'] ?? ""; // 구글 프로필 이름
      final String? googlePicture = data['google_picture']; // 구글 프로필 사진 URL

      if (isNewUser) {
        // 2. 신규 유저라면 온보딩(프로필 설정) 화면으로 이동
        // 이때 나중에 서버에 토큰을 보내야 하므로 accessToken도 같이 관리하거나 서비스에 저장해야 합니다.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnboardingScreen(
              initialNickname: googleName,
              initialImageUrl: googlePicture,
              accessToken: accessToken, // 토큰을 생성자에 넘겨서 온보딩에서 사용할 수 있도록 함
              onComplete: () {
                widget.onLoginSuccess(accessToken);
              },
            ),
          ),
        );
      } else {
        // 3. 기존 유저라면 바로 메인으로 진입
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

  Future<void> _requestResetCode(String userId, String email, StateSetter setDialogState) async {
    setDialogState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/request-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'email': email}),
      );
      if (response.statusCode == 200) {
        setDialogState(() => _isCodeSent = true);
        _showSnackBar("인증번호가 이메일로 발송되었습니다.");
      } else {
        _showSnackBar("정보가 일치하지 않습니다.");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류가 발생했습니다.");
    } finally {
      setDialogState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndReset(String userId, String code, String newPw) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/verify-and-reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'code': code, 'new_password': newPw}),
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

  void _showResetPasswordDialog() {
    _isCodeSent = false;
    final idConfirmController = TextEditingController();
    final emailConfirmController = TextEditingController();
    final codeController = TextEditingController();
    final newPwController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("비밀번호 재설정", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isCodeSent) ...[
                      const Text("가입하신 아이디와 이메일을 입력해주세요.", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 15),
                      TextFormField(controller: idConfirmController, decoration: InputDecoration(labelText: "아이디", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 10),
                      TextFormField(controller: emailConfirmController, decoration: InputDecoration(labelText: "이메일", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    ] else ...[
                      const Text("인증번호 6자리를 입력하세요.", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 15),
                      TextFormField(controller: codeController, decoration: InputDecoration(labelText: "인증번호", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: newPwController, 
                        obscureText: true, 
                        decoration: InputDecoration(labelText: "새 비밀번호", hintText: "8자 이상 + 영문/숫자/특수문자", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        validator: validatePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  if (_isCodeSent && !resetFormKey.currentState!.validate()) return;
                  if (!_isCodeSent) {
                    await _requestResetCode(idConfirmController.text.trim(), emailConfirmController.text.trim(), setDialogState);
                  } else {
                    await _verifyAndReset(idConfirmController.text.trim(), codeController.text.trim(), newPwController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isCodeSent ? "변경완료" : "인증번호 받기", style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

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
              // 🌸 로고 아이콘 색상 변경
              Icon(Icons.spa_rounded, size: 80, color: primaryColor), 
              const SizedBox(height: 20),
              Text(_isLoginView ? "Sadie" : "Join Sadie", 
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, letterSpacing: 1.2)),
              Text("당신의 마음을 들어드려요", style: TextStyle(fontSize: 14, color: subTextColor)),
              const SizedBox(height: 50),
              
              // 🌸 입력창 스타일 개선
              TextField(
                controller: _idController, 
                decoration: InputDecoration(
                  labelText: "아이디", 
                  prefixIcon: Icon(Icons.person_outline, color: subTextColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                )
              ),
              const SizedBox(height: 15),
              if (!_isLoginView) ...[
                TextField(
                  controller: _emailController, 
                  decoration: InputDecoration(
                    labelText: "이메일", 
                    prefixIcon: Icon(Icons.email_outlined, color: subTextColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                  )
                ),
                const SizedBox(height: 15),
              ],
              TextField(
                controller: _pwController, 
                obscureText: true, 
                decoration: InputDecoration(
                  labelText: "비밀번호", 
                  prefixIcon: Icon(Icons.lock_outline, color: subTextColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                )
              ),
              
              if (_isLoginView)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetPasswordDialog,
                    child: Text("비밀번호를 잊으셨나요?", style: TextStyle(color: subTextColor, fontSize: 13)),
                  ),
                ),
                
              const SizedBox(height: 30),
              
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

              // ✨ 여기부터 구글 로그인 영역을 조건부로 묶습니다.
              if (_isLoginView) ...[
                const SizedBox(height: 25),

                // 1. 구분선
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("또는", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 25),

                // 2. 구글 로그인 버튼
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
              ], // ✨ 조건부 묶음 끝

              const SizedBox(height: 10),
              
              // 하단 전환 버튼
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