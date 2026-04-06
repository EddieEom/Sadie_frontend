import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 

// 🌸 새롭게 분리한 커스텀 위젯들 임포트
import './widgets/profile_card.dart';
import './widgets/mind_temperature_card.dart';
import './widgets/setting_tile.dart';

// 기존 화면들 임포트 (경로 확인 필요)
import 'package:frontend/presentation/screens/mypage/sub_screens/password_change_screen.dart';
import 'package:frontend/presentation/screens/auth/onboarding_screen.dart';
import 'package:frontend/presentation/screens/mypage/sub_screens/password_reset_screen.dart';

class MyPageScreen extends StatefulWidget {
  final String userId;
  final String token;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final bool isSocial;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final double mindScore;

  const MyPageScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.isSocial,
    required this.onLogout,
    required this.onDeleteAccount,
    this.mindScore = 36.5,
  });

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final Color primaryColor = const Color.fromARGB(255, 182, 144, 253);
  final Color scaffoldBgColor = const Color(0xFFF9F8FD);
  final Color darkTextColor = const Color.fromARGB(255, 26, 25, 25);

  late String _currentNickname;
  String? _currentProfileImage;
  bool _isNotificationEnabled = true;
  String _appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    _currentNickname = widget.nickname;
    _currentProfileImage = widget.profileImageUrl;
    _loadSettings();
    _loadAppVersion();
  }

  // --- 비즈니스 로직 ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isNotificationEnabled = prefs.getBool('notification_enabled') ?? true);
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isNotificationEnabled = value);
    await prefs.setBool('notification_enabled', value);
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() => _appVersion = packageInfo.version);
  }

  void _navigateToEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingScreen(
          initialNickname: _currentNickname,
          initialImageUrl: _currentProfileImage,
          accessToken: widget.token,
          onComplete: () {
            // 프로필 업데이트 후 필요 시 상위 상태 갱신 로직 추가 가능
          },
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("로그아웃", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("정말 로그아웃 하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            child: const Text("로그아웃", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPasswordOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("비밀번호 설정", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text("현재 비밀번호로 변경"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PasswordChangeScreen(token: widget.token)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: const Text("비밀번호 재설정"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PasswordResetScreen(userId: widget.userId)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 메인 빌드 메서드 ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: darkTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("마이페이지", style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 🌸 1. 프로필 카드 위젯
            ProfileCard(
              nickname: _currentNickname,
              profileImageUrl: _currentProfileImage,
              onTap: _navigateToEditProfile,
              primaryColor: primaryColor,
            ),

            // 🌸 2. 마음 온도 카드 위젯
            MindTemperatureCard(
              score: widget.mindScore,
              primaryColor: primaryColor,
            ),
            
            const SizedBox(height: 30),
            _buildSectionTitle("계정 보안"),
            
            // 🌸 3. 설정 타일 위젯들
            SettingTile(
              icon: Icons.alternate_email_rounded,
              title: "계정",
              onTap: () {}, 
              trailingText: widget.email,
              showArrow: false,
              primaryColor: primaryColor,
            ),
            
            if (!widget.isSocial)
              SettingTile(
                icon: Icons.lock_open_rounded,
                title: "비밀번호 설정",
                onTap: _showPasswordOptions,
                primaryColor: primaryColor,
              ),

            const SizedBox(height: 20),
            _buildSectionTitle("연동 관리"),
            
            SettingTile(
              icon: Icons.logout_rounded,
              title: "로그아웃",
              onTap: _showLogoutDialog,
              primaryColor: primaryColor,
            ),
            
            SettingTile(
              icon: Icons.person_remove_outlined,
              title: "회원 탈퇴",
              onTap: widget.onDeleteAccount,
              isDestructive: true,
              primaryColor: primaryColor,
            ),
            
            const SizedBox(height: 20),
            _buildSectionTitle("앱 설정"),
            
            // 알림 스위치는 상태(Switch)가 포함되어 내부 메서드로 유지
            _buildNotificationSwitch(),
            
            SettingTile(
              icon: Icons.info_outline_rounded,
              title: "버전 정보",
              onTap: () {}, 
              trailingText: "v$_appVersion",
              showArrow: false,
              primaryColor: primaryColor,
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
          ],
        ),
      ),
    );
  }

  // --- 내부 UI 헬퍼 위젯 ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(fontSize: 14, color: darkTextColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: scaffoldBgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.notifications_none_rounded, size: 20, color: primaryColor),
        ),
        title: const Text("알림 설정", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        value: _isNotificationEnabled,
        activeThumbColor: primaryColor,
        activeTrackColor: primaryColor.withValues(alpha: 0.3),
        onChanged: _toggleNotification,
      ),
    );
  }
}