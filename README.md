# 🌸 Sadie Frontend

<div align="center">

### AI Conversational Assistant Mobile Client

**사용자의 대화와 감정 기록을 기반으로 AI와 상담형 대화를 나눌 수 있는 Flutter 애플리케이션입니다.**

<br>

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)
![Google](https://img.shields.io/badge/Google%20Sign--In-4285F4?style=for-the-badge\&logo=google\&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge\&logo=firebase\&logoColor=black)

</div>

<br>

---

# 📌 Project Overview

**Sadie**는 사용자가 자신의 고민과 감정을 기록하고
AI와 지속적인 대화를 나눌 수 있도록 개발한 Conversational Assistant입니다.

이 저장소는 Sadie 서비스의 **Flutter Mobile Client**이며,

* 사용자 인증
* Google 로그인
* 로그인 상태 유지
* 프로필 설정
* 상담방 관리
* AI 대화
* 대화 기록 조회
* 마음 온도 확인
* 계정 및 앱 설정

등의 사용자 인터페이스와 Backend API 연동을 담당합니다.

Backend는 별도의 FastAPI 서버로 구성되어 있습니다.

👉 [Sadie Backend](https://github.com/EddieEom/Sadie-backend)

<br>

---

# 🏗️ Application Flow

```text
App Start
   │
   ▼
Secure Storage Token Check
   │
   ├── Token 없음 ───────────▶ Login / Sign Up
   │
   └── Token 있음
          │
          ▼
    Backend Token Validation
          │
          ├── Invalid ───────▶ Login
          │
          └── Valid
                 │
                 ▼
          Profile Check
                 │
          ┌──────┴───────┐
          │              │
   Nickname 없음      Profile 완료
          │              │
          ▼              ▼
      Onboarding     Room List
                         │
                         ▼
                     Chat Room
                         │
                         ▼
                   AI Conversation
```

앱 실행 시 저장된 Access Token을 확인하고
Backend의 사용자 API를 통해 실제 토큰 유효성을 다시 검증합니다.

인증이 완료된 이후 사용자 프로필 상태에 따라
Onboarding 또는 상담방 목록 화면으로 이동합니다.

<br>

---

# ✨ Main Features

## 🔐 Authentication

### Email Authentication

* 회원가입 / 로그인 UI
* Backend JWT Authentication 연동
* Access Token 기반 사용자 인증
* 로그아웃 처리
* 만료된 Token 자동 제거

### Google Sign-In

* `google_sign_in` 패키지 기반 Google OAuth
* Google ID Token 획득
* Backend Google Authentication API 연동
* Social Account와 일반 계정 구분

### Persistent Login

`flutter_secure_storage`를 이용해 Access Token을 안전하게 저장합니다.

앱 재실행 시

```text
Secure Storage
      ↓
Access Token
      ↓
Backend /users/me
      ↓
Token Validation
      ↓
Automatic Login
```

흐름으로 자동 로그인을 처리합니다.

<br>

---

# 👤 Onboarding & Profile

최초 로그인 후 사용자 프로필이 설정되지 않은 경우
Onboarding 화면으로 이동합니다.

### Features

* 닉네임 설정
* 프로필 이미지 설정
* 기존 Google Profile Image 활용
* 사용자 Profile API 연동
* 프로필 수정 기능

`image_picker`를 활용하여 사용자가 직접 프로필 이미지를 선택할 수 있으며,
Backend의 Supabase Storage와 연결되어 프로필 이미지가 관리됩니다.

<br>

---

# 💬 Conversation Room

사용자는 여러 개의 상담방을 생성하고 관리할 수 있습니다.

### Room Management

* 상담방 목록 조회
* 새로운 상담방 생성
* 상담방 삭제
* 상담방 이름 변경
* Pull-to-Refresh
* 상담방 선택 후 Chat Screen 이동

상담방 삭제는 Flutter `Dismissible`을 활용해
Swipe UX로 구현했습니다.

```text
Room List
   │
   ├── Create
   ├── Rename
   ├── Delete
   │
   └── Select
          │
          ▼
      Chat Screen
```

<br>

---

# 🤖 AI Chat

상담방 내부에서 Sadie AI와 대화를 진행합니다.

### Conversation Flow

```text
User Message
     │
     ▼
Flutter Client
     │
     ▼
POST /chat
     │
     ▼
FastAPI Backend
     │
     ▼
AI / RAG Pipeline
     │
     ▼
AI Response
     │
     ▼
Flutter Chat UI
```

### Features

* 기존 Conversation History 자동 조회
* 사용자 메시지 즉시 UI 반영
* Backend AI API 호출
* AI Response 표시
* 대화 종료 후 자동 Scroll
* 응답 생성 중 Typing Indicator
* 새로운 AI 답변에 Typing Animation 적용
* JWT 기반 상담방 접근 인증

사용자가 상담방에 진입하면 기존 메시지를 먼저 불러오고
새로운 메시지만 별도의 타이핑 애니메이션과 함께 표시하도록 구성했습니다.

<br>

---

# 🌡️ Mind Temperature

Sadie Backend에서 분석된 사용자 데이터를 기반으로
현재 사용자의 **마음 온도(Mind Temperature)**를 화면에 표시합니다.

```text
Conversation / Mood Data
          ↓
       Backend
          ↓
 Weekly AI Analysis
          ↓
    Mind Temperature
          ↓
     Flutter Client
```

메인 화면에서는 최신 분석 요약을 확인할 수 있고,
마이페이지에서는 현재 마음 온도를 별도의 카드 UI로 확인할 수 있습니다.

<br>

---

# 👤 My Page

사용자 계정과 앱 설정을 관리할 수 있는 화면입니다.

### Profile

* Profile Image
* Nickname
* Profile Edit

### Account

* 사용자 Email 확인
* 비밀번호 변경
* 비밀번호 재설정
* 로그아웃
* 회원 탈퇴

Social Account 여부에 따라
일반 계정에서만 비밀번호 관리 메뉴가 표시되도록 구성했습니다.

### Application Settings

* 알림 설정
* 앱 Version 표시

알림 설정 상태는 `SharedPreferences`를 통해 로컬에 저장하며,
`package_info_plus`를 이용해 현재 앱 버전을 동적으로 조회합니다.

<br>

---

# 🎨 UI / UX

Sadie는 상담 서비스의 분위기에 맞춰
밝고 부드러운 Pastel Purple 기반 UI를 사용했습니다.

```text
Primary
#B690FD

Background
#F9F8FD

Surface
#FFFFFF
```

### UI Components

기능이 커지면서 Screen 내부에 모든 UI를 작성하는 대신
반복되는 요소를 별도의 Widget으로 분리했습니다.

예시:

```text
Chat
├── ChatBubble
├── ChatInputField
└── TypingIndicator

Room List
├── RoomHeader
└── RoomCard

My Page
├── ProfileCard
├── MindTemperatureCard
└── SettingTile
```

이를 통해 Screen은 데이터 흐름과 화면 상태를 담당하고
세부 UI는 재사용 가능한 Widget이 담당하도록 구성했습니다.

<br>

---

# ⚙️ Tech Stack

## Mobile

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)

<br>

## Authentication

![Google](https://img.shields.io/badge/Google%20Sign--In-4285F4?style=for-the-badge\&logo=google\&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge\&logo=firebase\&logoColor=black)

`JWT Authentication`
`Google OAuth`
`Flutter Secure Storage`

<br>

## Communication

![REST API](https://img.shields.io/badge/REST%20API-009688?style=for-the-badge)

`HTTP` `JSON` `Bearer Token`

<br>

## Local Storage

`Flutter Secure Storage`
`SharedPreferences`

<br>

---

# 📦 주요 Packages

| Package                  | Purpose                     |
| ------------------------ | --------------------------- |
| `http`                   | FastAPI Backend REST API 통신 |
| `flutter_secure_storage` | JWT Access Token 저장         |
| `google_sign_in`         | Google OAuth                |
| `firebase_core`          | Firebase 초기 설정              |
| `image_picker`           | 사용자 Profile Image 선택        |
| `shared_preferences`     | 앱 설정 값 저장                   |
| `package_info_plus`      | 앱 Version 조회                |
| `flutter_markdown`       | Markdown Content Rendering  |

<br>

---

# 📂 Project Structure

```text
lib/
│
├── main.dart
│
├── config.dart
│
├── core/
│
├── models/
│
├── services/
│   ├── auth_service.dart
│   └── analysis_service.dart
│
└── presentation/
    └── screens/
        │
        ├── auth/
        │   ├── auth_screen.dart
        │   ├── onboarding_screen.dart
        │   └── widgets/
        │
        ├── room_list/
        │   ├── room_list_screen.dart
        │   └── widgets/
        │
        ├── chat/
        │   ├── chat_screen.dart
        │   └── widgets/
        │
        └── mypage/
            ├── my_page_screen.dart
            ├── sub_screens/
            └── widgets/
```

UI를 `presentation`, 외부 인증 기능을 `services`,
데이터 객체를 `models` 등으로 분리하여 프로젝트 구조를 관리했습니다.

<br>

---

# 🔗 Backend Integration

Sadie Frontend는 FastAPI 기반 Backend와 REST API로 통신합니다.

### 주요 API Flow

```text
Authentication
POST /login
POST /signup
POST /auth/google

User
GET  /users/me
POST /users/me/profile
GET  /users/me/mood-chart

Chat Room
GET    /rooms
POST   /rooms
PUT    /rooms/{room_id}/title
DELETE /rooms/{room_id}

Chat
GET  /rooms/{room_id}/messages
POST /chat
```

대부분의 사용자 API 요청에는 다음과 같이 JWT가 포함됩니다.

```http
Authorization: Bearer <ACCESS_TOKEN>
```

<br>

---

# 🖥️ Backend

Sadie Backend에서는 다음 기능을 담당합니다.

* FastAPI REST API
* PostgreSQL
* JWT Authentication
* Google Authentication
* Conversation Management
* LLM API Integration
* Embedding
* pgvector Vector Search
* RAG
* Weekly AI Report
* Supabase Storage

👉 **Backend Repository**
https://github.com/EddieEom/Sadie-backend

<br>

---

# 🚀 Getting Started

## 1. Clone Repository

```bash
git clone https://github.com/EddieEom/Sadie_frontend.git
cd Sadie_frontend
```

## 2. Install Dependencies

```bash
flutter pub get
```

## 3. Check Flutter Environment

```bash
flutter doctor
```

## 4. Run

```bash
flutter run
```

<br>

---

# 🎯 What I Learned

Sadie Frontend를 개발하며 단순한 Flutter UI 구현을 넘어
**Backend와 연결되는 실제 Mobile Application의 데이터 흐름**을 경험하는 것을 목표로 했습니다.

특히 다음 내용을 직접 구현하며 학습했습니다.

* Flutter ↔ FastAPI REST API Integration
* JWT 기반 로그인 상태 관리
* Secure Storage를 활용한 자동 로그인
* Google OAuth 연동
* 사용자 상태에 따른 화면 Flow 제어
* 비동기 API 요청 및 UI State 관리
* Chat History와 AI Response UI 구성
* Widget 단위 UI 분리 및 재사용
* 사용자 Profile / Account Management
* Backend AI 분석 데이터를 Mobile UI에 연결

이를 통해

```text
User Interaction
      ↓
Flutter Client
      ↓
REST API
      ↓
Backend
      ↓
Database / AI
      ↓
API Response
      ↓
Flutter UI
```

로 이어지는 **서비스 전체의 데이터 흐름**을 경험했습니다.

<br>

---

# 👨‍💻 Developer

**Eddie Eom**

GitHub
https://github.com/EddieEom

<br>

---

# 📎 Related Repository

### Sadie Backend

https://github.com/EddieEom/Sadie-backend
