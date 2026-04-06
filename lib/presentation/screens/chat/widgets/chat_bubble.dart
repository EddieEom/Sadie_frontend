import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import './typing_markdown.dart'; // 기존 파일 경로에 맞게 수정 필요

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onType;
  final VoidCallback onComplete;

  const ChatBubble({
    super.key,
    required this.message,
    required this.onType,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['role'] == 'user';
    final bool shouldAnimate = message['isAnimating'] == true;
    final Color userBubbleColor = const Color(0xFFFFF9C4);
    final Color assistantBubbleColor = Colors.white;
    final Color textColor = const Color.fromARGB(255, 26, 25, 25);

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
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: shouldAnimate
            ? TypingMarkdown(
                data: message['content']!,
                onType: onType,
                onComplete: onComplete,
              )
            : MarkdownBody(
                data: message['content']!,
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
  }
}