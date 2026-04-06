import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '648311520592-6knmvd8oimks3mqc2eo6ob93dastgunl.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<String?> signInWithGoogle() async {
    try {
      // [추가 포인트] 매번 계정을 선택하게 하려면 기존 인증 상태를 해제해야 합니다.
      // 단순히 signOut()만 하면 세션이 남을 수 있으므로 disconnect()가 더 확실합니다.
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect(); 
      }

      // 1. 구글 로그인 실행
      // 일부 환경에서는 signIn(context: ..., forceCodeForRefreshToken: true) 등을 활용하지만
      // 위에서 disconnect()를 해주면 대부분의 플랫폼에서 계정 선택창이 강제로 뜹니다.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // 2. 구글 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. 백엔드로 보낼 ID Token 반환
      return googleAuth.idToken; 
      
    } catch (error) {
      debugPrint("Google Sign-In Error: $error");
      return null;
    }
  }

  // 로그아웃 (단순 로그아웃)
  Future<void> signOut() => _googleSignIn.signOut();
  
  // 완전 연결 해제 (다음 로그인 시 무조건 다시 계정 선택/동의하게 함)
  Future<void> disconnect() => _googleSignIn.disconnect();
}