import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final dynamic room;
  final int roomId;
  final String currentTitle;
  final Color primaryColor;
  final Color accentColor;
  final Color darkTextColor;
  final Color cardColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RoomCard({
    super.key,
    required this.room,
    required this.roomId,
    required this.currentTitle,
    required this.primaryColor,
    required this.accentColor,
    required this.darkTextColor,
    required this.cardColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            fontSize: 17, 
            fontWeight: FontWeight.w600, 
            color: darkTextColor
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            "상담 시작: ${room['created_at'].toString().substring(0, 10)}",
            style: TextStyle(
              color: darkTextColor.withValues(alpha: 0.4), 
              fontSize: 13
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded, 
          color: primaryColor.withValues(alpha: 0.3), 
          size: 16
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}