import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/presentation/screens/chat/chat_screen.dart';
import 'package:frontend/presentation/screens/mypage/my_page_screen.dart';
import 'package:frontend/config.dart';
import './widgets/room_card.dart';
import './widgets/room_header.dart'; 

class RoomListScreen extends StatefulWidget {
  final String token;
  final VoidCallback onLogout;
  final bool isSocial;
  final String email;
  final String? initialUserId;
  final String nickname;

  const RoomListScreen({
    super.key,
    required this.token,
    required this.onLogout,
    required this.isSocial,
    required this.email,
    required this.nickname,
    this.initialUserId,
  });

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  List<dynamic> _rooms = [];
  bool _isLoading = true;
  double _mindScore = 36.5;
  String _latestBrief = "최근 대화가 없어요. Sadie와 이야기를 나눠보세요!";
  String? _userId;
  String _nickname = "상담가";
  String? _profileImageUrl;

  final Color primaryColor = const Color.fromARGB(255, 182, 144, 253);
  final Color scaffoldBgColor = const Color(0xFFF9F8FD);
  final Color cardColor = Colors.white;
  final Color accentColor = const Color(0xFFF3E5F5);
  final Color darkTextColor = const Color.fromARGB(255, 26, 25, 25);

  @override
  void initState() {
    super.initState();
    _userId = widget.initialUserId;
    _loadInitialData();
  }

  // --- API 및 비즈니스 로직 (기존과 동일) ---
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchRooms(),
        _fetchUserProfile(),
        _fetchMoodData(),
      ]);
    } catch (e) {
      debugPrint("데이터 로딩 중 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoodData() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/me/mood-chart'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedData['status'] == 'success') {
          setState(() {
            _mindScore = (decodedData['current_temp'] as num).toDouble();
            _latestBrief = decodedData['latest_brief'] ?? "최근 리포트가 없습니다.";
          });
        }
      }
    } catch (e) {
      debugPrint("마음 온도 로딩 실패: $e");
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/me'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        if (decodedData['status'] == 'success') {
          final userData = decodedData['data'];
          setState(() {
            _userId = userData['id']?.toString() ?? userData['user_id']?.toString();
            _nickname = userData['nickname'] ?? "상담가";
            _profileImageUrl = userData['profile_image'];
          });
        }
      } else if (response.statusCode == 401) {
        widget.onLogout();
      }
    } catch (e) {
      debugPrint("프로필 정보 로딩 실패: $e");
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/rooms'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _rooms = data['rooms'];
        });
      }
    } catch (e) {
      _showSnackBar("방 목록을 불러오지 못했습니다.");
    }
  }

  Future<void> _createRoom() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/rooms'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'title': '새로운 상담'}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchRooms();
      }
    } catch (e) {
      _showSnackBar("상담실 생성 중 오류가 발생했습니다.");
    }
  }

  Future<void> _deleteRoom(int roomId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/rooms/$roomId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        _fetchRooms();
      }
    } catch (e) {
      _showSnackBar("삭제 오류가 발생했습니다.");
    }
  }

  Future<void> _renameRoom(int roomId, String newTitle) async {
    if (newTitle.trim().isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/rooms/$roomId/title'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'title': newTitle}),
      );
      if (response.statusCode == 200) {
        _fetchRooms();
      }
    } catch (e) {
      _showSnackBar("네트워크 오류");
    }
  }

  void _navigateToMyPage() async {
    if (_userId == null) {
      _showSnackBar("사용자 정보를 확인 중입니다.");
      _fetchUserProfile();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyPageScreen(
          userId: _userId!,
          token: widget.token,
          email: widget.email,
          nickname: _nickname,
          profileImageUrl: _profileImageUrl,
          isSocial: widget.isSocial,
          onLogout: widget.onLogout,
          mindScore: _mindScore,
          onDeleteAccount: _showDeleteAccountDialog,
        ),
      ),
    );
    _loadInitialData();
  }

  // --- UI 헬퍼 및 다이얼로그 ---

  void _showRenameDialog(int roomId, String oldTitle) {
    final controller = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("상담 제목 수정"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _renameRoom(roomId, controller.text.trim());
            },
            child: Text("저장", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    // 마이페이지에서 사용하던 로직과 동일 (이전 코드 참조)
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                const SizedBox(height: 50),
                // 🌸 1. 헤더 위젯 사용
                RoomHeader(
                  latestBrief: _latestBrief,
                  profileImageUrl: _profileImageUrl,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  darkTextColor: darkTextColor,
                  onProfileTap: _navigateToMyPage,
                ),
                // 🌸 2. 방 목록 영역
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchRooms,
                    color: primaryColor,
                    child: _rooms.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              const Center(child: Text("새로운 대화를 시작해보세요.", style: TextStyle(color: Colors.grey))),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            itemCount: _rooms.length,
                            itemBuilder: (context, index) {
                              final room = _rooms[index];
                              final roomId = room['id'];
                              final currentTitle = room['title'] ?? '상담 진행 중';

                              return Dismissible(
                                key: Key(roomId.toString()),
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) => _deleteRoom(roomId),
                                background: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: RoomCard(
                                  room: room,
                                  roomId: roomId,
                                  currentTitle: currentTitle,
                                  primaryColor: primaryColor,
                                  accentColor: accentColor,
                                  darkTextColor: darkTextColor,
                                  cardColor: cardColor,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        token: widget.token,
                                        roomId: roomId,
                                        onLogout: widget.onLogout,
                                        initialTitle: currentTitle,
                                      ),
                                    ),
                                  ).then((_) => _fetchRooms()),
                                  onLongPress: () => _showRenameDialog(roomId, currentTitle),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRoom,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("새 상담 시작", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}