# 📱 Yoyaku Mate - 파트너 매장용 어플리케이션 (Flutter App)

> **Yoyaku Mate** 파트너용 앱은 매장을 운영하는 점주 및 직원을 위한 **대기열 관리 및 매장 설정 모바일/데스크톱 어플리케이션**입니다. 실시간 고객 대기 상태 관리, 메뉴 설정, 스태프 관리, 매출/대기 통계 시각화 및 티켓 인쇄 등의 백오피스 핵심 기능을 제공합니다.

---

## 🛠 Tech Stack (기술 스택)

- **Cross-Platform Framework:** Flutter (Dart)
- **State Management:** Provider (데이터 상태 전역 관리)
- **Authentication:** Firebase Auth (로그인, 회원가입, 비밀번호 재설정 및 이메일 검증)
- **Database (Local):** SQLite (`sqflite`), `shared_preferences` (로컬 데이터 캐싱 및 설정 저장)
- **Routing:** Go Router (선언적 내비게이션 라우팅)
- **AI Engine:** Google Generative AI (Gemini SDK 활용 다국어 번역 및 자동화 어시스턴트)
- **Libraries:**
  - `fl_chart` (대기 통계 차트 시각화)
  - `mobile_scanner` (고객 QR 코드 티켓 스캔 및 검증)
  - `pdf` & `printing` (대기 번호표 PDF 생성 및 영수증 프린터 호환 인쇄)
  - `flutter_slidable` (리스트 슬라이드 조작)
  - `flutter_dotenv` (환경 변수 파일 로드)

---

## ✨ Key Features (핵심 기능)

- **실시간 대기열 제어 (Queue Management):** 대기 중인 고객 호출(Push), 대기 완료 처리, 예약 취소 등을 한 터치로 실시간 제어합니다.
- **QR 티켓 리더 (QR Code Scanner):** 매장에 도착한 고객이 제시한 모바일 QR 티켓을 기기 카메라로 즉시 스캔하여 대기 상태를 검증합니다.
- **메뉴 & 카테고리 관리:** 제공되는 식사 메뉴의 추가, 삭제, 가격 설정 및 카테고리 분류를 관리합니다.
- **직원 관리 (Staff Management):** 근무 직원을 추가하고, 각 계정별로 권한을 관리합니다.
- **통계 분석 대시보드:** 일별/주별 대기 인원 통계 및 혼잡 시간대 리포트를 차트 시각화하여 확인합니다.
- **인쇄 시스템 (Ticket Printing):** 영수증/감열식 프린터와 연동하여 현장 대기자용 감열 인쇄 번호표를 발행할 수 있습니다.

---

## 📂 Project Structure (폴더 구조)

```bash
lib/
├── constants/            # API 키 정의 및 상수 모음
├── models/               # 대기열, 매장, 메뉴 등 데이터 모델 클래스
├── pages/                # 핵심 비즈니스 화면
│   ├── waiting_page/     # 실시간 대기 현황판 및 고객 호출 화면
│   ├── menu_management/  # 메뉴 리스트 및 세부 추가/수정 화면
│   ├── staff_management/ # 스태프 추가 및 역할 변경 화면
│   ├── statistics_page/  # fl_chart 기반 대시보드 통계 화면
│   ├── profile_page/     # 매장 상세 정보 및 앱 설정 화면
│   └── sign_up/          # 단계별 회원가입 화면
├── services/             # Firebase 및 백엔드 서버 연동 비즈니스 API 레이어
├── utils/                # PDF 변환, 시간 파싱 등 유틸리티 클래스
├── widgets/              # UI 가독성을 높이기 위해 잘게 쪼갠 공통 UI 위젯들
├── routes.dart           # GoRouter 기반 전체 앱 네비게이션 정의
└── main.dart             # Flutter 앱의 진입점 및 전역 프로바이더 설정
```

---

## 🚀 Getting Started (시작 가이드)

> [!IMPORTANT]
> 본 프로젝트는 보안상 Firebase 및 일부 설정 파일이 `.gitignore`에 등록되어 있어 최초 클론 후 설정 파일 생성이 필요합니다.

### 1. 설정 파일 복구
1. **Firebase 설정 파일 추가**
   - Android용: `android/app/google-services.json` 파일 배치
   - iOS용: `ios/Runner/GoogleService-Info.plist` 파일 배치
   - 또는 프로젝트 루트에서 `flutterfire configure` 명령어를 실행하여 `lib/firebase_options.dart` 파일을 생성합니다.

2. **환경 변수 파일 (`.env`) 추가**
   - 프로젝트 루트 디렉토리에 `.env`, `.env.development`, `.env.production` 파일을 생성합니다.
   ```env
   # 백엔드 서버 URL 및 AI 키 설정
   API_URL=https://rusui-dev.fly.dev
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY
   ```

### 2. 패키지 설치 및 실행
```bash
# 의존성 패키지 설치
flutter pub get

# 앱 실행
flutter run
```
또는 VS Code / Android Studio의 디바이스 툴을 활용하여 원하는 에뮬레이터나 실기기에서 실행할 수 있습니다.
