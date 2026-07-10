# 아키텍처 개요

> 최종 수정: 2026-07-10

## 기술 스택

| 항목 | 기술 |
|------|------|
| Framework | Flutter |
| State Management | Provider |
| Authentication | Firebase Auth |
| HTTP Client | `http` 패키지 |
| Data Visualization | `fl_chart` |
| Local Database | `sqflite`, `shared_preferences` |
| Hardware | `mobile_scanner` (QR), `pdf` & `printing` (영수증) |

---

## 디렉토리 구조

```
lib/
├── models/               # JSON 파싱용 데이터 모델 클래스 (WaitingList, Store 등)
├── pages/                # 화면 단위 폴더 (UI 및 ViewModel 포함)
│   ├── waiting_page/     # 실시간 대기 관리 (SSE 기반)
│   ├── statistics_page/  # 통계 대시보드
│   ├── menu_management_page/ # 메뉴 추가/수정
│   ├── staff_management_page/# 직원 권한 관리
│   └── store_selection/  # 점포 선택/QR 연동
│
├── services/             # 비즈니스 로직 및 API 통신 캡슐화
│   ├── waiting_service.dart    # SSE 연결 및 멱등성 보장 로직
│   └── statistics_service.dart # 별도 Isolate JSON 파싱 로직
│
├── utils/                # 날짜 포맷 변환 등 헬퍼 함수
├── widgets/              # 재사용 UI 컴포넌트
├── constants/            # 색상(AppColors), API 엔드포인트 환경 변수
├── routes.dart           # GoRouter 기반 라우팅
└── main.dart             # 앱 진입점 및 전역 Provider 설정
```

---

## 데이터 흐름

```
Flutter UI (Pages)
    │
    ▼ (Event / User Action)
ViewModel (ChangeNotifier)
    │
    ▼ (Method Call)
Service Layer (services/*.dart)
    │
    ├── (REST) ──▶ Backend API (fly.io) ──▶ MongoDB
    ├── (SSE) ◀── 백엔드 실시간 푸시 데이터 수신
    └── (Local) ─▶ SQLite / SharedPreferences 캐싱
```

### 아키텍처 특징: MVVM 패턴

- **Model**: `lib/models/`에 위치하며, 백엔드 API 통신 응답과 일치하는 순수 데이터 객체.
- **View**: `lib/pages/` 내의 `*_screen.dart`. 오직 UI 렌더링에만 집중.
- **ViewModel**: `*_viewmodel.dart`. 비즈니스 로직과 화면 상태(`isLoading`, `error`, 데이터 리스트)를 관리하며, 상태 변경 시 `notifyListeners()`로 View 갱신. `Provider`를 통해 주입.
