import 'package:flutter/material.dart';

class MindTemperatureCard extends StatelessWidget {
  final double score;
  final Color primaryColor;

  const MindTemperatureCard({
    super.key,
    required this.score,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // 온도에 따른 상태 정의
    Color tempColor = primaryColor;
    String statusText = "따뜻하고 안정적인 상태예요.";
    
    if (score >= 39.0) {
      tempColor = Colors.orangeAccent;
      statusText = "마음이 조금 과열되었네요. 휴식이 필요해요.";
    } else if (score <= 35.0) {
      tempColor = Colors.lightBlueAccent;
      statusText = "마음이 조금 차가워졌어요. Sadie가 안아드릴게요.";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("현재 마음 온도", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text("${score.toStringAsFixed(1)}°C", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tempColor)),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (score / 45.0).clamp(0.1, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tempColor.withValues(alpha: 0.5), tempColor],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(statusText, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}