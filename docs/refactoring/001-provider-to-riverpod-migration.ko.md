# 상태관리 아키텍처 Provider(MVVM) → Riverpod + Hooks 전면 마이그레이션

> 최종 업데이트: 2026-09-01
> 관련: [ADR-001](../decisions/ADR-001-provider-state.ko.md) (이번 리팩토링으로 일부 결정이 상위 대체됨)

## 배경 및 문제점 (AS-IS)

초기에는 [ADR-001](../decisions/ADR-001-provider-state.ko.md)의 결정에 따라 `provider` 패키지 + `ChangeNotifier` 기반 MVVM 패턴으로 상태를 관리했습니다. 운영을 이어가며 다음 문제들이 드러났습니다.

1. **명령형 데이터 조회와 수동 상태 동기화**: `initState`에서 `fetchXxx()` 호출을 빼먹으면 화면이 영원히 비어있게 되고, 로딩/에러 상태도 `_isLoading`/`_errorMessage` 필드를 매번 손으로 `notifyListeners()`와 동기화해야 했습니다.

2. **스코프와 실체의 불일치("God Object"화)**: `ProfileScreenViewModel`은 `pages/profile_page/` 아래에 있고 이름도 페이지 전용처럼 보였지만, 실제로는 `main.dart` 루트에서 `ChangeNotifierProxyProvider<User?, ProfileScreenViewModel>`로 Firebase 인증 상태에 연동되어 등록돼 있었고, 로그인 유저·소유 매장 목록·선택 중인 매장·매장 설정/라이선스까지 들고 있는 앱 전체의 세션 상태였습니다. `provider` 패키지에서는 새 전역 provider를 추가할 때마다 `main.dart`의 `MultiProvider` 배선을 수정해야 해서, 그 수고를 피하려고 기존 VM에 기능을 계속 얹은 결과 책임이 비대해졌습니다.

3. **컴파일 타임에 잡히지 않는 의존성 누락**: `context.watch<T>()`/`context.read<T>()`는 `T`가 상위 트리에 등록되어 있지 않으면 런타임에 크래시가 납니다. 실제로 `main.dart`의 `MultiProvider`에서 `StoreSettingsService` 등록을 제거했을 때, 아직 마이그레이션되지 않았던 `waiting_screen.dart`가 이를 직접 참조하고 있었는데 이는 `flutter analyze`로는 잡히지 않아 수동 `grep`으로 뒤늦게 발견해야 했습니다.

## 해결책: 페이지 단위 Riverpod + Hooks 순차 마이그레이션 (TO-BE)

[enechain 기술블로그의 MVVM→선언적 아키텍처 사례](https://techblog.enechain.com/entry/flutter-rearchitecture-from-mvvm)를 참고해 `hooks_riverpod` + `riverpod_annotation`/`riverpod_generator`(codegen, `.g.dart`는 Git에 커밋)를 채택하고, 기존 `provider` 트리와 신규 `ProviderScope`를 공존시키며 페이지 단위로 순차 이전했습니다.

### 설계 원칙

| 원칙 | 내용 |
|------|------|
| 스코프 분리 | 페이지 로컬 상태는 `lib/pages/xxx/xxx_providers.dart`, 앱 전체 세션 상태(로그인 유저/소유 매장/선택 매장/매장 설정·라이선스)는 신설한 [lib/providers/session_providers.dart](../../lib/providers/session_providers.dart)에 집약 |
| Ephemeral UI 상태 | `StatefulWidget` 대신 `flutter_hooks`의 `useState`/`useTabController`/`useAppLifecycleState` 등을 사용 |
| 비동기 상태 표현 | `AsyncValue`/`FutureProvider`/`AsyncNotifier`로 로딩/에러/데이터를 선언적으로 표현하고, `_isLoading`/`_errorMessage` 수동 필드를 폐기 |
| 갱신 후 재조회 | 성공 시 `ref.invalidate(...)` 한 줄로 선언적 재조회 (Riverpod은 재조회 중에도 직전 데이터를 유지하므로 전체 화면 깜빡임이 없음) |
| 성공/실패 알림 | 액션용 Notifier는 상태를 갖지 않고(`build() {}`), 실패 시 그냥 `rethrow`. 호출부(화면)가 즉시 Toast/SnackBar 표시 |

### Before / After 예시 (`menu_management_page`)

```dart
// AS-IS: ChangeNotifier + 수동 필드 동기화
class MenuManagementScreenViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<MenuListItem> _menuItems = [];

  Future<void> loadMenuData(String storeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _menuItems = await _menuService.fetchMenuItems(storeId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

```dart
// TO-BE: AsyncNotifier + codegen — 로딩/에러는 AsyncValue가 자동 표현
@riverpod
class MenuItemsNotifier extends _$MenuItemsNotifier {
  @override
  Future<MenuManagementData> build({required String storeId}) async {
    final service = ref.watch(menuServiceProvider);
    final items = await service.fetchMenuItems(storeId);
    return MenuManagementData.recompute(items);
  }
}

// 호출부
final menuAsync = ref.watch(menuItemsNotifierProvider(storeId: storeId));
// menuAsync.isLoading / menuAsync.hasError / menuAsync.valueOrNull 로 판단
```

## 마이그레이션 순서와 페이지별 요점

| # | 페이지 / 대상 | 특이사항 |
|---|------|------|
| 1 | `staff_management_page` | 파일럿. 기본 패턴(`xxx_providers.dart` + `AsyncNotifier` + Actions)을 확립 |
| 2 | `profile_page` + 세션 상태 | `ProfileScreenViewModel`을 전면 해체해 `session_providers.dart`로 이관. `StoreSelectionViewModel`(얇은 래퍼)도 함께 제거. `store_selection`/`sign_up_page.dart`/`navigation_bar.dart`/`add_store_page.dart`도 뒤따라 마이그레이션됨 |
| 3 | `menu_management_page` | 카테고리/메뉴 목록을 하나의 불변 데이터클래스로 통합. 1초 디바운스 자동저장은 Notifier 인스턴스 필드 `Timer?` + `ref.onDispose`로 구현. `TabController`는 카테고리 개수 변화에 따라 재생성이 필요해 Hooks로 대체하지 않고 `ConsumerState` + `ref.listen`을 유지 |
| 4 | `statistics_page` | 필터 상태(기간/지표/날짜)는 `useState`(Hooks), 실제 데이터 조회는 `(storeId, period, date)`를 인자로 받는 `FutureProvider.family`라는 **Hooks와 Riverpod의 하이브리드 설계**를 처음 적용. 부수 효과로, 이미 본 기간으로 돌아갈 때 family 캐시 덕분에 재조회 없이 즉시 표시됨 |
| 5 | `waiting_page` | 가장 복잡한 마이그레이션 대상(SSE 폴링 스트림, 낙관적 업데이트 충돌 방지 플래그, 앱 라이프사이클 감지, 중복 로그인 감지). `WidgetsBindingObserver`는 `flutter_hooks`의 `useAppLifecycleState()` + `useEffect`로 대체. 매장 대기 정책(`estimatedWaitTime` 등)은 별도 재조회 없이 `session_providers.dart`의 `storeSettingsProvider`를 재사용해 중복 API 호출을 줄임 |
| 6 | `sign_up` | `provider` 패키지의 앱 전체 마지막 사용처. Firebase Auth의 전화번호 인증 콜백(`verifyPhoneNumber`의 `verificationCompleted`/`verificationFailed`/`codeSent`)이 위젯 폐기 후에도 비동기로 발화할 수 있는 문제 대응이 핵심. 마이그레이션 완료와 함께 `pubspec.yaml`에서 `provider` 패키지 자체를 제거 |

## 구현상 주의점 (향후 참고용)

- **`ref.mounted`는 riverpod 2.6.1에 존재하지 않음**: Notifier의 dispose 후 쓰기 방지는 `ref.onDispose(() => _isDisposed = true)`로 세운 자체 플래그를, 모든 상태 갱신이 거치는 헬퍼 함수 안에서 체크하는 방식으로 구현했다 (`ChangeNotifier.notifyListeners()` 오버라이드를 통한 `_isDisposed` 체크의 직접적인 대체).
- **기존 전역 `Provider<T>` 등록을 삭제하기 전엔 반드시 `grep`으로 전체 참조처를 재확인**: `flutter analyze`로는 잡히지 않는 런타임 한정 의존성 누락이 발생할 수 있다 (`waiting_screen.dart` 실제 사례).
- **페이지 폴더에 `xxx_providers.dart`가 없는 게 정상인 경우가 있음**: 그 페이지가 소유한 로컬 상태가 없으면(전부 세션 상태이거나 Hooks로 끝나는 경우) 빈 파일을 억지로 만들 필요는 없다 (예: `profile_page/`).
- **기존의 사소한 동작 특성은 마이그레이션 중 임의로 고치지 않음**: 예를 들어 `menu_management_page`의 "`addCategory`로 만든 빈 카테고리가 다른 조작 후 사라지는" 동작은, 이번 작업의 목적이 순수 아키텍처 이전이었으므로 의도적으로 그대로 유지했다.

## 기대 효과

1. **의존성 누락의 컴파일 타임 검출**: `ref.watch`/`ref.read`는 대상 provider가 없으면 빌드 자체가 실패하므로, `waiting_screen.dart`와 같은 런타임 크래시가 구조적으로 발생하기 어려워졌다.
2. **보일러플레이트 감소**: `_isLoading`/`_errorMessage` 수동 동기화가 불필요해지고, `AsyncValue`가 로딩/에러/데이터를 선언적으로 표현한다.
3. **스코프의 명확화**: 페이지 로컬 상태와 앱 전체 세션 상태가 물리적으로 다른 파일로 분리되어, `ProfileScreenViewModel`과 같은 "숨은 전역 상태"가 재발하기 어려운 구조가 됐다.
4. **의존 패키지 정리**: `provider` 패키지 의존성을 `pubspec.yaml`에서 완전히 제거하고 상태관리를 Riverpod 하나로 통일했다.

## 관련 문서

- [ADR-001: 상태관리 도구로서의 Provider 패턴 채택](../decisions/ADR-001-provider-state.ko.md) (이번 리팩토링으로 상위 대체됨)
- [아키텍처 개요](../implementation/architecture.ko.md)
