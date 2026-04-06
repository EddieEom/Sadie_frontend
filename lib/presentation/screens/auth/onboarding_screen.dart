import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // http 호출을 위해 필요
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 토큰 저장을 위해 필요
import 'package:frontend/config.dart';

class OnboardingScreen extends StatefulWidget {
  final String initialNickname; // 구글에서 가져온 이름
  final String? initialImageUrl; // 구글 프로필 이미지 (선택 사항)
  final String accessToken; // 토큰을 직접 받도록 추가
  final VoidCallback onComplete; // 콜백 추가

  const OnboardingScreen({
    super.key, 
    required this.initialNickname, 
    this.initialImageUrl,
    required this.accessToken,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  // storage 객체 생성 (로그인 시 토큰을 저장했던 곳과 같은 객체여야 함)
  final storage = const FlutterSecureStorage(); 

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.initialNickname;
  }
  // 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 설정 완료 후 서버 전송 로직
  Future<void> _completeOnboarding() async {
  String nickname = _nicknameController.text.trim();
  
  if (nickname.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('닉네임을 입력해주세요!')),
    );
    return;
  }

  try {
    // 1. 키 이름을 'access_token'으로 정확히 맞춤
    String token = widget.accessToken; 
    debugPrint("넘겨받은 토큰 확인: $token");

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/users/me/profile'),
    );

    request.followRedirects = false; // 리다이렉트 방지
    // 2. 서버의 replace("Bearer ", "") 로직에 맞게 반드시 "Bearer " 추가
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['nickname'] = nickname;
    
    if (widget.initialImageUrl != null && _imageFile == null) {
      request.fields['google_image_url'] = widget.initialImageUrl!;
    }

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image', 
        _imageFile!.path,
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      if (!mounted) return;

      widget.onComplete();

      // 수정된 부분: 현재 화면이 '온보딩'으로 직접 열린 건지, 
      // 아니면 마이페이지에서 'Push'해서 들어온 건지 판단합니다.
      if (Navigator.canPop(context)) {
        // 마이페이지에서 넘어왔다면, 수정을 마치고 다시 마이페이지로 돌아갑니다.
        Navigator.pop(context);
      } else {
        // 처음 로그인 후 온보딩에 들어왔다면(뒤로 갈 곳이 없다면) 룸 리스트로 갑니다.
        Navigator.pushReplacementNamed(context, '/roomList');
      }
    } 
    
    else {
      // 401 에러 시 서버가 주는 상세 메시지 확인용
      debugPrint("서버 응답 에러 (${response.statusCode}): ${response.body}");
      throw Exception('프로필 업데이트 실패: ${response.body}');
    }
  } catch (e) {
    debugPrint("최종 에러 발생: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('설정 저장 중 오류: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 키보드가 올라올 때 화면이 자동으로 조절되도록 설정 (기본값이 true)
      resizeToAvoidBottomInset: true, 
      body: SafeArea(
        child: SingleChildScrollView( // 1. 스크롤 가능하게 감싸기
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            // 2. 키보드가 올라왔을 때 최소 높이를 보장하거나 
            // 컨텐츠가 자연스럽게 배치되도록 함
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "프로필 설정",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("서비스에서 사용할 정보를 입력해주세요."),
                const SizedBox(height: 48),
                
                // 프로필 이미지 선택 섹션
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageFile != null 
                            ? FileImage(_imageFile!) 
                            : (widget.initialImageUrl != null 
                                ? NetworkImage(widget.initialImageUrl!) as ImageProvider
                                : null),
                        child: _imageFile == null && widget.initialImageUrl == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // 닉네임 입력 필드
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: "닉네임",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                ),

                // 3. Spacer() 대신 고정된 여백을 주거나 LayoutBuilder를 사용합니다.
                // 키보드가 없을 때 버튼을 아래로 밀고 싶다면 최소 80~100 정도의 여백을 줍니다.
                const SizedBox(height: 100), 
                
                // 시작하기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _completeOnboarding(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "시작하기",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                // 키보드에 가려지지 않도록 하단에 약간의 여유 공간 추가
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}