import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/auth_screen.dart';
import 'screens/room_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/config.dart'; // API URL을 별도의 파일로 분리

void main() => runApp(const CounselorApp());

class CounselorApp extends StatelessWidget {
  const CounselorApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sadie Counselor',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      // 메인 진입점
      home: const AuthWrapper(),
      // route 에러 방지: /roomList 호출 시 다시 AuthWrapper로 보내서 
      // 현재 상태(토큰/닉네임 유무)에 맞는 화면을 띄우게 합니다.
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

Future<void> _checkLoginStatus() async {
  if (!mounted) return;
  setState(() => _isChecking = true);
  
  debugPrint("--- [DEBUG] 로그인 상태 체크 시작 ---");

  String? token = _token ?? await _storage.read(key: 'access_token');
  try {
    if (token != null) {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(utf8.decode(response.bodyBytes));
        if (userData['data'] != null) {
          final data = userData['data'];
          setState(() {
            _userId = data['id']?.toString() ?? data['user_id']?.toString(); 
            _nickname = data['nickname'] ?? "사용자";
            _email = data['email'] ?? "이메일 정보 없음";
            _isSocial = data['is_social'] == true; 
            _token = token;
          });
        }
      } else if (response.statusCode == 401) {
        // 토큰 만료 시 청소
        await _storage.delete(key: 'access_token');
        setState(() {
          _token = null;
          _nickname = null;
        });
      }
    }
  } catch (e) {
    debugPrint("--- [ERROR] $e ---");
  } finally {
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }
}

  void _handleLoginSuccess(String token) async {
  // 1. 즉시 로딩 상태로 만들고 토큰을 메모리에 저장
    setState(() {
      _isChecking = true;
      _token = token; 
    });

    // 2. 스토리지에 기록 (비동기)
    await _storage.write(key: 'access_token', value: token);
    
    // 3. 서버에서 최신 유저 정보를 가져와서 닉네임 등 업데이트
    await _checkLoginStatus();
  }

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
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}

  void _handleOnboardingComplete() {
    _checkLoginStatus(); 
  }

@override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F8FD), // 룸 리스트와 맞춘 배경색
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color.fromARGB(255, 182, 144, 253)),
              SizedBox(height: 20),
              Text("로그인 정보를 확인 중입니다...", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_token == null) {
      return AuthScreen(onLoginSuccess: _handleLoginSuccess);
    }

    if (_nickname == null || _nickname!.isEmpty) {
      return OnboardingScreen(
        initialNickname: "",
        accessToken: _token!,
        onComplete: _handleOnboardingComplete,
      );
    }

    // 수정: RoomListScreen에 초기 정보들을 더 많이 넘겨주면 로딩이 매끄러움.
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