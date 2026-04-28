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
| 2.1 | `Presentation/CurrencySelect/CurrencySelectState.swift` | `searchQuery: String = ""` 필드 추가. `filteredCurrencies: [Currency]` computed — `searchQuery` 빈 문자열이면 `currencies` 전체, 아니면 `countryName` / `currencyUnit` 부분 일치(공백 trim, 대소문자 무시). `currencyName`/`symbol`은 매칭 범위 제외 (사용자 결정 2026-04-28 — "엔"·"¥" 같은 token-only 검색은 의도적 비매칭으로 통화 식별성 명확하게 유지). | Spec-Tasks §9 리뷰 4.2 |
| 2.2 | `Presentation/CurrencySelect/CurrencySelectIntent.swift` | `case setSearchQuery(String)` 추가. | — |
| 2.3 | `Presentation/CurrencySelect/CurrencySelectReducer.swift` | `setSearchQuery` 처리 — `state.searchQuery = query` 만 갱신. | — |
| 2.4 | `Presentation/CurrencySelect/CurrencySelectView.swift` | 헤더 아래·`locationButton` 위에 SearchBar (`TextField` + 돋보기 아이콘 + 입력 시 우측 `xmark.circle.fill` clear 버튼). `currencyList`는 `state.filteredCurrencies` 사용. 결과 0건일 때 "검색 결과가 없습니다" empty state. | Spec-UI 디자인 시스템 (appBackground/appTextSub 톤 유지) |

### Step 3: 테스트

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `TravelCalculatorTests/Domain/ExchangeRateConversionTests.swift` | 신규 통화(JPY/EUR/VND) 변환 회귀 케이스 추가. 자세한 케이스 표는 §Step 3.1 상세. | Spec-Overview §2.2.4 |
| 3.2 | `TravelCalculatorTests/Presentation/CurrencySelectFilterTests.swift` (신규) | `CurrencySelectReducer` + `CurrencySelectState.filteredCurrencies` 단위 테스트: (a) 빈 쿼리 → 전체, (b) "일본"/"JPY"/"jpy" 매칭, (c) 대소문자/공백 무시, (d) 무매칭 → 빈 배열, (e) scope-guard "엔"/"¥" 비매칭. | — |

#### Step 3.1 상세

**목표**: Phase F Step 1에서 추가된 신규 통화(JPY/CNY/EUR/THB/VND/PHP) 중 fractionDigits 분기를 대표하는 3종(JPY=0, EUR=2, VND=0/저액면)의 KRW 양방향 환산을 회귀 안전망에 편입.

**테스트 패턴**: 기존 `conversion_TWD_appliesRate` (line 43–52) 와 동일. `CalculatorDisplayModel.make(...)` 호출, `inputCurrency`/`outputCurrency`/`exchangeRate` 직접 지정, `resultDisplay.rawAmount` + `formattedAmount` 검증.

**rate 선택 원칙**: 정확한 정수/2자리 결과가 나오도록 의도적으로 라운드 친화 값 사용. 부동 정밀도 검증은 별도 케이스(50 EUR × 1467.93)로만.

| # | 케이스명 | input | rate | output | rawAmount | formattedAmount |
|---|---|---|---|---|---|---|
| 3.1.1 | `conversion_JPYtoKRW_appliesRate` | 1000 JPY | 9 | KRW | `9000` | `9,000` |
| 3.1.2 | `conversion_KRWtoJPY_dropsFractionDigits` | 9000 KRW | 9 | JPY | `1000` | `1,000` |
| 3.1.3 | `conversion_EURtoKRW_appliesRate` | 100 EUR | 1500 | KRW | `150000` | `150,000` |
| 3.1.4 | `conversion_KRWtoEUR_keepsTwoFractionDigits` | 150000 KRW | 1500 | EUR | `100` | `100.00` |
| 3.1.5 | `conversion_EUR_decimalRate_bankerRoundsHalfEven` | 50 EUR | 1467.93 | KRW | `73396.5` | `73,396` |
| 3.1.6 | `conversion_VNDtoKRW_smallRate` | 100000 VND | 0.05 | KRW | `5000` | `5,000` |
| 3.1.7 | `conversion_KRWtoVND_largeResult` | 100000 KRW | 0.05 | VND | `2000000` | `2,000,000` |

**산식 검증**:
- 3.1.5 — `Decimal(50) * Decimal("1467.93") = 73396.5`. `Decimal+Format.swift`는 `NumberFormatter` 기본 모드(`.halfEven` = banker's rounding) 사용. 73396.5 → 73396(짝수)로 내림. 기대값 `73,396` 확정. 이 케이스가 라운딩 모드 회귀를 동시에 잡아주는 효과 있음.
- 3.1.7 — `Decimal(100000) / Decimal("0.05") = 2,000,000`. 정수부 7자리, 천단위 콤마. Decimal은 38 significant digits까지 안전 → VND 저액면 overflow 우려 없음.

**놓치면 위험한 회귀**:
- JPY/VND가 `fractionDigits=0`인데 formatter가 0자리 라운딩 미적용 시 소수점 노출 (3.1.2, 3.1.7로 잡힘)
- EUR이 `fractionDigits=2`인데 0자리 또는 부동정밀도로 절단 (3.1.4, 3.1.5로 잡힘)
- VND가 너무 작은 rate로 큰 결과를 만들 때 표시 폭 (3.1.7) — Display View 측 minimumScaleFactor 회귀와 별개

**파일 구조**: 기존 `ExchangeRateConversionTests` struct 안에 `@Test` 7개 추가. 별도 struct 분리 불필요 (모두 동일 도메인).

**의존성/사전 조건**: 추가 코드 없음. Currency enum의 fractionDigits는 Phase F Step 1에서 이미 케이스별 분기 완료 (Currency.swift:72–77).

---

## 완료 기준

- [x] `xcodebuild build` 성공 (warning 0, error 0)
- [x] `xcodebuild test` 성공 (Step 3.2 신규 검색 테스트 포함 전 케이스 통과)
- [x] CurrencySelectView 시뮬레이터 확인: 9개 통화(KRW 제외 8개 표시) 노출, 검색어 입력 시 실시간 필터, clear 버튼 동작, 결과 0건 empty state
- [x] 신규 통화(예: JPY, EUR) 선택 → 계산기 화면에서 실시간 KRW 변환 정상 표시 (fractionDigits 차등 반영)
- [ ] 위치 기반 자동 설정으로 JP/TH/VN/PH/CN 국가 시 해당 통화 매핑 (EU는 fallback Toast 정상) ← 사용자 손 검증 대기

### Step 진행 상황

- ✅ **Step 1** — Currency 확장 (커밋 `459cbf4`)
- ✅ **Step 2** — 검색·필터 UI (working tree, 미커밋) + Tripy.html 디자인 사양 + 팀 검증 HIGH(spec)/MEDIUM 7건 반영 + /simplify 1건 반영
- ⬜ **Step 3.1** — `ExchangeRateConversionTests`에 JPY(0)/EUR(2)/VND(0) fractionDigits 회귀 케이스 추가 (현재 USD/KRW만)
- ✅ **Step 3.2** — `CurrencySelectFilterTests.swift` 신규 (10 케이스)

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
├── Domain/
│   └── ExchangeRateConversionTests.swift               ← MOD (Step 3.1, 신규 통화 케이스)
└── Presentation/
    └── CurrencySelectFilterTests.swift                 ← NEW (Step 3.2)
```

---

## 다음 Phase

V1 백로그 잔여(접근성: VoiceOver/Dynamic Type, Toast 스와이프 닫기) 또는 V1+ 릴리스 준비(앱 아이콘/스토어 메타데이터).
