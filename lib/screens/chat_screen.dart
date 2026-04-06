// lib/screens/chat_screen.dart

import 'typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'typing_markdown.dart';
import 'package:frontend/config.dart'; 

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
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  
  // 1. 메시지 관리를 위한 리스트 (Map 대신 명확한 구조 사용)
  final List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  late String _currentTitle; 

  // 파스텔 테마 컬러 (RoomList와 통일)
  final Color primaryColor = const Color.fromARGB(255, 182, 144, 253); 
  final Color userBubbleColor = const Color(0xFFFFF9C4); // 파스텔 옐로우
  final Color assistantBubbleColor = Colors.white; // AI 말풍선
  final Color scaffoldBgColor = const Color(0xFFF9F8FD); 
  final Color textColor = const Color.fromARGB(255, 26, 25, 25);

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.initialTitle;
    _loadHistory();
  }

  // 1. 대화 기록 불러오기
  Future<void> _loadHistory() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/rooms/${widget.roomId}/messages'), 
        headers: {'Authorization': 'Bearer ${widget.token}'}
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.clear();
          // 과거 기록은 애니메이션 없이(false) 로드
          for (var m in data['messages']) {
            _messages.add({
              "role": m['role'].toString(), 
              "content": m['content'].toString(),
              "isAnimating": false 
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

  // 2. 메시지 전송
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    setState(() { 
      _messages.add({
        "role": "user", 
        "content": text, 
        "isAnimating": false
      }); 
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
          'message': text
        })
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() { 
          _messages.add({
            "role": "assistant", 
            "content": data['ai_response'],
            "isAnimating": true // 새 메시지는 타이핑 애니메이션 적용
          }); 
        });
      } else {
        debugPrint("Chat Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Send Message Error: $e");
    } finally { 
      setState(() => _isSending = false); 
      _scrollToBottom(); 
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
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
        title: Text(_currentTitle, 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 메시지 리스트 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                
                // 1. AI 응답 대기 중 로딩 인디케이터 (수정된 부분)
                if (index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: assistantBubbleColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      // 점 애니메이션 위젯 사용
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 4),
                        child: TypingIndicator(dotColor: Colors.grey),
                      ),
                    ),
                  );
                }
                
                // 2. 일반 메시지 처리
                final m = _messages[index];
                final bool isUser = m['role'] == 'user';
                final bool shouldAnimate = m['isAnimating'] == true;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? userBubbleColor : assistantBubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75
                    ),
                    child: shouldAnimate
                        ? TypingMarkdown(
                            data: m['content']!,
                            onType: _scrollToBottom,
                            onComplete: () {
                              setState(() { m['isAnimating'] = false; });
                            },
                          )
                        : MarkdownBody(
                            data: m['content']!,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: textColor.withValues(alpha: 0.85),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          
          // 하단 입력창 영역 (기존과 동일)
          _buildInputArea(),
        ],
      ),
    );
  }

  // 가독성을 위해 입력창 영역을 별도 위젯으로 분리해서 관리하면 좋습니다.
  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, 
              offset: const Offset(0, -2)
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0F7),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: textColor),
                  decoration: const InputDecoration(
                    hintText: "따뜻한 이야기를 들려주세요...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (value) => _sendMessage(value),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(_controller.text),
              child: CircleAvatar(
                backgroundColor: primaryColor,
                radius: 22,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}