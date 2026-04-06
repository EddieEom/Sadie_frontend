import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final Function(String) onSubmitted;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 182, 144, 253);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
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
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "따뜻한 이야기를 들려주세요...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: isSending ? null : onSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isSending ? null : () => onSubmitted(controller.text),
              child: CircleAvatar(
                backgroundColor: isSending ? Colors.grey : primaryColor,
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