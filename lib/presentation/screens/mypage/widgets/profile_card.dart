import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String nickname;
  final String? profileImageUrl;
  final VoidCallback onTap;
  final Color primaryColor;

  const ProfileCard({
    super.key,
    required this.nickname,
    this.profileImageUrl,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color darkTextColor = const Color.fromARGB(255, 26, 25, 25);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // 프로필 이미지 영역
            CircleAvatar(
              radius: 35,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              backgroundImage: profileImageUrl != null 
                  ? NetworkImage(profileImageUrl!) 
                  : null,
              child: profileImageUrl == null 
                  ? Icon(Icons.person_rounded, size: 35, color: primaryColor) 
                  : null,
            ),
            const SizedBox(width: 20),
            
            // 닉네임 및 수정 안내
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: darkTextColor
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "내 정보 수정하기 >",
                    style: TextStyle(
                      fontSize: 13, 
                      color: primaryColor, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}