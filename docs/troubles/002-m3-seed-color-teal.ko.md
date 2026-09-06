# 트러블슈팅: 무채색을 시드로 준 ColorScheme이 청록색이 되는 문제

> 작성일: 2026-09-06
> 관련 문서: [시프트표 구현 상세서](../implementation/shift-table.ko.md)

---

## 증상

색을 명시하지 않은 위젯이, 앱 디자인(검정~회색 기조)과 무관한 **청록색**으로 그려지고 있었다.

* `修正依頼 N件`의 `OutlinedButton`(글자와 테두리)
* 충돌 해결 다이얼로그의 `OutlinedButton` / `TextButton`
* 삭제 중에 나오는 `CircularProgressIndicator`
* `Switch`, 드롭다운 하이라이트, 텍스트 선택 핸들 등

색을 개별 지정하지 않은 곳에만 나와서 처음에는 「지정 누락」으로 보였지만, 해당 위치가 광범위하게 흩어져 있었다.

---

## 원인

`main.dart`의 테마 정의.

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: AppColors.accentPrimary,  // #2C2C2C
),
```

`AppColors.accentPrimary`는 `#2C2C2C`로 **거의 무채색**이다. Material 3의 `fromSeed`는 시드 색을 HCT 색공간으로 변환한 뒤 거기서 **색상(hue)을 추출해** 토널 팔레트를 생성한다. 무채색은 색상이 정의되지 않으므로 임의의 값이 채택되고, 거기에 기본 채도가 더해진다.

그 결과 `colorScheme.primary`가 **`#006874`(청록)** 이 되어 있었다. M3에서 검정이나 회색을 시드로 주면 청록이 나오는 것은 알려진 함정이다.

`primary`는 색을 명시하지 않은 위젯의 기본색으로 널리 참조되므로, 지정 누락된 모든 위치가 이 청록을 물려받고 있었다.

---

## 대처

채도를 낮추는 변형을 지정한 뒤, 실제로 화면에 나오는 롤을 `AppColors`로 직접 덮어썼다.

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: AppColors.accentPrimary,
  dynamicSchemeVariant: DynamicSchemeVariant.neutral,
).copyWith(
  primary: AppColors.accentPrimary,
  onPrimary: AppColors.textPrimaryLight,
  secondary: AppColors.accentSecondary,
  onSecondary: AppColors.textPrimaryLight,
  surface: AppColors.cardBackground,
  onSurface: AppColors.textPrimary,
  tertiary: AppColors.accentSecondary,
  onTertiary: AppColors.textPrimaryLight,
  error: AppColors.error,
  onError: AppColors.textPrimaryLight,
  outline: AppColors.border,
  surfaceTint: AppColors.accentPrimary,
),
```

### `surfaceTint`를 잊지 말 것

`neutral` 변형을 지정해도 `surfaceTint`는 `#516164`로 청록 기가 남는다. M3는 이 색으로 **elevation이 있는 Card / Dialog / Menu의 배경을 착색**하므로, 지정하지 않으면 다이얼로그에 옅은 청록이 깔린다.

### 모든 롤을 명시하지 않은 이유

`primaryContainer`나 `secondaryContainer`는 덮어쓰지 않았다. 앱 내의 `Chip` / `ChoiceChip` / `ActionChip`은 모두 `backgroundColor` / `selectedColor`를 직접 지정하고 있어 이 롤들을 소비하지 않기 때문이다. 모든 롤을 적어 내리면 M3 내부의 정합성(대비비 확보 등)이 깨지므로, **화면에 나오는 롤만 덮어쓰는** 방침으로 했다.

---

## 검증 방법

`ColorScheme` 각 롤의 채도(RGB의 max-min)를 출력해 확인했다. 수정 후 화면에 나오는 롤은 전부 채도 0이 되었다.

| 롤 | 수정 전 | 수정 후 |
|---|---|---|
| `primary` | `#006874` | `#2C2C2C` |
| `secondary` | `#4A6267` | `#424242` |
| `surfaceTint` | `#516164` | `#2C2C2C` |
| `outline` | `#6F797A` | `#EAEAEA` |

---

## 교훈

* **무채색을 디자인 기조로 삼은 앱에서 `ColorScheme.fromSeed`를 그대로 쓰면 안 된다.** 시드에서 색상을 복원할 수 없어 의도치 않은 색상이 섞여 들어온다.
* 「색을 지정하지 않은 곳」은 생각보다 많다. 테마의 기본색은 반드시 한 번 실제 값을 출력해 확인한다.
* `surfaceTint`는 `primary`와 별개의 롤이므로, `primary`만 덮어써도 따라오지 않는다.
