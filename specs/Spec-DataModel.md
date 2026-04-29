# TravelCalculator 기획서 — 데이터 모델

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [개요/Toast/온보딩](Spec-Overview.md) | [계산기/환율 변환](Spec-Calculator.md) | [환율/통화/오프라인](Spec-ExchangeRate.md) | [화면 설계](Spec-UI.md) | [아키텍처](Spec-Architecture.md) | [태스크](Spec-Tasks.md)

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

    var symbol: String         // ₩ $ ¥ 元 € NT$ ฿ ₫ ₱
    var flag: String           // 🇰🇷 🇺🇸 🇯🇵 🇨🇳 🇪🇺 🇹🇼 🇹🇭 🇻🇳 🇵🇭
    var countryName: String    // 대한민국 / 미국 / 일본 / 중국 / 유럽연합 / 대만 / 태국 / 베트남 / 필리핀
    var currencyName: String   // 대한민국 원 / 미국 달러 / 일본 엔 / 중국 위안 / 유로 / 대만 달러 / 태국 바트 / 베트남 동 / 필리핀 페소
    var currencyUnit: String   // rawValue
    var fractionDigits: Int    // 0자리: KRW/JPY/VND, 2자리: USD/CNY/EUR/TWD/THB/PHP
    var countryCodes: [String] // ISO 3166-1 alpha-2 — EUR만 다중(eurozone 19개국)
}

extension Currency: Codable { ... }   // singleValueContainer rawValue
```

`CaseIterable` 순서가 통화 선택 화면 표시 순서에 직결.

**순서 규칙 (여행 도메인 우선):**
- 홈 통화(KRW) → 한국인 인기 여행지 → 글로벌 기축 → 기타

**확정 순서**
`KRW · JPY · VND · THB · PHP · CNY · TWD · USD · EUR`

**근거 데이터 출처**
- 한국관광공사(KTO) 한국인 출국 통계 — https://kto.visitkorea.or.kr/kor/notice/data/statis/tstatus/forn/notice/inout.kto
- KOSIS 국가통계포털 출국자 통계 — https://kosis.kr/statHtml/statHtml.do?orgId=350&tblId=DT_KTO_OBSE_018
- 출국자 수 상위 여행지 순서로 정렬 (2024-2025 기준)

**새 통화 추가 절차**
1. 통화 분류 결정: 홈 / 인기 여행지 / 글로벌 기축 / 기타
2. 분류별 위치에 인기순으로 삽입
3. PR 설명에 KTO/KOSIS 데이터 인용 또는 디자이너/PM 합의 흔적 첨부
4. `Currency.swift` case 순서, `Spec-DataModel §5.2` 표, `Spec-Overview §2.3.1` 표 동시 갱신

⚠️ **현 코드 순서**: `KRW · USD · JPY · CNY · EUR · TWD · THB · VND · PHP` — spec과 불일치, 정합화 작업 대기 중

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
| EUR | DE, FR, IT, ES, NL, BE, AT, PT, IE, FI, GR, LU, SK, SI, EE, LV, LT, MT, CY |
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
    let duration: TimeInterval  // SSOT: ToastStyle.duration. init 시 override 가능

    init(style: ToastStyle, title: String, message: String, duration: TimeInterval? = nil) {
        self.style = style
        self.title = title
        self.message = message
        self.duration = duration ?? style.duration
    }
}
```

`duration` 단일 출처: `ToastStyle.duration` (Spec-Overview §2.6.1 표 참조).
- 기본값: 호출자가 `duration`을 지정하지 않으면 `style.duration` 사용
- 인스턴스별 override: 호출자가 명시적으로 다른 값 전달 가능 (예외 케이스)
- §2.6.1 표 변경 시 `ToastStyle.swift`만 수정, spec은 미러

### 5.8 ExchangeRate / 5.9 AppCurrencyStore / 5.11 Protocol 인터페이스

네트워크/환율/Protocol 데이터 모델은 [Spec-DataModel-Network](Spec-DataModel-Network.md) 참조.

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

