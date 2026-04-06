// lib/config.dart

class AppConfig {
  // 1. 현재 개발 모드인지 설정 (true: 로컬 서버, false: 배포 서버)
  static const bool isDebug = false; 

  // 2. 로컬 서버 주소 (본인의 환경에 맞게 선택)
  // Android 에뮬레이터: 10.0.2.2
  // iOS 시뮬레이터: 127.0.0.1
  static const String localUrl = "http://192.168.45.154:8000";

  // 3. 배포 서버 주소
  static const String devUrl = "https://sadie-api.onrender.com";

  // 4. 최종 사용할 Base URL
  static String get baseUrl => isDebug ? localUrl : devUrl;
}