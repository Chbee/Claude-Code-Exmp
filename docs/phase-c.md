# Phase C — Exchange Rate API (환율 API 연동)

> 브랜치: `phase/c-exchange-rate`
> 목표: mock 환율을 한국수출입은행 실제 API로 교체. searchdate 기반 캐싱 + 새로고침 + 에러 핸들링.

---

## 구현 목표

1. 환율 데이터 모델 + 에러 타입 + API Protocol 정의
2. 한국수출입은행 API 구현체 (deal_bas_r 쉼표 파싱, 주말/공휴일 7일 fallback)
3. actor 기반 파일 캐시 (exchange_rates_cache.json, 24h 유효)
4. ExchangeRateStatus associated value 추가 + AppCurrencyStore 환율 로드 메서드
5. CalculatorStore에서 mock 제거 → 실제 환율 연동
6. Display UI 업데이트 (실시간 업데이트 시간, searchdate 기반 새로고침 버튼)
7. API 실패 + 캐시 없음 → 전체화면 에러 오버레이

---

## 태스크 목록

### Step 1: Domain Layer — 데이터 모델 + Protocol

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `Domain/Models/ExchangeRate.swift` | ExchangeRate + ExchangeRateResponse (Codable, Sendable). `rate(for:)` convenience 메서드 | Spec-DataModel §5.8 |
| 1.2 | `Domain/Models/ExchangeRateError.swift` | ExchangeRateError enum (networkError/serverError/noDataAvailable/parsingError/invalidRate/noCacheAvailable). LocalizedError 한국어 메시지 | Spec-Overview §2.5.5 |
| 1.3 | `Domain/Protocols/ExchangeRateAPIProtocol.swift` | `protocol ExchangeRateAPIProtocol: Sendable` — `fetchRates(for:) async throws -> ExchangeRateResponse` | Spec-DataModel §5.11 |

### Step 2: Network Layer — API 구현체 + 캐시 Actor

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `Data/Network/ExchangeRateAPI.swift` | `ExchangeRateCacheActor` — Documents/exchange_rates_cache.json 읽기/쓰기/삭제 (actor 직렬화) | 2.4.4 |
| 2.2 | 〃 | `ExchangeRateAPI: ExchangeRateAPIProtocol` — API 호출 + 캐시 우선 전략 | 2.4.1 |
| 2.3 | 〃 | deal_bas_r 쉼표 제거 후 Decimal 변환 + 비정상값(0, 음수) 무시 | 2.4.2, 2.4.7 |
| 2.4 | 〃 | 주말/공휴일 순차 fallback (오늘→6일 전, 최대 7회 호출) | 2.4.3 |
| 2.5 | 〃 | API 실패 시 만료 캐시 fallback, 캐시도 없으면 throw `.noCacheAvailable` | 2.4.5 |
| 2.6 | `Config/APIKeys.swift` | placeholder 템플릿 (이미 .gitignore, 로컬에 실제 키 존재) | 2.4.1 |

### Step 3: State 확장 — ExchangeRateStatus + AppCurrencyStore

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `Core/App/AppCurrencyStore.swift` | ExchangeRateStatus에 associated value 추가: `.loaded(ExchangeRateResponse)`, `.error(ExchangeRateError)` | 2.3.1 |
| 3.2 | 〃 | computed properties: `currentResponse`, `currentRate`, `searchDate`, `isRefreshEnabled` | 2.4.6 |
| 3.3 | 〃 | `exchangeRateAPI: (any ExchangeRateAPIProtocol)?` 저장 프로퍼티 (DI) | 2.4.5 |
| 3.4 | 〃 | `loadExchangeRates()` async — 상태 전이 loading→loaded/error | 2.4.3 |
| 3.5 | 〃 | `refreshExchangeRates()` async — 수동 새로고침 | 2.4.6 |

### Step 4: Store 통합 — mock 제거 + 실제 환율 연동

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 4.1 | `Presentation/Calculator/CalculatorStore.swift` | `mockRate(for:)` 삭제, `displayModel`에서 `currencyStore.exchangeRateStatus` 기반 rate 조회 | 2.2.1 |
| 4.2 | 〃 | `refreshRates()` 메서드 추가 → `currencyStore.refreshExchangeRates()` 위임 | 2.4.6 |

### Step 5: UI 업데이트 — Display + Error View

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 5.1 | `Presentation/Calculator/CalculatorDisplay.swift` | rateRow: "Mock 데이터" → 실제 searchDate 기반 텍스트 (오늘=비활성, 과거=활성) | 1.4.2, 2.4.6 |
| 5.2 | 〃 | 새로고침 버튼: `isRefreshEnabled` + `isLoading` 기반 활성화/비활성화 | 1.4.3~1.4.4 |
| 5.3 | 〃 | 로딩 중 ProgressView 스피너 표시 | 2.4.4 |
| 5.4 | `Presentation/Calculator/CalculatorView.swift` | CalculatorDisplay에 searchDate/isRefreshEnabled/isLoading 전달 | — |
| 5.5 | `Presentation/Error/ExchangeRateErrorView.swift` | 전체화면 에러 오버레이 (에러 아이콘 + 메시지 + 재시도 버튼) | 2.4.5 |

### Step 6: 앱 라이프사이클 — 초기 로드 + 에러 오버레이

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 6.1 | `Core/App/AppStore.swift` | init에서 ExchangeRateAPI 생성 → AppCurrencyStore에 주입 | Spec-Architecture §4.3 |
| 6.2 | `ContentView.swift` | `.task`로 앱 시작 시 `loadExchangeRates()` 호출 | 2.4.3 |
| 6.3 | 〃 | `exchangeRateStatus == .error` + 캐시 없음 → ExchangeRateErrorView 오버레이 | 2.4.5 |

---

## 완료 기준

- [ ] `xcodebuild` 빌드 성공 (warning 0, error 0)
- [ ] 앱 실행 시 한국수출입은행 API에서 실제 환율 로드
- [ ] 환율 표시: "1 USD = X,XXX.XX KRW" + searchdate 기반 업데이트 시간
- [ ] 새로고침 버튼: searchdate < 오늘이면 활성화, == 오늘이면 비활성화
- [ ] 주말/공휴일: 순차 fallback으로 최근 영업일 환율 조회
- [ ] 캐시: 24h 유효, API 실패 시 만료 캐시 fallback
- [ ] API 실패 + 캐시 없음 → 전체화면 에러 + 재시도 버튼
- [ ] deal_bas_r 쉼표 파싱 정상 동작
- [ ] 비정상 환율값(0, 음수) 무시

---

## 파일 구조 (생성/수정 예정)

```
TravelCalculator/
├── Config/
│   └── APIKeys.swift                              ← (확인/생성)
├── Core/
│   └── App/
│       ├── AppCurrencyStore.swift                 ← MOD
│       └── AppStore.swift                         ← MOD
├── Data/
│   └── Network/
│       └── ExchangeRateAPI.swift                  ← NEW
├── Domain/
│   ├── Models/
│   │   ├── ExchangeRate.swift                     ← NEW
│   │   └── ExchangeRateError.swift                ← NEW
│   └── Protocols/
│       └── ExchangeRateAPIProtocol.swift          ← NEW
└── Presentation/
    ├── Calculator/
    │   ├── CalculatorDisplay.swift                ← MOD
    │   ├── CalculatorStore.swift                  ← MOD
    │   └── CalculatorView.swift                   ← MOD
    └── Error/
        └── ExchangeRateErrorView.swift            ← NEW
```

---

## 에이전트 할당 계획

```
Worker-1 (Sonnet): Step 1~2 — Domain 모델 + Network API 구현
  파일: ExchangeRate.swift, ExchangeRateError.swift, ExchangeRateAPIProtocol.swift, ExchangeRateAPI.swift

Worker-2 (Sonnet): Step 3~4 — State 확장 + Store 통합
  파일: AppCurrencyStore.swift, CalculatorStore.swift
  의존: Worker-1 완료 후 시작

Worker-3 (Sonnet): Step 5~6 — UI 업데이트 + 앱 라이프사이클
  파일: CalculatorDisplay.swift, CalculatorView.swift, ExchangeRateErrorView.swift, AppStore.swift, ContentView.swift
  의존: Worker-2 완료 후 시작

Senior (Opus): 각 Worker 결과물 설계 리뷰 (Swift 6 concurrency, Decimal 정밀도, 에러 핸들링)
Leader: 최종 통합 + xcodebuild 빌드 확인
```

---

## 다음 Phase

Phase D (`phase/d-onboarding`): 온보딩 화면 — 첫 실행 시 통화 선택 강제 + 위치 기반 자동 선택
