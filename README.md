# Sadie 프론트엔드

LLM 파인튜닝에 관심을 갖고 혼자 진행한 Sadie 프로젝트의 Flutter 앱입니다. 서버에 메시지를 보내고 AI 응답과 대화 기록을 화면에서 확인하도록 만들었습니다.

## 프로젝트 배경

처음에는 LLaMA 3.1을 연결하고, AI Hub 데이터를 JSONL로 변환해 일부 데이터로 학습을 시도했습니다. 학교의 A100 GPU 2개가 장착된 서버를 사용했지만 기대한 한국어 응답 개선은 확인하지 못했습니다.

초기 모델 학습 실험과 현재 앱의 외부 LLM API 연동은 별도의 내용입니다. 자세한 진행 과정과 한계는 [백엔드 README](https://github.com/EddieEom/Sadie-backend)에서 정리했습니다.

## 주요 화면

- 로그인과 회원가입
- 채팅방 목록과 대화 화면
- 사용자 프로필과 계정 관리
- 서버에서 받은 감정 관련 데이터 표시

앱이 동작하는 것은 확인했지만, 현재 모든 화면과 기능을 다시 점검한 상태는 아닙니다. AI 응답과 감정 관련 결과의 정확도를 검증한 기록도 없습니다.

## 사용 기술

Flutter, Dart, REST API, JWT, Google 로그인, 로컬 토큰 저장

## 다룬 내용

사용자 입력을 서버 API로 보내고 응답을 화면에 표시하는 과정, 로그인 상태 관리, 채팅 기록 조회를 진행했습니다.

## 실행 방법

### 1. Clone Repository

```bash
git clone https://github.com/EddieEom/Sadie_frontend.git
cd Sadie_frontend
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Check Flutter Environment

```bash
flutter doctor
```

### 4. Run

```bash
flutter run
```

앱 실행 전에 백엔드 서버 주소와 로그인 관련 설정을 개발 환경에 맞게 확인해야 합니다.

## 관련 저장소

[Sadie 백엔드](https://github.com/EddieEom/Sadie-backend)
