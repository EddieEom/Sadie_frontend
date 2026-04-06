import 'package:flutter/material.dart';

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final String? trailingText;
  final bool showArrow;
  final Color primaryColor;

  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.primaryColor,
    this.isDestructive = false,
    this.trailingText,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : const Color(0xFFF9F8FD),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isDestructive ? Colors.redAccent : primaryColor),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.redAccent : const Color.fromARGB(255, 26, 25, 25),
              ),
            ),
            const Spacer(),
            if (trailingText != null)
              Text(
                trailingText!,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            if (!showArrow && trailingText != null) const SizedBox(width: 8),
          ],
        ),
        trailing: showArrow 
            ? Icon(Icons.chevron_right_rounded, color: Colors.grey[400]) 
            : null,
      ),
    );
  }
}