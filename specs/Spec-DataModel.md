# TravelCalculator 기획서 — 데이터 모델

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [기능 명세](Spec-Overview.md) | [화면 설계](Spec-UI.md) | [아키텍처](Spec-Architecture.md) | [태스크](Spec-Tasks.md)

---

## 5. 데이터 모델

### 5.1 Operator (독립 enum)

```swift
enum Operator: String, CaseIterable {
    case plus, minus, multiply, divide
}
```

State와 Intent가 공유하는 독립 타입. `Domain/Models/Operator.swift`에 위치.

### 5.2 Currency

```swift
enum Currency: String, CaseIterable, Sendable {
    case KRW, USD, JPY, CNY, EUR, TWD, THB, VND, PHP

    var symbol: String         // ₩ $ ¥ ¥ € NT$ ฿ ₫ ₱
    var flag: String           // 🇰🇷 🇺🇸 🇯🇵 🇨🇳 🇪🇺 🇹🇼 🇹🇭 🇻🇳 🇵🇭
    var countryName: String    // 대한민국 / 미국 / 일본 / 중국 / 유럽연합 / 대만 / 태국 / 베트남 / 필리핀
    var currencyName: String   // 대한민국 원 / 미국 달러 / 일본 엔 / 중국 위안 / 유로 / 대만 달러 / 태국 바트 / 베트남 동 / 필리핀 페소
    var currencyUnit: String   // rawValue
    var fractionDigits: Int    // 0자리: KRW/JPY/VND, 2자리: USD/CNY/EUR/TWD/THB/PHP
    var countryCodes: [String] // ISO 3166-1 alpha-2 — EUR만 다중(EU + eurozone 19개국)
}

extension Currency: Codable { ... }   // singleValueContainer rawValue
```

`CaseIterable` 순서가 통화 선택 화면 표시 순서에 직결 (한국 여행객 인기/지역순).

`fractionDigits` 매핑:

| 자릿수 | 통화 |
|--------|------|
| 0 | KRW, JPY, VND |
| 2 | USD, CNY, EUR, TWD, THB, PHP |

`countryCodes` 매핑(`from(countryCode:)` reverse-lookup 데이터):

| Currency | countryCodes |
|----------|--------------|
| KRW | KR |
| USD | US |
| JPY | JP |
| CNY | CN |
| EUR | EU, DE, FR, IT, ES, NL, BE, AT, PT, IE, FI, GR, LU, SK, SI, EE, LV, LT, MT, CY |
| TWD | TW |
| THB | TH |
| VND | VN |
| PHP | PH |

### 5.3 CalculatorIntent

```swift
enum CalculatorIntent {
    case numberPressed(Int)
    case operatorPressed(Operator)
    case equalsPressed
    case decimalPressed
    case clearPressed          // C
    case allClearPressed       // AC
    case backspacePressed
    case resetInputLimitFlag
    case resetForCurrencyChange
}
```

### 5.4 CalculatorState

```swift
struct CalculatorState {
    var display: String = "0"
    var pendingOperator: Operator?
    var isEnteringNewNumber: Bool = true
    var previousValue: Decimal?
    var lastOperand: Decimal?          // = 반복 시 마지막 피연산자
    var lastOperator: Operator?        // = 반복 시 마지막 연산자
    var isInputLimitExceeded: Bool = false
    var pendingToast: ToastPayload?
}
```

### 5.5 CalculatorDisplayModel

```swift
struct CalculatorDisplayModel {
    let inputDisplay: CurrencyAmountDisplayModel
    let resultDisplay: CurrencyAmountDisplayModel
    let exchangeRate: Decimal

    var rateDisplay: String  // "1 USD = 1,350.00 KRW"
}
```

### 5.6 CurrencyAmountDisplayModel

```swift
struct CurrencyAmountDisplayModel {
    let currencyCode: String    // "USD"
    let symbol: String          // "$"
    let flag: String            // "🇺🇸"
    let formattedAmount: String // "1,350,000"
}
```

### 5.7 ToastPayload

```swift
struct ToastPayload {
    let style: ToastStyle
    let title: String
    let message: String
    var duration: TimeInterval  // style별 차등
}
```

### 5.8 ExchangeRate

```swift
struct ExchangeRate: Codable {
    let currencyCode: String
    let currencyName: String
    let rate: Decimal
}

struct ExchangeRateResponse: Codable {
    let rates: [ExchangeRate]
    let fetchedAt: Date
    let searchDate: String     // "2026-04-04"
    let validUntil: Date
}
```

### 5.9 AppCurrencyStore 상태

```swift
@Observable class AppCurrencyStore {
    var selectedCurrency: Currency      // UserDefaults 저장
    var conversionDirection: ConversionDirection  // UserDefaults 저장
    var exchangeRateStatus: ExchangeRateStatus

    enum ExchangeRateStatus {
        case loading
        case loaded(ExchangeRateResponse)
        case error(ExchangeRateError)
    }

    enum ConversionDirection: String, Codable {
        case selectedToKRW
        case krwToSelected
    }
}
```

### 5.10 Permission

```swift
enum PermissionStatus {
    case notDetermined, granted, denied
}

struct CurrencySelectState {
    var currencies: [Currency] = Currency.allCases
    var locationPermission: PermissionStatus = .notDetermined
    var isSearchingLocation: Bool = false
}
```

### 5.11 Protocol 인터페이스

```swift
protocol ExchangeRateAPIProtocol {
    func fetchRates(for currencies: [Currency]) async throws -> ExchangeRateResponse
}

protocol LocationServiceProtocol {
    func requestCurrentCurrency() async throws -> Currency
}
```
