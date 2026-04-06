import 'package:flutter/material.dart';
import 'package:frontend/screens/password_change_screen.dart';
import 'package:frontend/screens/onboarding_screen.dart';
import 'package:frontend/screens/password_reset_screen.dart';
import 'package:package_info_plus/package_info_plus.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 

class MyPageScreen extends StatefulWidget {
  final String userId;
  final String token;
  final String email; // 추가된 이메일 필드
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
    required this.email, // 추가
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('notification_enabled') ?? true;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = value;
    });
    await prefs.setBool('notification_enabled', value);
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("로그아웃", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("정말 로그아웃 하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 취소
              child: Text("취소", style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
                widget.onLogout(); // 실제 로그아웃 로직 실행
              },
              child: const Text("로그아웃", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPasswordOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "비밀번호 설정",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text("현재 비밀번호로 변경"),
                subtitle: const Text("기존 비밀번호를 알고 있는 경우"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PasswordChangeScreen(token: widget.token)
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: const Text("비밀번호 재설정"),
                subtitle: const Text("비밀번호를 잊어버려 이메일 인증이 필요한 경우"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PasswordResetScreen(userId: widget.userId)
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
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
            // 프로필 업데이트 후 새로고침
            setState(() {
              _currentNickname = widget.nickname; // 최신 닉네임으로 업데이트
              _currentProfileImage = widget.profileImageUrl; // 최신 프로필 이미지로 업데이트
            });
          },
        ),
      ),
    );
  }

  Widget _buildMindTemperatureCard(double score) {
  // 온도에 따른 색상 정의
  Color tempColor = primaryColor;
  if (score >= 39.0) tempColor = Colors.orangeAccent; // 과열
  if (score <= 35.0) tempColor = Colors.lightBlueAccent; // 저체온

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 15,
          offset: const Offset(0, 5),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("현재 마음 온도", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text("${score.toStringAsFixed(1)}°C", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tempColor)),
          ],
        ),
        const SizedBox(height: 15),
        // 게이지 바
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // 실제 온도를 시각적으로 보여주는 바 (36.5를 중간인 50% 지점으로 계산)
            FractionallySizedBox(
              widthFactor: (score / 45.0).clamp(0.1, 1.0), // 45도를 최대치로 가정
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tempColor.withValues(alpha: 0.5), tempColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          score >= 36.0 && score <= 37.5 
            ? "따뜻하고 안정적인 상태예요." 
            : score > 37.5 ? "마음이 조금 과열되었네요. 휴식이 필요해요." : "마음이 조금 차가워졌어요. Sadie가 안아드릴게요.",
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    ),
  );
}
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
        title: Text("마이페이지", 
          style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _navigateToEditProfile,
              child: _buildProfileCard(),
            ),

            // 마음 온도 게이지 카드
            _buildMindTemperatureCard(widget.mindScore),
            
            const SizedBox(height: 30),
            _buildSectionTitle("계정 보안"),
            _buildSettingTile(
              icon: Icons.alternate_email_rounded,
              title: "계정",
              onTap: () {}, 
              trailingText: widget.email,
              showArrow: false, // 이메일은 읽기 전용
            ),
            if (!widget.isSocial)
              _buildSettingTile(
                icon: Icons.lock_open_rounded,
                title: "비밀번호 설정",
                onTap: _showPasswordOptions,
              ),

            const SizedBox(height: 20),
            _buildSectionTitle("연동 관리"),
            _buildSettingTile(
              icon: Icons.logout_rounded,
              title: "로그아웃",
              onTap: _showLogoutDialog,
            ),
            _buildSettingTile(
              icon: Icons.person_remove_outlined,
              title: "회원 탈퇴",
              onTap: widget.onDeleteAccount,
              isDestructive: true,
            ),
            
            const SizedBox(height: 20),
            _buildSectionTitle("앱 설정"),
            _buildNotificationSwitch(),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: "버전 정보",
              onTap: () {}, 
              trailingText: "v$_appVersion",
              showArrow: false, // 👈 버전 정보 우측 패딩 최적화 적용
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
          ],
        ),
      ),
    );
  }

  // --- 위젯 빌더 함수들 ---

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            backgroundImage: _currentProfileImage != null ? NetworkImage(_currentProfileImage!) : null,
            child: _currentProfileImage == null 
                ? Icon(Icons.person_rounded, size: 35, color: primaryColor) 
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentNickname,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "내 정보 수정하기 >",
                  style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        ],
      ),
    );
  }

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scaffoldBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.notifications_none_rounded, size: 20, color: primaryColor),
        ),
        title: const Text(
          "알림 설정",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        value: _isNotificationEnabled,
        activeThumbColor: primaryColor,
        activeTrackColor: primaryColor.withValues(alpha: 0.3),
        onChanged: _toggleNotification,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    String? trailingText,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // 👈 contentPadding을 통해 내부 요소들이 테두리에 너무 붙지 않게 조정
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : scaffoldBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isDestructive ? Colors.redAccent : primaryColor),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.redAccent : darkTextColor,
              ),
            ),
            const SizedBox(width: 12), // 간격 소폭 확대
            if (trailingText != null)
              Expanded(
                child: Padding(
                  // 👈 화살표가 없는 경우(버전 정보 등) 오른쪽 끝 여백을 8px 추가하여 자연스럽게 배치
                  padding: EdgeInsets.only(right: showArrow ? 0 : 8),
                  child: Text(
                    trailingText,
                    textAlign: TextAlign.end,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
        trailing: showArrow 
            ? Icon(Icons.chevron_right_rounded, color: Colors.grey[400]) 
            : null,
        // 👈 밀집도를 -2로 조정하여 요소들이 숨 쉴 공간을 확보
        visualDensity: const VisualDensity(horizontal: -2, vertical: 0),
      ),
    );
  }
}