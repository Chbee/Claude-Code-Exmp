# Phase A — Foundation (도메인 모델 + MVI 코어 + Toast)

> 브랜치: `phase/a-foundation`
> 목표: UI 없이 계산기 로직과 인프라를 완성. Reducer가 순수 함수라 마일스톤 4 테스트 기반이 됨.

---

## 구현 목표

1. 도메인 모델 정의 (Currency, Operator)
2. 유틸리티 (Decimal+Format, Preview+ColorScheme)
3. 전역 상태 인프라 (AppStore, AppCurrencyStore)
4. 계산기 MVI 코어 (State, Intent, Reducer, Store, DisplayModel)
5. Toast 인프라 (ToastManager, ToastPayload, ToastStyle, ToastView, ToastModifier)
6. 앱 진입점 연결 (TravelCalculatorApp, ContentView → CalculatorView 스텁)

---

## 태스크 목록

### Step 1: 도메인 모델

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `Domain/Models/Currency.swift` | Currency enum (KRW/USD/TWD), symbol/flag/countryName/fractionDigits | Spec-DataModel §5.2 |
| 1.2 | `Domain/Models/Operator.swift` | Operator enum (plus/minus/multiply/divide) | Spec-DataModel §5.1 |

### Step 2: 유틸리티

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `Core/Extensions/Decimal+Format.swift` | `formatDecimal(maxFractionDigits:)` — 로케일 고정(. / ,), 천단위 구분 | Spec-Architecture §7.1 |
| 2.2 | `Core/Extensions/Preview+ColorScheme.swift` | `previewWithColorSchemes()` — 라이트/다크 나란히 프리뷰 | Spec-Architecture §7.2 |

### Step 3: 전역 상태

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `Core/App/AppCurrencyStore.swift` | @Observable, selectedCurrency/conversionDirection UserDefaults 저장, ExchangeRateStatus enum, ConversionDirection enum, fromCurrency/toCurrency computed | Spec-DataModel §5.9 |
| 3.2 | `Core/App/AppStore.swift` | @Observable, hasCompletedOnboarding (UserDefaults), AppCurrencyStore 보유 | Spec-Architecture §4.3 |

### Step 4: 계산기 MVI

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 4.1 | `Presentation/Calculator/CalculatorState.swift` | CalculatorState struct — display, pendingOperator, isEnteringNewNumber, previousValue, lastOperand, lastOperator, isInputLimitExceeded, pendingToast | Spec-DataModel §5.4 |
| 4.2 | `Presentation/Calculator/CalculatorIntent.swift` | CalculatorIntent enum 전체 케이스 | Spec-DataModel §5.3 |
| 4.3 | `Presentation/Calculator/CalculatorReducer.swift` | 순수 함수. 아래 모든 엣지 케이스 처리 | Spec-Overview §2.1 |
| 4.4 | `Presentation/Calculator/CalculatorStore.swift` | @Observable. Reducer 호출 + Toast 사이드이펙트 | Spec-Architecture §4.2 |
| 4.5 | `Presentation/Calculator/CalculatorDisplayModel.swift` | CalculatorDisplayModel + CurrencyAmountDisplayModel | Spec-DataModel §5.5, §5.6 |

#### CalculatorReducer 처리 목록 (Spec-Overview §2.1.5)

| 케이스 | 처리 |
|--------|------|
| 숫자 입력 — 정수부 10자리 초과 | Toast(warning) + 햅틱 + 입력 차단 |
| 소수점 중복 | 무시 |
| 소수점 첫 입력 시 display="0" | "0."으로 자동 완성 |
| 소수점 이하 3자리 이상 | 입력 차단 |
| 연산자 연속 입력 | 마지막 연산자로 교체 |
| `=` 단독 (pendingOperator=nil) | 무시 |
| `=` 연속 입력 | lastOperator + lastOperand로 반복 |
| `=` 후 숫자 입력 | 새 계산 시작 |
| `=` 후 연산자 입력 | 결과값 → previousValue |
| 연산자 후 `=` (피연산자 없이) | display값을 피연산자로 사용 (`5+=` → 10) |
| 0으로 나누기 | Toast(warning, "0으로 나눌 수 없습니다") + 상태 유지 |
| `=` 결과 정수부 15자리 초과 | Toast(error, "계산 결과가 너무 큽니다") + 이전 display 유지 |
| 음수 결과 | display에는 표시. 환율 변환 결과는 0 + Toast |
| AC | 전체 리셋 |
| C | display만 "0". pendingOperator/previousValue 유지 |
| AC/C 토글 조건 | display="0" AND pendingOperator=nil → AC 표시 |
| 백스페이스: 한 자리 | → "0" |
| 백스페이스: "0." | → "0" |
| 백스페이스: "0" | 무시 |
| 백스페이스: = 직후 | 결과 한 자리씩 삭제 |
| resetForCurrencyChange | display="0", 모든 연산 상태 nil |

### Step 5: Toast 인프라

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 5.1 | `Presentation/Common/Toast/ToastStyle.swift` | ToastStyle enum (success/info/warning/error), 색상 + 지속시간 | Spec-Overview §2.6.1 |
| 5.2 | `Presentation/Common/Toast/ToastPayload.swift` | ToastPayload struct (style, title, message, duration) | Spec-DataModel §5.7 |
| 5.3 | `Presentation/Common/Toast/ToastManager.swift` | @Observable. show(:) 메서드. 큐 관리 | Spec-Overview §2.6.2 |
| 5.4 | `Presentation/Common/Toast/ToastView.swift` | SwiftUI View. 스타일별 색상, 상단 safe area | Spec-Overview §2.6.2 |
| 5.5 | `Presentation/Common/Toast/ToastModifier.swift` | ViewModifier. .toast(manager:) extension | Spec-Overview §2.6.2 |

### Step 6: 앱 진입점 연결

| # | 파일 | 태스크 |
|---|------|--------|
| 6.1 | `TravelCalculatorApp.swift` | AppStore, ToastManager 생성 및 @EnvironmentObject 주입 |
| 6.2 | `ContentView.swift` | CalculatorView 스텁 연결 (실제 UI는 Phase B에서) |

---

## 완료 기준

- [x] `xcodebuild` 빌드 성공 (warning 0, error 0)
- [x] CalculatorReducer: 모든 엣지 케이스 코드 구현 완료
- [x] Toast: style별 색상 + 지속시간 반영
- [x] AppStore/AppCurrencyStore: UserDefaults 저장 동작 확인
- [x] Decimal+Format: 소수점 `.` / 천단위 `,` 로케일 고정

---

## 파일 구조 (생성 예정)

```
TravelCalculator/
├── Core/
│   ├── App/
│   │   ├── AppStore.swift                   ← NEW
│   │   └── AppCurrencyStore.swift           ← NEW
│   └── Extensions/
│       ├── Decimal+Format.swift             ← NEW
│       └── Preview+ColorScheme.swift        ← NEW
├── Domain/
│   └── Models/
│       ├── Currency.swift                   ← NEW
│       └── Operator.swift                   ← NEW
└── Presentation/
    ├── Calculator/
    │   ├── CalculatorState.swift            ← NEW
    │   ├── CalculatorIntent.swift           ← NEW
    │   ├── CalculatorReducer.swift          ← NEW
    │   ├── CalculatorStore.swift            ← NEW
    │   └── CalculatorDisplayModel.swift     ← NEW
    └── Common/
        └── Toast/
            ├── ToastStyle.swift             ← NEW
            ├── ToastPayload.swift           ← NEW
            ├── ToastManager.swift           ← NEW
            ├── ToastView.swift              ← NEW
            └── ToastModifier.swift          ← NEW
```

---

## 다음 Phase

Phase B (`phase/b-calculator-ui`): 계산기 UI (CalculatorView, CalculatorKeypad, CalculatorDisplay, CalculatorToolbar) + 통화 선택 UI
