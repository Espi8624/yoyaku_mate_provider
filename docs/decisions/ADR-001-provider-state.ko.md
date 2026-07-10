# ADR-001: 상태 관리 도구로 Provider 패턴 채택

> 작성일: 2026-07-10  
> 상태: 확정

## 컨텍스트

Flutter 애플리케이션에서 여러 화면에 걸쳐 공유되는 상태(인증 상태, 현재 매장 ID, 실시간 대기열 데이터 등)를 관리해야 합니다.

---

## 검토 대상

| 방법 | 장점 | 단점 |
|------|------|------|
| BLoC / Cubit | 이벤트 기반으로 상태 추적이 매우 명확함 | 보일러플레이트 코드가 많고 학습 곡선이 높음 |
| GetX | 라우팅 및 상태 관리가 하나로 통합되어 생산성 최상 | 컨텍스트 없는 라우팅 남용 위험, 앱 구조 결합도 상승 |
| Riverpod | 컴파일 타임 에러 검출, 강력한 의존성 관리 | 문법이 다소 생소할 수 있음 (Provider의 진화형) |
| **Provider** | Flutter 공식 권장(과거), 직관적인 MVVM 패턴 지원 | 상태 업데이트 로직이 복잡해지면 UI와 결합될 수 있음 |

---

## 결정: Provider + MVVM 채택

### 이유

1. **간결한 MVVM 아키텍처 지원**: `ChangeNotifier`를 상속한 ViewModel(예: `WaitingScreenViewModel`)을 구성하고, `ChangeNotifierProvider`로 주입하는 방식이 가장 직관적이고 보일러플레이트가 적습니다.
2. **의존성 주입의 용이성**: `MultiProvider`를 통해 `ProfileService`, `WaitingService` 등 비즈니스 서비스들을 최상단(main.dart)에서 전역으로 쉽게 주입(DI)할 수 있습니다.
3. **학습 비용 대비 높은 효율**: 복잡도가 아주 높은 앱이 아니며, 단일 매장의 대기열을 관리하는 단방향 데이터 흐름이 주를 이루므로, Provider만으로 충분히 확장성 있는 코드를 작성할 수 있습니다.

### 트레이드오프

- Provider 내에서 다른 Provider의 상태를 참조해야 할 때(`ProxyProvider` 사용 등) 구성이 다소 복잡해질 수 있음. (현재 `ChangeNotifierProxyProvider`로 해결 중)
- 위젯 트리가 깊어질 때 `context.read()` / `context.watch()` 호출로 인한 불필요한 리빌드가 발생할 수 있어, 성능에 민감한 차트 그리기(`fl_chart`) 등의 경우 `Selector`를 적극 활용하여 렌더링 범위를 제한해야 함.

---

## 관련 문서

- [아키텍처 개요](../implementation/architecture.ko.md)
