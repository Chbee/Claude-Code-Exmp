# TravelCalculator 기획서 — 아키텍처 & 유틸리티

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [MVI 룰](Spec-MVI.md) | [개요/Toast/온보딩](Spec-Overview.md) | [계산기/환율 변환](Spec-Calculator.md) | [환율/통화/오프라인](Spec-ExchangeRate.md) | [화면 설계](Spec-UI.md) | [데이터 모델](Spec-DataModel.md) | [태스크](Spec-Tasks.md)

---

## 4. 아키텍처

### 4.1 MVI (Model-View-Intent) 패턴

```
View → Intent → Reducer(순수) → Store(@Observable) → View
```

- **Reducer**: 순수 함수 `(State, Intent) -> State` — 사이드 이펙트/비결정적 호출 금지
- **Store**: `@Observable` — 상태 보유, Reducer 호출, 사이드 이펙트(네트워크/IO/Toast/햅틱) 처리, 비결정적 값(Date/UUID) 생성

상세 룰(허용/금지 목록, 리팩터링 예시, 검증 가능 항목)은 [Spec-MVI](Spec-MVI.md) 참조.

### 4.2 모듈 구조

#### Calculator MVI
| 파일 | 역할 |
|------|------|
| CalculatorView | SwiftUI 화면 |
| CalculatorState | UI 상태 (display, pendingOperator, previousValue 등) |
| CalculatorIntent | 사용자 액션 (numberPressed, operatorPressed, equalsPressed 등) |
| CalculatorReducer | 순수 함수 — State + Intent → 새 State |
| CalculatorStore | @Observable — 상태 보유 + 사이드 이펙트 처리 |
| CalculatorDisplay | 디스플레이 영역 컴포넌트 |
| CalculatorDisplayModel | 디스플레이 데이터 (inputDisplay, resultDisplay, rateDisplay) |
| CalculatorKeypad | 숫자/연산 키패드 컴포넌트 |
| CalculatorToolbar | 상단 툴바 컴포넌트 |

#### CurrencySelect MVI
| 파일 | 역할 |
|------|------|
| CurrencySelectView | 통화 선택 화면 (온보딩/일반 모드 공용) |
| CurrencySelectState | 상태 (currencies, locationPermission, isSearchingLocation) |
| CurrencySelectIntent | 액션 (selectCurrency, requestLocation 등) |
| CurrencySelectStore | 상태 관리 + 위치/권한 서비스 연동 |

### 4.3 전역 상태

```
TravelCalculatorApp
├── AppStore (전역 앱 상태)
│   ├── AppCurrencyStore (통화 + 환율 상태)
│   │   ├── selectedCurrency: Currency         (UserDefaults 저장)
│   │   ├── conversionDirection: ConversionDirection  (UserDefaults 저장)
│   │   ├── exchangeRateStatus: ExchangeRateStatus
│   │   ├── fromCurrency (computed)
│   │   └── toCurrency (computed)
│   └── hasCompletedOnboarding: Bool           (UserDefaults 저장)
└── ToastManager (전역 Toast 관리)

↓ @EnvironmentObject로 주입

ContentView → CalculatorView
├── CalculatorStore(toastManager, currencyStore)
└── CurrencySelectStore(toastManager, currencyStore)
```

**ExchangeRateStatus:**
```swift
enum ExchangeRateStatus {
    case loading
    case loaded(ExchangeRateResponse)
    case error(ExchangeRateError)
}
```

**Store 간 협력 (auto-tracking)**

`CalculatorStore`가 `AppCurrencyStore`에서 읽는 프로퍼티 (computed `displayModel`을 통해 `@Observable` 자동 추적):
- `selectedCurrency`, `currentRate`, `conversionDirection`, `fromCurrency`, `toCurrency`

**명시적 반응 트리거** (`CalculatorView.onChange(of:)`)
- `selectedCurrency` 변경 → `calculatorStore.send(.resetForCurrencyChange)` 발행 (state 리셋)
- `networkState` 변경 (`offline → online` 복귀) → `currentResponse == nil`이면 자동 재시도(`loadExchangeRates()`) + pulse 애니메이션(throttle 10s, Spec-Overview §2.5.3)

**통화 변경 시 흐름:**
1. `CurrencySelectStore.selectCurrency()` → `AppCurrencyStore.selectedCurrency` 업데이트
2. `CalculatorView.onChange(of: currencyStore.selectedCurrency)`가 변화 감지
3. `calculatorStore.send(.resetForCurrencyChange)` Intent 발행 → Reducer가 state 리셋

**Cross-store observe 룰**
- Store는 **다른 Store를 직접 observe하지 않음** (`withObservationTracking`, `Combine.sink` 등 직접 구독 금지)
- 반응형 동작은 항상 **View의 `onChange(of:)` → Store에 Intent 발행** 경로를 거침
- Store가 다른 Store에서 값을 읽는 것(`currencyStore.currentRate` 등)은 허용 — `@Observable` 자동 추적이 SwiftUI 갱신을 처리

**검증 가능 항목** (결재 에이전트용)
- 새 cross-store 의존성 추가 시 위 프로퍼티 목록을 spec에 동시 갱신
- Store 파일에서 `withObservationTracking` / `Combine` / `sink` / `assign(to:)` 직접 구독 grep 결과 0건

### 4.4 폴더 구조

```
TravelCalculator/
├── TravelCalculatorApp.swift
├── ContentView.swift
├── Assets.xcassets/
├── Config/
│   └── APIKeys.swift              (.gitignore)
│
├── Core/
│   ├── App/
│   │   ├── AppStore.swift
│   │   └── AppCurrencyStore.swift
│   ├── Extensions/
│   │   ├── Decimal+Format.swift
│   │   └── Preview+ColorScheme.swift
│   └── Haptic.swift
│
├── Domain/
│   ├── Models/
│   │   ├── Currency.swift
│   │   └── Operator.swift
│   └── Protocols/
│       ├── ExchangeRateAPIProtocol.swift
│       └── CurrentCountryCodeProvider.swift
│
├── Data/
│   ├── Network/
│   │   └── ExchangeRateAPI.swift
│   ├── Location/
│   │   └── LocationService.swift
│   └── Permission/
│       ├── PermissionService.swift
│       └── LocationPermissionService.swift
│
└── Presentation/
    ├── Calculator/
    │   ├── CalculatorView.swift
    │   ├── CalculatorState.swift
    │   ├── CalculatorIntent.swift
    │   ├── CalculatorReducer.swift
    │   ├── CalculatorStore.swift
    │   ├── CalculatorDisplay.swift
    │   ├── CalculatorDisplayModel.swift
    │   ├── CalculatorKeypad.swift
    │   └── CalculatorToolbar.swift
    ├── CurrencySelect/
    │   ├── CurrencySelectView.swift
    │   ├── CurrencySelectState.swift
    │   ├── CurrencySelectIntent.swift
    │   └── CurrencySelectStore.swift
    ├── Error/
    │   └── ExchangeRateErrorView.swift
    ├── Components/
    │   └── IconButton.swift
    └── Common/
        └── Toast/
            ├── ToastManager.swift
            ├── ToastPayload.swift
            ├── ToastView.swift
            ├── ToastStyle.swift
            └── ToastModifier.swift
```

---

## 7. 유틸리티

### 7.1 Decimal+Format
```swift
extension Decimal {
    func formatDecimal(maxFractionDigits: Int) -> String
    // 1234.5 → "1,234.5" (천단위 구분자 포함)
    // 항상 locale 고정: 소수점 ".", 천단위 ","
}
```

### 7.2 Preview+ColorScheme
```swift
extension View {
    func previewWithColorSchemes() -> some View
    // 라이트/다크 모드 나란히 프리뷰
}
```
