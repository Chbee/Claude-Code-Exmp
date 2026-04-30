# TravelCalculator 기획서 — MVI 패턴 룰

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [아키텍처](Spec-Architecture.md) | [개요](Spec-Overview.md)

---

## 4.1 MVI (Model-View-Intent) 패턴

```
사용자 입력
    ↓
View → Intent (사용자 액션 정의)
    ↓
Reducer (순수 함수: State + Intent → 새 State)
    ↓
Store (@Observable, 상태 관리 + 사이드 이펙트)
    ↓
View (SwiftUI 자동 렌더링)
```

사이드 이펙트는 Reducer가 아닌 Store에서 처리. (Redux/Elm/TCA 정통 입장 일치)

### Reducer 허용 (순수 함수: `(State, Intent) -> State`)
- 입력 state와 intent로부터 새 state를 계산
- `state.pendingToast` 등 "의도 데이터" 필드에 후속 트리거를 기록 (Store가 발화)

### Reducer 금지
- **사이드 이펙트**: 네트워크 / I/O / UserDefaults / 캐시 / 위치/권한 / Toast 발화 / 햅틱 / `Task` / `await`
- **비결정적 호출**: `Date.now`, `Date()`, `UUID()`, `*.random*`, `Calendar.current`, `Locale.current`, `TimeZone.current`, `ProcessInfo.processInfo` 등
  - 시간/UUID 등이 필요하면 **Store가 생성하여 Intent payload로 주입**

### Store 책임 (`@Observable`)
- Reducer 호출 + 결과 적용
- Reducer가 남긴 의도(`pendingToast` 등) 발화: Toast/햅틱 트리거
- 비동기 사이드 이펙트: 네트워크(`api.fetchRates`), 위치(`service.requestCurrentCountryCode`), UserDefaults 영속화
- **비결정적 값 생성**: `Date.now`, `UUID()` 등을 호출하여 Intent payload로 Reducer에 주입
- 다른 Store와의 협력 (예: `AppCurrencyStore` 변화 감지 → `.resetForCurrencyChange` Intent 발행)

### 리팩터링 예시 (위반 발견 시)
```swift
// ❌ Reducer에서 직접 호출
case .timestampPressed:
    s.timestamp = Date.now  // 비결정적

// ✅ Intent payload로 주입
case .timestampPressed(let now):
    s.timestamp = now

// Store 측에서 비결정적 값 주입
func handleTimestampTap() {
    send(.timestampPressed(now: Date.now))
}
```

### 검증 가능 항목 (결재 에이전트용)
- `*Reducer.swift`에서 다음 패턴 grep 결과 0건:
  - 비결정적: `Date\(\)`, `Date\.now`, `UUID\(\)`, `\.random\(`, `Calendar\.current`, `Locale\.current`, `TimeZone\.current`, `ProcessInfo\.processInfo`
  - 사이드 이펙트: `Task\s*\{`, `await\s`, `URLSession`, `FileManager`, `UserDefaults`, `ToastManager`, `Haptic\.`
- Reducer 함수 시그니처가 `(State, Intent) -> State` 형태 (외부 의존 인자 없음)
