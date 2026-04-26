# Phase F — Currency Expansion + Search (통화 확장 + 검색)

> 브랜치: `phase/f-currency-expansion`
> 목표: 백로그 §9 High 우선순위(리뷰 1.2 / 4.2) — 지원 통화에 JPY/EUR/THB/VND/PHP/CNY 추가, CurrencySelect 화면에 검색·필터 UI 도입.

---

## 구현 목표

1. `Currency` enum 확장 — JPY, EUR, THB, VND, PHP, CNY 추가 (기호/국기/국가명/fractionDigits)
2. 위치 기반 통화 매핑(`Currency.from(countryCode:)`) 신규 통화 반영 (단일 국가 매핑이 가능한 JP/TH/VN/PH/CN; EUR은 매핑 제외)
3. `ExchangeRateAPI.currencyName(for:)` 책임을 `Currency` 모델로 이전 (exhaustive switch 부담 제거 + 단일 출처)
4. `CurrencySelectView` 검색바 추가 — 국가명/통화코드/기호 부분 일치 필터
5. 신규 통화 변환·검색 필터 단위 테스트 (Spec-Tasks §9 리뷰 1.2/4.2 회귀 방지)

---

## 태스크 목록

### Step 1: Currency 모델 확장

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `Domain/Models/Currency.swift` | 신규 case JPY/EUR/THB/VND/PHP/CNY 추가. `symbol`/`flag`/`countryName`/`fractionDigits` 분기 확장 (JPY=0, VND=0, KRW=0; 그 외 2). `currencyName: String` computed 추가 (한국어 통화명, 예: "일본 엔", "유로", "태국 바트"). `from(countryCode:)`에 JP/TH/VN/PH/CN 추가 (EU는 단일 국가 매핑 불가 — 제외). | Spec-Tasks §9 리뷰 1.2, Spec-DataModel §5.2 |
| 1.2 | `Data/Network/ExchangeRateAPI.swift` | `private currencyName(for:)` 삭제 → `currency.currencyName` 사용. (open.er-api.com는 USD 베이스로 `rates`에 모든 ISO 통화 포함하므로 신규 통화 자동 수신) | Spec-Overview §2.2.3 |

### Step 2: 검색·필터 UI

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `Presentation/CurrencySelect/CurrencySelectState.swift` | `searchQuery: String = ""` 필드 추가. `filteredCurrencies: [Currency]` computed — `searchQuery` 빈 문자열이면 `currencies` 전체, 아니면 `countryName` / `currencyName` / `currencyUnit` / `symbol` 부분 일치(공백 trim, 대소문자 무시). `currencyName` 포함 이유: "엔" 검색이 "일본 엔"에 매칭되도록 (countryName "일본"만 보면 "엔" 매칭 누락). | Spec-Tasks §9 리뷰 4.2 |
| 2.2 | `Presentation/CurrencySelect/CurrencySelectIntent.swift` | `case setSearchQuery(String)` 추가. | — |
| 2.3 | `Presentation/CurrencySelect/CurrencySelectReducer.swift` | `setSearchQuery` 처리 — `state.searchQuery = query` 만 갱신. | — |
| 2.4 | `Presentation/CurrencySelect/CurrencySelectView.swift` | 헤더 아래·`locationButton` 위에 SearchBar (`TextField` + 돋보기 아이콘 + 입력 시 우측 `xmark.circle.fill` clear 버튼). `currencyList`는 `state.filteredCurrencies` 사용. 결과 0건일 때 "검색 결과가 없습니다" empty state. | Spec-UI 디자인 시스템 (appBackground/appTextSub 톤 유지) |

### Step 3: 테스트

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `TravelCalculatorTests/ExchangeRateConversionTests.swift` | 신규 통화 변환 회귀 케이스 추가 — JPY(fractionDigits=0), EUR(2), VND(0) 각각 USD↔통화↔KRW 라운드트립 (Decimal 정밀도, 은행 반올림). | Spec-Overview §2.2 |
| 3.2 | `TravelCalculatorTests/CurrencySelectFilterTests.swift` (신규) | `CurrencySelectReducer` + `CurrencySelectState.filteredCurrencies` 단위 테스트: (a) 빈 쿼리 → 전체, (b) "일본"/"JPY"/"¥" 각각 매칭, (c) 대소문자/공백 무시, (d) 무매칭 → 빈 배열. | — |

---

## 완료 기준

- [ ] `xcodebuild build` 성공 (warning 0, error 0)
- [ ] `xcodebuild test` 성공 (Step 3 신규 테스트 포함 전 케이스 통과)
- [ ] CurrencySelectView 시뮬레이터 확인: 9개 통화(KRW 제외 8개 표시) 노출, 검색어 입력 시 실시간 필터, clear 버튼 동작, 결과 0건 empty state
- [ ] 신규 통화(예: JPY, EUR) 선택 → 계산기 화면에서 실시간 KRW 변환 정상 표시 (fractionDigits 차등 반영)
- [ ] 위치 기반 자동 설정으로 JP/TH/VN/PH/CN 국가 시 해당 통화 매핑 (EU는 fallback Toast 정상)

---

## 파일 구조 (생성/수정 예정)

```
TravelCalculator/
├── Domain/
│   └── Models/
│       └── Currency.swift                              ← MOD (Step 1, +6 cases, currencyName)
├── Data/
│   └── Network/
│       └── ExchangeRateAPI.swift                       ← MOD (Step 1, currencyName 위임)
└── Presentation/
    └── CurrencySelect/
        ├── CurrencySelectState.swift                   ← MOD (Step 2, searchQuery + filtered)
        ├── CurrencySelectIntent.swift                  ← MOD (Step 2, setSearchQuery)
        ├── CurrencySelectReducer.swift                 ← MOD (Step 2)
        └── CurrencySelectView.swift                    ← MOD (Step 2, SearchBar + empty state)

TravelCalculatorTests/
├── ExchangeRateConversionTests.swift                   ← MOD (Step 3.1, 신규 통화 케이스)
└── CurrencySelectFilterTests.swift                     ← NEW (Step 3.2)
```

---

## 다음 Phase

V1 백로그 잔여(접근성: VoiceOver/Dynamic Type, Toast 스와이프 닫기) 또는 V1+ 릴리스 준비(앱 아이콘/스토어 메타데이터).
