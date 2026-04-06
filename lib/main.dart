import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// 🌸 경로 수정: 리팩토링된 위치로 변경
import 'package:frontend/presentation/screens/auth/auth_screen.dart';
import 'package:frontend/presentation/screens/room_list/room_list_screen.dart';
import 'package:frontend/presentation/screens/auth/onboarding_screen.dart';
import 'package:frontend/config.dart';

void main() {
  // 위젯 바인딩 초기화 (SecureStorage 등 비동기 플러그인 사용 시 안전함)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CounselorApp());
}

class CounselorApp extends StatelessWidget {
  const CounselorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sadie Counselor',
      theme: ThemeData(
        // Sadie의 파스텔 퍼플 톤에 맞춘 테마 설정
        primaryColor: const Color.fromARGB(255, 182, 144, 253),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 182, 144, 253),
          surface: const Color(0xFFFDFCFE),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/roomList': (context) => const AuthWrapper(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _nickname;
  String? _userId;
  String? _email;
  bool _isChecking = true;  
  bool _isSocial = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); 
  }

  // 🌸 로그인 상태 체크 로직 (최적화)
  Future<void> _checkLoginStatus() async {
    if (!mounted) return;
    setState(() => _isChecking = true);
    
    // 1. 스토리지에서 토큰 먼저 읽기
    String? savedToken = await _storage.read(key: 'access_token');
    
    if (savedToken == null) {
      if (mounted) setState(() => _isChecking = false);
      return;
    }

    try {
      // 2. 서버에 유저 정보 요청하여 토큰 유효성 검증
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: {'Authorization': 'Bearer $savedToken'},
      ).timeout(const Duration(seconds: 5)); // 타임아웃 5초로 소폭 단축

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(utf8.decode(response.bodyBytes));
        if (userData['data'] != null) {
          final data = userData['data'];
          if (mounted) {
            setState(() {
              _userId = data['id']?.toString() ?? data['user_id']?.toString(); 
              _nickname = data['nickname'];
              _email = data['email'];
              _isSocial = data['is_social'] == true; 
              _token = savedToken;
            });
          }
        }
      } else if (response.statusCode == 401) {
        // 만료된 토큰 삭제
        await _storage.delete(key: 'access_token');
        if (mounted) {
          setState(() {
            _token = null;
            _nickname = null;
          });
        }
      }
    } catch (e) {
      debugPrint("--- [Auth Error] $e ---");
      // 네트워크 에러 시 일단 오프라인 모드나 재시도 처리를 고민할 수 있지만, 
      // 현재는 로딩 종료만 처리합니다.
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  // 로그인 성공 핸들러
  void _handleLoginSuccess(String token) async {
    await _storage.write(key: 'access_token', value: token);
    await _checkLoginStatus(); // 최신 정보 갱신
  }

  // 로그아웃 핸들러
  void _handleLogout() async {
    await _storage.delete(key: 'access_token');
    if (mounted) {
      setState(() {
        _token = null;
        _nickname = null;
        _isSocial = false; 
        _userId = null;
        _email = null;
      });
      // 모든 경로를 제거하고 루트로 이동
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _handleOnboardingComplete() {
    _checkLoginStatus(); 
  }

  @override
  Widget build(BuildContext context) {
    // 1. 체크 중인 경우 로딩 화면
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F8FD),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color.fromARGB(255, 182, 144, 253)),
              SizedBox(height: 20),
              Text("로그인 정보를 확인 중입니다...", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // 2. 토큰이 없으면 로그인 화면
    if (_token == null) {
      return AuthScreen(onLoginSuccess: _handleLoginSuccess);
    }

    // 3. 닉네임이 없으면 온보딩(프로필 설정) 화면
    if (_nickname == null || _nickname!.isEmpty) {
      return OnboardingScreen(
        initialNickname: "",
        accessToken: _token!,
        onComplete: _handleOnboardingComplete,
      );
    }

    // 4. 모두 통과하면 메인 룸 리스트 화면
    return RoomListScreen(
      token: _token!,
      email: _email ?? "",
      isSocial: _isSocial,
      onLogout: _handleLogout,
      initialUserId: _userId,
      nickname: _nickname!,
    );
  }
}