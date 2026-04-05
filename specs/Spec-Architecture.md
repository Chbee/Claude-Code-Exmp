# TravelCalculator 기획서 — 아키텍처 & 유틸리티

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [기능 명세](Spec-Overview.md) | [화면 설계](Spec-UI.md) | [데이터 모델](Spec-DataModel.md) | [태스크](Spec-Tasks.md)

---

## 4. 아키텍처

### 4.1 MVI (Model-View-Intent) 패턴

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

사이드 이펙트(API 호출, 위치 조회 등)는 Reducer가 아닌 Store에서 처리.

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

**통화 변경 시 흐름:**
1. `CurrencySelectStore.selectCurrency()` → `AppCurrencyStore.selectedCurrency` 업데이트
2. `CalculatorStore`가 `AppCurrencyStore` 변화를 감지 (`@Observable` 자동 추적)
3. `CalculatorStore`가 `.resetForCurrencyChange` Intent 발행 → Reducer가 state 리셋

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
│       └── LocationServiceProtocol.swift
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
