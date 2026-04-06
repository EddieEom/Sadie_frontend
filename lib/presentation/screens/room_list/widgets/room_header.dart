import 'package:flutter/material.dart';

class RoomHeader extends StatelessWidget {
  final String latestBrief;
  final String? profileImageUrl;
  final Color primaryColor;
  final Color accentColor;
  final Color darkTextColor;
  final VoidCallback onProfileTap;

  const RoomHeader({
    super.key,
    required this.latestBrief,
    this.profileImageUrl,
    required this.primaryColor,
    required this.accentColor,
    required this.darkTextColor,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "나의 상담실",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: darkTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    latestBrief,
                    style: TextStyle(
                      fontSize: 13,
                      color: darkTextColor.withValues(alpha: 0.7),
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onProfileTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: accentColor,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: profileImageUrl == null
                    ? Icon(Icons.person_rounded, color: primaryColor, size: 28)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}