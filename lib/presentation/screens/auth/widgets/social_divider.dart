import 'package:flutter/material.dart'; // 필수: Row, Expanded, Divider 등을 사용하기 위함
import 'package:frontend/core/theme/app_colors.dart'; // 필수: AppColors.divider를 사용하기 위함

class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "또는",
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}