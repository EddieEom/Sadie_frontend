class WeeklyReport {
  final int id;
  final String summary;
  final int moodScore;
  final DateTime createdAt;

  WeeklyReport({
    required this.id,
    required this.summary,
    required this.moodScore,
    required this.createdAt,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      id: json['id'],
      summary: json['summary'] ?? "리포트 내용이 없습니다.",
      moodScore: json['mood_score'] ?? 50,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}