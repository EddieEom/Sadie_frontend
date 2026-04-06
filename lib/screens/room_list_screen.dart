import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';
import 'my_page_screen.dart';
import 'package:frontend/config.dart'; // API URL을 별도의 파일로 분리

class RoomListScreen extends StatefulWidget {
  final String token;
  final VoidCallback onLogout;
  final bool isSocial;
  final String email;
  final String? initialUserId; // 👈 추가: 초기 유저 ID 전달받는 변수
  final String nickname;
  
  const RoomListScreen({
    super.key, 
    required this.token, 
    required this.onLogout, 
    required this.isSocial, 
    required this.email, 
    required this.nickname, 
    this.initialUserId
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
  // 2. [삽입] 사용자 정보를 저장할 변수들
  String _nickname = "상담가"; // 초기값 (나중에 서버 데이터로 변경)
  String? _profileImageUrl; // 프로필 이미지 URL

  // [색상 통합 섹션] - 파스텔 라벤더 테마로 변경
  final Color primaryColor = const Color.fromARGB(255, 182, 144, 253); // 부드러운 라벤더
  final Color scaffoldBgColor = const Color(0xFFF9F8FD); // 연보라빛 화이트
  final Color cardColor = Colors.white; 
  final Color accentColor = const Color(0xFFF3E5F5); // 아이콘용 연한 퍼플
  final Color darkTextColor = const Color.fromARGB(255, 26, 25, 25); // 가독성 높은 짙은 퍼플

@override
void initState() {
  super.initState();
  _userId = widget.initialUserId;
  _loadInitialData(); // 👈 두 함수를 묶어서 관리하는 게 안전합니다.
}


// 2. 마음 온도 API 호출 함수 추가
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
    debugPrint("--- [ERROR] 마음 온도 로딩 실패: $e ---");
  }
}

Future<void> _loadInitialData() async {
  setState(() => _isLoading = true);
  try {
    // 두 정보를 모두 가져올 때까지 기다립니다.
    await Future.wait([
      _fetchRooms(),
      _fetchUserProfile(),
      _fetchMoodData(),
    ]);
  } catch (e) {
    debugPrint("데이터 로딩 중 에러: $e");
  } finally {
    if (mounted) {
      setState(() => _isLoading = false); // 👈 여기서 로딩 바를 확실히 제거
    }
  }
}

  // 6. 유저 프로필 정보 가져오기 (GET)
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
      // utf8.decode를 사용하여 한글 깨짐 방지
      final decodedData = jsonDecode(utf8.decode(response.bodyBytes));
      
      // 서버 응답 구조가 {"status": "success", "data": {...}} 이므로 접근 방식 수정
      if (decodedData['status'] == 'success') {
        final userData = decodedData['data']; 
        
        setState(() {
          _userId = userData['id']?.toString() ?? userData['user_id']?.toString();
          _nickname = userData['nickname'] ?? "상담가";
          _profileImageUrl = userData['profile_image'];
          // 필요하다면 여기서 is_social 값 등을 업데이트 할 수도 있습니다.
        });
        
        debugPrint("--- [DEBUG] 유저 프로필 로드 성공: $_nickname ---");
      }
    } else if (response.statusCode == 401) {
      widget.onLogout(); // 토큰 만료 시 로그아웃 처리
    }
  } catch (e) {
    debugPrint("--- [ERROR] 프로필 정보 로딩 실패: $e ---");
  }
}

  // 3. [삽입] 마이페이지로 이동하는 함수
 void _navigateToMyPage() async {
    // 👈 중요: 여전히 null일 경우를 대비한 안전장치
    if (_userId == null) {
      _showSnackBar("사용자 정보를 확인 중입니다. 잠시 후 다시 시도해주세요.");
      _fetchUserProfile(); // 다시 시도
      return;
    }

  // 2. 모든 데이터가 있을 때만 페이지 이동
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
        onDeleteAccount: () {
          _showDeleteAccountDialog();
          debugPrint("계정 탈퇴 시도");
        },
      ),
    ),
  );
  
  _loadInitialData(); 
}

  // 1. 방 목록 불러오기 (GET)
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
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        widget.onLogout();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("방 목록을 불러오지 못했습니다.");
    }
  }

  // 2. 방 제목 변경 (PUT)
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
        _showSnackBar("제목이 변경되었습니다.");
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _showSnackBar(data['detail'] ?? "변경 실패");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류가 발생했습니다.");
    }
  }

  // 3. 방 생성 (POST)
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

  // 4. 방 삭제 (DELETE)
  Future<void> _deleteRoom(int roomId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/rooms/$roomId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        _fetchRooms();
      } else {
        _showSnackBar("삭제 권한이 없거나 오류가 발생했습니다.");
      }
    } catch (e) {
      _showSnackBar("삭제 오류가 발생했습니다.");
    }
  }

  // 5. 회원 탈퇴 (DELETE)
  Future<void> _handleDeleteAccount(String password) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/delete-account'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("탈퇴가 완료되었습니다.");
        widget.onLogout();
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _showSnackBar(data['detail'] ?? "탈퇴 오류");
      }
    } catch (e) {
      _showSnackBar("네트워크 오류");
    }
  }

  // --- 다이얼로그 및 UI 헬퍼 ---

  void _showRenameDialog(int roomId, String oldTitle) {
    final controller = TextEditingController(text: oldTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("상담 제목 수정", style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller, 
          autofocus: true, 
          decoration: InputDecoration(
            hintText: "제목을 입력하세요",
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _renameRoom(roomId, controller.text.trim());
            },
            child: Text("저장", style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

void _showDeleteAccountDialog() {
    final pwConfirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("회원 탈퇴", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 소셜 유저 여부에 따른 안내 문구 변경
            Text(
              widget.isSocial 
                ? "구글 계정으로 로그인 중입니다.\n탈퇴 시 상담 데이터는 즉시 삭제되며 복구할 수 없습니다."
                : "보안을 위해 비밀번호를 입력해주세요.\n데이터는 즉시 삭제되며 복구할 수 없습니다.", 
              style: const TextStyle(fontSize: 14)
            ),
            
            // 일반 유저일 때만 비밀번호 입력창 표시
            if (!widget.isSocial) ...[
              const SizedBox(height: 15),
              TextField(
                controller: pwConfirmController, 
                obscureText: true, 
                decoration: const InputDecoration(
                  labelText: "비밀번호",
                  labelStyle: TextStyle(color: Colors.grey),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
                )
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 소셜 유저라면 빈 문자열을 보냄 (백엔드에서 is_social=True면 비번 체크 안 함)
              _handleDeleteAccount(widget.isSocial ? "" : pwConfirmController.text.trim());
            }, 
            child: const Text("탈퇴", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)), 
        behavior: SnackBarBehavior.floating, 
        backgroundColor: darkTextColor.withAlpha(230),
        duration: const Duration(seconds: 2)
      )
    );
  }

  // // --- [추가] 설정 메뉴를 보여주는 바텀시트 함수 ---
  // void _showSettingsBottomSheet() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
  //     ),
  //     backgroundColor: cardColor,
  //     builder: (context) => SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 20),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // 바텀시트 상단 핸들
  //             Container(
  //               width: 40,
  //               height: 4,
  //               margin: const EdgeInsets.only(bottom: 20),
  //               decoration: BoxDecoration(
  //                 color: Colors.grey[300],
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //             if (!widget.isSocial)
  //               _buildMenuTile(Icons.lock_reset_rounded, "비밀번호 변경", () {
  //                 Navigator.pop(context);
  //                 Navigator.push(context, MaterialPageRoute(
  //                   builder: (context) => PasswordChangeScreen(token: widget.token)
  //                 ));
  //               }),
  //             _buildMenuTile(Icons.logout_rounded, "로그아웃", () {
  //               Navigator.pop(context);
  //               widget.onLogout();
  //             }),
  //             _buildMenuTile(Icons.person_remove_outlined, "회원탈퇴", () {
  //               Navigator.pop(context);
  //               _showDeleteAccountDialog();
  //             }, isDestructive: true),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
  //   return ListTile(
  //     leading: Icon(icon, color: isDestructive ? Colors.redAccent : darkTextColor),
  //     title: Text(
  //       title, 
  //       style: TextStyle(
  //         color: isDestructive ? Colors.redAccent : darkTextColor,
  //         fontWeight: FontWeight.w500
  //       )
  //     ),
  //     onTap: onTap,
  //   );
  // }
  
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: scaffoldBgColor,
    appBar: AppBar(
      backgroundColor: scaffoldBgColor,
      elevation: 0,
      toolbarHeight: 0,
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // 👈 상단 정렬로 변경 (프로필과 높이 맞춤)
                  children: [
                    // 1. 텍스트 영역을 Expanded로 감싸서 Overflow 방지
                    Expanded( 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "나의 상담실",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: darkTextColor),
                          ),
                          const SizedBox(height: 8),
                          // 최신 요약 브리핑 표시 영역
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _latestBrief,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: darkTextColor.withValues(alpha: 0.7)),
                              // 👈 글자가 길어지면 다음 줄로 넘어가도록 설정
                              softWrap: true, 
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16), // 2. 텍스트와 프로필 사이 간격 확보

                    // 3. 프로필 아이콘 영역
                    GestureDetector(
                      onTap: _navigateToMyPage,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: accentColor,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: _profileImageUrl == null
                              ? Icon(Icons.person_rounded,
                                  color: primaryColor, size: 28)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                // 방 목록 영역
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchRooms,
                    color: primaryColor,
                    backgroundColor: cardColor,
                    child: _rooms.isEmpty
                        ? ListView( // Empty state에서도 스크롤(Refresh) 가능하게 함
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                              const Center(
                                child: Text(
                                  "새로운 대화를 시작해보세요.",
                                  style: TextStyle(color: Colors.grey)
                                )
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 110, left: 18, right: 18, top: 10),
                            itemCount: _rooms.length,
                            itemBuilder: (context, index) {
                              final room = _rooms[index];
                              final roomId = room['id'];
                              final currentTitle = room['title'] ?? '상담 진행 중';

                              return Dismissible(
                                key: Key(roomId.toString()),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  // 삭제 전 확인 절차 추가 (사용자 실수 방지)
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("상담 삭제"),
                                      content: const Text("이 상담 기록을 삭제할까요?\n삭제된 데이터는 복구할 수 없습니다."),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) => _deleteRoom(roomId),
                                background: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF9A9A).withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: const Icon(Icons.delete_forever_outlined, color: Colors.white, size: 30),
                                ),
                                child: _buildRoomCard(room, roomId, currentTitle),
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
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("새 상담 시작", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  // 리스트 아이템 빌더 분리 (가독성)
  Widget _buildRoomCard(dynamic room, int roomId, String currentTitle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: accentColor,
          child: Icon(Icons.spa_rounded, color: primaryColor, size: 26),
        ),
        title: Text(
          currentTitle,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: darkTextColor),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            "상담 시작: ${room['created_at'].toString().substring(0, 10)}",
            style: TextStyle(color: darkTextColor.withValues(alpha: 0.4), fontSize: 13),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: primaryColor.withValues(alpha: 0.3), size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => ChatScreen(
            token: widget.token,
            roomId: roomId,
            onLogout: widget.onLogout,
            initialTitle: currentTitle,
          )
        )).then((_) => _fetchRooms()),
        onLongPress: () => _showRenameDialog(roomId, currentTitle),
      ),
    );
  }
}