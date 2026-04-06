import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/config.dart';

// 분리한 위젯 및 유틸리티 임포트
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_field.dart';
import 'widgets/typing_indicator.dart'; // 로딩 상태 전용 위젯

class ChatScreen extends StatefulWidget {
  final String token;
  final int roomId;
  final VoidCallback onLogout;
  final String initialTitle;

  const ChatScreen({
    super.key,
    required this.token,
    required this.roomId,
    required this.onLogout,
    required this.initialTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 메시지 데이터를 담는 리스트
  final List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  late String _currentTitle;

  // 디자인 테마 설정
  final Color scaffoldBgColor = const Color(0xFFF9F8FD);
  final Color textColor = const Color.fromARGB(255, 26, 25, 25);

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.initialTitle;
    _loadHistory(); // 초기 데이터 로드
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 1. 서버에서 기존 대화 기록 가져오기
  Future<void> _loadHistory() async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/rooms/${widget.roomId}/messages'),
          headers: {'Authorization': 'Bearer ${widget.token}'});

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.clear();
          for (var m in data['messages']) {
            _messages.add({
              "role": m['role'].toString(),
              "content": m['content'].toString(),
              "isAnimating": false // 기존 기록은 타이핑 애니메이션 제외
            });
          }
        });
        _scrollToBottom();
      } else if (response.statusCode == 401) {
        widget.onLogout();
      }
    } catch (e) {
      debugPrint("History Load Error: $e");
    }
  }

  // 2. 메시지 전송 및 AI 응답 처리
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    final userMessage = {
      "role": "user",
      "content": text,
      "isAnimating": false
    };

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}'
        },
        body: jsonEncode({
          'room_id': widget.roomId,
          'message': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add({
            "role": "assistant",
            "content": data['ai_response'],
            "isAnimating": true // 새 응답에는 타이핑 효과 적용
          });
        });
      } else {
        debugPrint("Chat API Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Send Message Error: $e");
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  // 리스트 최하단으로 스크롤 이동
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _currentTitle,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 채팅 메시지 리스트 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                // AI가 응답을 생성 중일 때 표시할 인디케이터
                if (index == _messages.length) {
                  return const TypingIndicator();
                }

                // 일반 메시지 말풍선
                return ChatBubble(
                  message: _messages[index],
                  onType: _scrollToBottom,
                  onComplete: () {
                    // 애니메이션 완료 시 상태 업데이트 (중복 실행 방지)
                    setState(() {
                      _messages[index]['isAnimating'] = false;
                    });
                  },
                );
              },
            ),
          ),
          // 하단 입력창 위젯
          ChatInputField(
            controller: _controller,
            isSending: _isSending,
            onSubmitted: _sendMessage,
          ),
        ],
      ),
    );
  }
}