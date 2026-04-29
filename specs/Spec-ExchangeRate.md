# TravelCalculator 기획서 — 통화 선택 / 환율 API / 오프라인

> 2차 인터뷰 기반 최종 확정본 | 2026-04-05
> 관련: [개요/Toast/온보딩](Spec-Overview.md) | [계산기/환율 변환](Spec-Calculator.md) | [화면 설계](Spec-UI.md) | [아키텍처](Spec-Architecture.md) | [데이터 모델](Spec-DataModel.md) | [태스크](Spec-Tasks.md)

---

## 2.3 통화 선택

### 2.3.1 지원 통화
| 통화 코드 | 기호 | 국기 | 국가명 |
|-----------|------|------|--------|
| KRW | ₩ | 🇰🇷 | 대한민국 |
| USD | $ | 🇺🇸 | 미국 |
| JPY | ¥ | 🇯🇵 | 일본 |
| CNY | 元 | 🇨🇳 | 중국 |
| EUR | € | 🇪🇺 | 유럽연합 |
| TWD | NT$ | 🇹🇼 | 대만 |
| THB | ฿ | 🇹🇭 | 태국 |
| VND | ₫ | 🇻🇳 | 베트남 |
| PHP | ₱ | 🇵🇭 | 필리핀 |

### 2.3.2 통화 선택 화면
- 전체 화면 모달 (fullScreenCover)
- 통화 목록에서 선택 시 체크마크 표시
- 선택 완료 후 자동 닫힘 또는 X 버튼으로 닫기

### 2.3.3 통화 변경 시 계산기 리셋
- 통화 변경이 확정되면 CalculatorStore 전체 리셋
  - `display = "0"`, `previousValue = nil`, `pendingOperator = nil`, `lastOperand = nil`, `lastOperator = nil`
  - 이유: display 숫자가 이전/새 통화 중 어느 것인지 모호해지는 상황 방지

### 2.3.4 위치 기반 자동 선택
- "현재 위치로 자동 설정" 버튼
- 위치 권한 요청 → GPS 좌표 획득 → 역지오코딩 → 국가 코드 매핑
- 국가 코드 매핑(ISO 3166-1 alpha-2):
  - 단일 매핑: `KR→KRW`, `US→USD`, `JP→JPY`, `CN→CNY`, `TW→TWD`, `TH→THB`, `VN→VND`, `PH→PHP`
  - EUR(eurozone 19개국): `DE/FR/IT/ES/NL/BE/AT/PT/IE/FI/GR/LU/SK/SI/EE/LV/LT/MT/CY → EUR`
  - 데이터 소스: `Currency.countryCodes` (Spec-DataModel §5.2)
- 미지원 지역일 경우 Toast(warning) 알림
- `PermissionStatus.denied` 시: iOS 설정 앱으로 안내하는 Toast(info) + 딥링크

---

## 2.4 환율 API 연동

### 2.4.1 데이터 소스
- open.er-api.com (USD 기준)
- endpoint: `https://open.er-api.com/v6/latest/USD`
- 인증 불필요, 호출 한도 없음
- **업데이트 주기**: 24시간마다 갱신 (`time_next_update_unix` 제공)
- 응답: `{ "result": "success", "base_code": "USD", "time_last_update_unix": ..., "rates": {"KRW": ..., "TWD": ..., ...} }`
- KRW 환산: `X→KRW = rates["KRW"] / rates["X"]` (API 레이어에서 사전 계산)
  - 반올림: **banker's rounding** (ROUND_HALF_EVEN, `NSDecimalNumberHandler.roundingMode = .bankers`)
  - scale: **8** (소수점 이하 8자리)
  - 정의 위치: `ExchangeRateAPI.swift` 응답 매핑 단계

### 2.4.2 (삭제됨) deal_bas_r 파싱
- open.er-api는 JSON 숫자로 환율을 반환하므로 별도 문자열 파싱 없음

### 2.4.3 (삭제됨) 주말/공휴일 fallback
- open.er-api는 24h 주기로 매일 갱신 — fallback 불필요
- API 실패 시 stale 캐시 반환, 캐시도 없으면 §2.5.4 환율 미가용 에러 배너

### 2.4.4 캐싱 전략
- 캐시 파일: `exchange_rates_cache.json` (Documents 디렉토리)
- 유효성 판단: `Date.now < response.validUntil` — API의 `time_next_update_unix`를 그대로 `validUntil`로 저장
- API 실패 시: `validUntil` 지난 stale 캐시라도 fallback으로 사용
- JSON 파싱 실패 시: 캐시 파일 삭제 후 재요청
- 동시 읽기/쓰기: **`ExchangeRateCacheActor`** 가 캐시 파일 IO를 직렬화 (`Data/Network/ExchangeRateAPI.swift`). 노출 메서드: `save(_:)` / `load()` / `isValid(_:)` / `delete()`. 파일 쓰기는 `.atomic` 옵션으로 부분 쓰기 방지.

### 2.4.5 Protocol 추상화
- `ExchangeRateAPIProtocol`: fetch 메서드 정의
- `CurrentCountryCodeProvider`: 위치 → 국가 코드(`String`) 반환. 통화 매핑은 호출자 책임
- Store에 의존성 주입 → 마일스톤 4(테스트)에서 Mock으로 대체

### 2.4.6 새로고침 전략 (searchdate 기반)
| 조건 | 새로고침 버튼 | 동작 |
|------|-------------|------|
| 캐시의 searchdate = 오늘 | **비활성화** | "최신" 표시 |
| 캐시의 searchdate < 오늘 | 활성화 | "N일 전" 표시 + 탭 시 API 호출 |
| 캐시 없음 | — | 앱 시작 시 자동 호출 |

- 별도 throttle 불필요: 같은 날 데이터는 변하지 않으므로 searchdate 기반으로 자연스럽게 제한
- 비정상 환율값 처리:
  - **개별 통화** `rates[X]` 누락 또는 `≤ 0`: 해당 통화만 결과 배열에서 제외(`compactMap`). 다른 통화는 정상 사용.
  - **응답 전체 폐기**(이하 `noDataAvailable` throw): `result != "success"` / `base_code != "USD"` / `rates["KRW"]` 누락 또는 `≤ 0` (KRW는 환산 기준이라 필수) / `time_next_update_unix` 비정상 / 개별 필터 후 결과 배열이 빔
  - **Fallback**: throw 발생 시 호출자가 stale 캐시(`validUntil` 지난 캐시 포함)로 폴백. 캐시도 없으면 §2.5.4 환율 미가용 에러 배너 진입.
  - 정의 위치: `ExchangeRateAPI.swift` 응답 매핑 단계

### 2.4.7 데이터 모델
```swift
ExchangeRate
├── currencyCode: String    // "USD", "TWD"
├── currencyName: String    // "미국 달러"
└── rate: Decimal           // 1 외화 = N 원 (Decimal 타입)

ExchangeRateResponse
├── rates: [ExchangeRate]
├── fetchedAt: Date
├── searchDate: String      // "2026-04-04" (API 조회일)
└── validUntil: Date
```

---

## 2.5 오프라인 대응

### 2.5.1 네트워크 모니터링
- NWPathMonitor를 사용한 실시간 네트워크 상태 감지
- `NetworkState` enum: `unknown` / `online` / `offline` (초기값 `unknown` — 첫 콜백 도달 전 "거짓 온라인" 창 제거)
- 콜백 → MainActor 전달 시 `@Sendable` 처리

### 2.5.2 오프라인 UI
- **Toolbar 인디케이터**: Online(`● 온라인`, 초록) ↔ Offline(`wifi.slash 오프라인`, 노랑) ↔ Unknown(빈 placeholder). 상세 스펙은 Spec-UI §3.1 참조
- **환율 영역 rate row 인라인 캐시 시각 표기** (별도 배너 없음): `Color.appWarning` 톤
  - 상대 시각 (경과 시간 기준, `[lo, hi)` 반열림 구간, 버림):
    - `< 60초` → `방금`
    - `60초 ~ < 3,600초` → `N분 전` (N = ⌊초/60⌋, 1~59)
    - `3,600초 ~ < 86,400초` → `N시간 전` (N = ⌊초/3600⌋, 1~23)
    - `≥ 86,400초` → `N일 전` (N = ⌊초/86400⌋, 1~)
  - 절대 시간(`14:00 기준`)은 사용하지 않음 — 오프라인 인라인 표기는 finer-grain 상대 시각 전용
  - 정의 위치: `CalculatorDisplay.swift` (offline relative time formatter)
- 새로고침 버튼: 오프라인 시 비활성화 (tap 시 `Toast(info, "오프라인 시 갱신할 수 없어요")`)
- `unknown` 상태: 인디케이터/인라인 표기 비표시, 새로고침 disabled (안전 기본값)

### 2.5.3 온라인↔오프라인 전환
- **온→오프**: 별도 Toast/배너 없음 — 환율 영역 인라인 캐시 시각 표기로 대체 (grace period 없음)
- **오프→온 복귀**: 환율 영역 pulse 애니메이션 — `scale 1.0→1.02→1.0` 1회 (`easeOut 0.3s` → `easeIn 0.3s`, 총 0.6초). Toast/햅틱 없음. 인라인 표기는 원래 라벨(`최신` / `N일 전`)로 복귀.
  - **Throttle**: 직전 pulse 발화 후 10초 이내에는 재발화하지 않음 (flapping 시 애니 스팸 방지). 정의: `CalculatorView.pulseThrottle = 10s`
- `unknown → offline` 전이는 무시(첫 진입 시 깜빡임 방지), `online → offline` 전이만 인라인 표기 발화

### 2.5.4 API 실패 + 캐시 없음 (환율 미가용)
- **트리거**: `currentRate == nil` (= API 실패 + stale 캐시도 없음). 판정 프로퍼티: `AppCurrencyStore.unavailableRateError`
- **UI**: 상단 인라인 배너 — 아이콘(`exclamationmark.triangle.fill`) + 에러 메시지(§2.5.5 표) + `재시도` 버튼. 상세 스펙은 Spec-UI §3.4 참조
- **계산기 키패드**: **활성 유지** — 환율 없이도 단순 산술 사용 가능. 변환 결과 영역은 `0`으로 표시(Spec-Calculator §2.2.1 fallback)
- **재시도**: `loadExchangeRates()` 재호출. 성공 시 배너 자동 해제

### 2.5.5 에러 핸들링
- 에러 분류: 네트워크 / 서버 / 파싱 에러
- Timeout: 요청당 10초 (`timeoutIntervalForRequest = 10`, 리소스 전체 30초)
- 재시도 정책: **총 3회 시도** (최초 1회 + 재시도 2회). 시도 간 간격 2초.
  - 재시도 대상: `networkError` (URLSession 레벨 — timeout/연결 실패), `serverError` 5xx (500~599)
  - 재시도 안 함: `serverError` 4xx, `parsingError`, `noDataAvailable` (즉시 stale 캐시 fallback으로 진행)
  - 정의: `ExchangeRateAPI.maxAttempts = 3`, `retryDelay = 2s`, `shouldRetry(_:)`
- Fallback 흐름: 위 시도가 모두 실패하면 stale 캐시(`validUntil` 지난 캐시 포함) 반환. 캐시 없으면 `noCacheAvailable` → §2.5.4 환율 미가용 에러 배너
- 에러 메시지: 모든 에러 문구는 `ExchangeRateError.errorDescription`에 중앙화 (단일 출처 — 코드 기준, spec은 미러)

  | 케이스 | 메시지 |
  |---|---|
  | `networkError` | `네트워크 연결에 실패했습니다` |
  | `serverError` (5xx/4xx 무관 동일) | `서버에서 오류가 발생했습니다` |
  | `noDataAvailable` | `환율 데이터를 찾을 수 없습니다` |
  | `parsingError` | `환율 데이터를 처리할 수 없습니다` |
  | `invalidRate` | `유효하지 않은 환율입니다` |
  | `noCacheAvailable` | `저장된 환율 데이터가 없습니다` |

  - 정의 위치: `Domain/Models/ExchangeRateError.swift`
  - 메시지 변경 시 코드 우선, spec 표 동시 갱신
