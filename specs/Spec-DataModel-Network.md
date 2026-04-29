# TravelCalculator 기획서 — 데이터 모델 (네트워크/환율/Protocol)

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [데이터 모델](Spec-DataModel.md) | [환율/통화/오프라인](Spec-ExchangeRate.md) | [아키텍처](Spec-Architecture.md)

---

## 5.8 ExchangeRate

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

## 5.9 AppCurrencyStore 상태

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

## 5.11 Protocol 인터페이스

```swift
protocol ExchangeRateAPIProtocol {
    /// 지정한 통화들에 대해 KRW 환산 환율을 조회.
    /// - Parameter currencies: 조회 대상 통화 집합. KRW는 base 통화이므로 자동 제외(전달돼도 무시).
    /// - Returns: 입력 통화 중 정상 환율을 가진 통화만 포함하는 응답. 비정상 통화는 제외(Spec-ExchangeRate §2.4.6 참조).
    /// - Throws: `noDataAvailable` — 결과 통화가 0개일 때 (빈 입력 또는 전부 비정상).
    func fetchRates(for currencies: [Currency]) async throws -> ExchangeRateResponse
}

@MainActor
protocol CurrentCountryCodeProvider {
    /// 현재 위치의 ISO 3166-1 alpha-2 국가 코드 반환.
    /// 호출자는 `Currency.from(countryCode:)`로 통화 매핑 (Spec-ExchangeRate §2.3.4 참조).
    /// - Throws: `LocationError.permissionDenied` (권한 거부), `.unavailable` (조회 실패/타임아웃)
    func requestCurrentCountryCode() async throws -> String
}

enum LocationError: Error, Sendable {
    case permissionDenied
    case unavailable
}
```

**계약 (검증 가능 항목):**
- `fetchRates`: 빈 배열 전달 → `noDataAvailable` throw
- `fetchRates`: KRW를 포함해 전달해도 결과에 KRW 없음 (base이므로 자동 제외)
- 캐시 유효(`searchDate == 오늘 KST`) 시 네트워크 호출 없이 캐시 반환 (Spec-ExchangeRate §2.4.6)
- `requestCurrentCountryCode`: 통화 매핑은 호출자 책임 (Protocol은 국가 코드만 반환 — 위치/통화 매핑 관심사 분리)
