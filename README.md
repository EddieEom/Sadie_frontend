# Sadie 프론트엔드

LLM 파인튜닝에 관심을 갖고 혼자 진행한 Sadie 프로젝트의 Flutter 앱입니다. 서버에 메시지를 보내고 AI 응답과 대화 기록을 화면에서 확인하도록 만들었습니다.

## 프로젝트 배경

모델 학습에 대한 관심에서 시작해, 사용자가 메시지를 입력하고 AI 응답을 확인할 수 있는 앱으로 연결했습니다. 초기 LLaMA 학습 실험에서는 AI Hub 데이터 전처리와 학교 A100 서버를 활용한 학습 실행을 경험했습니다.

초기 모델 학습 실험과 현재 앱의 외부 LLM API 연동은 별도의 내용입니다. 학습 실험 과정과 결과는 [백엔드 README](https://github.com/EddieEom/Sadie-backend)에서 정리했습니다.

## 주요 화면

- 로그인과 회원가입
- 채팅방 목록과 대화 화면
- 사용자 프로필과 계정 관리
- 서버에서 받은 감정 관련 데이터 표시

개발 당시 앱과 서버를 연결해 대화 동작을 확인했습니다. AI 응답과 감정 관련 결과의 품질 평가는 후속 과제로 두고 있습니다.

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
