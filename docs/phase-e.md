# Phase E — Offline Support + Tests (오프라인 대응 + 테스트)

> 브랜치: `phase/e-offline-tests`
> 목표: NWPathMonitor 기반 오프라인 감지·UI 피드백·재시도 로직 추가, Reducer/환율 변환 테스트 보강.

---

## 구현 목표

1. 네트워크 상태 감지 (NWPathMonitor, @Sendable)
2. 오프라인 State + 온→오프 전환 처리 (인라인 캐시 시각 표시)
3. 오프라인 UI 피드백 (Toolbar 인디케이터, 환율 영역 인라인 캐시 시각, 새로고침 비활성화)
4. API 에러 핸들링 강화 (재시도 2회, 간격 2초)
5. Reducer 단위 테스트 (Spec-Tasks 4.1)
6. 환율 변환 테스트 (Spec-Tasks 4.2)

---

## 태스크 목록

### Step 1: 네트워크 모니터 + 오프라인 State ✅ 완료

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `Domain/Protocols/NetworkMonitorProtocol.swift` (신규) | `NetworkState` enum (unknown/online/offline) + `@MainActor` Protocol | Spec-Overview §2.5.1 |
| 1.2 | `Data/Network/NetworkMonitor.swift` (신규) | NWPathMonitor 래핑, `@Observable`, `state: NetworkState` 초기 `.unknown`, `@Sendable` 콜백 → MainActor hop, idempotent `start()` | Spec-Overview §2.5.1 |
| 1.3 | `Core/App/AppStore.swift` | NetworkMonitor 인스턴스 보유 + currencyStore에 cascade 주입 | Spec-Architecture §4.3 |
| 1.4 | `Core/App/AppCurrencyStore.swift` | `networkState`/`isOffline`/`cachedAt` computed | Spec-Overview §2.5.3, Spec-Tasks 3.1.2 |
| 1.5 | `TravelCalculatorApp.swift` | init에서 `appStore.networkMonitor.start()` 1회 호출 (Step 2에서 AppStore.init으로 이동 예정) | — |

> 결정 핵심: `NetworkState.unknown` 도입으로 첫 콜백 도달 전 "거짓 온라인" 창 제거. Toast/배너는 `unknown → offline` 전이 무시, `online → offline` 만 발화 (Step 2에서 적용).

### Step 2: 오프라인 UI

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `Presentation/Calculator/CalculatorToolbar.swift` | 인디케이터: 색 + 아이콘 모양 변경(● ↔ wifi-off) + `accessibilityLabel` | Spec-UI §1, Spec-Tasks 3.3.1 |
| 2.2 | `Presentation/Calculator/CalculatorDisplay.swift` | 오프라인일 때 환율 영역 rate row 에 캐시 시각을 인라인 표시 (`isOffline + cachedAt` 분기). 라벨은 `relativeLabel` 헬퍼로 finer-grain 상대 시각(`방금` / `N분 전` / `N시간 전` / `N일 전`), `Color.appWarning` 톤 | Spec-Overview §2.5.2, Spec-Tasks 3.3.2 |
| 2.3 | `Presentation/Calculator/CalculatorView.swift` | `isOffline`/`cachedAt`을 CalculatorDisplay 로 전달 + 새로고침 disabled binding (`state != .online`) + 복귀 시 환율 영역 **pulse 애니** (scale 1.0→1.02→1.0 한 번) | Spec-Tasks 3.3.3 |
| 2.4 | `Presentation/Calculator/CalculatorView.swift` | 새로고침 disabled 상태에서도 tap 받아 `Toast(info, "오프라인 시 갱신할 수 없어요")` 발화 | UX A-7 |
| 2.5 | `Core/App/AppStore.swift` | `networkMonitor.start()` 호출을 `AppStore.init`으로 이동 (TravelCalculatorApp 단순화 — 컨벤션 M3) | — |

#### Step 2 결정사항 (인터뷰 확정)
- **온→오프 알림**: 별도 Toast/배너 없음 — 환율 영역 rate row 에 캐시 시각을 인라인 표기로 대체
- **오프→온 복귀 신호**: 환율 영역 pulse 애니메이션 (Toast/햅틱 X)
- **새로고침 disabled affordance**: tap → Toast(info, "오프라인 시 갱신할 수 없어요")
- **Toolbar 인디케이터**: 색 + 아이콘 모양 + VoiceOver
- **OfflineBanner**: 도입했다가 제거 — 인라인 캐시 시각 표시로 대체 (별도 grace period 없음)
- **`unknown` 상태 UI**: 인디케이터/인라인 표기 비표시, 새로고침 disabled (안전)
- **상대 시각 grain**: 오프라인 인라인 표기는 finer grain (`방금` / `N분 전` / `N시간 전` / `N일 전`), 온라인 day-grain (`최신` / `N일 전`) 과 분리

### Step 3: 에러 핸들링 + 재시도 ✅ 완료

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `Domain/Models/ExchangeRateError.swift` | 분류 확인 (network/server/parsing) — 친화적 메시지 컴퓨티드 추가 | Spec-Overview §2.5.5, Spec-Tasks 3.4.1/3.4.2 |
| 3.2 | `Data/Network/ExchangeRateAPI.swift` | `fetchFromAPI` 재시도 로직: 최대 2회, 간격 2초 (timeout 10s) | Spec-Tasks 3.4.3 |

### Step 4: Reducer 단위 테스트 ✅ 완료

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 4.1 | `TravelCalculatorTests/CalculatorReducerTests.swift` (신규) | 숫자 입력, 사칙연산, 소수점, AC/C/백스페이스, 엣지 케이스(0 나누기, 연산자 교체, =반복, 음수), 10자리 제한 — Spec-Tasks 4.1.1~4.1.6 전부 | Spec-Overview §2.1 |

### Step 5: 환율 변환 테스트 ✅ 완료

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 5.1 | `TravelCalculatorTests/ExchangeRateConversionTests.swift` (신규) | 통화 변환(Decimal 정밀도, fractionDigits), 소수점 처리, 방향 전환 시 값 이전(10자리 초과 포함), 통화 변경 시 리셋, 음수 → 변환 0 — Spec-Tasks 4.2.1~4.2.5 | Spec-Overview §2.2 |

---

## 완료 기준

- [x] `xcodebuild build` 성공 (warning 0, error 0)
- [x] `xcodebuild test` 성공 (4.1, 4.2 신규 테스트 통과)
- [x] 시뮬레이터 Wi-Fi off → 환율 영역 rate row 에 캐시 시각이 즉시 인라인 표시(`방금` / `N분 전` / `N시간 전` / `N일 전`) + Toolbar 인디케이터 색+아이콘 전환 + 새로고침 disabled
- [x] **온→오프 Toast/배너 없음** (인라인 캐시 시각 표기로 대체)
- [x] 오프→온 복귀 시 환율 영역 pulse 애니메이션 + 인라인 캐시 시각 표기 사라짐(원래 `최신` / `N일 전` 라벨로 복귀)
- [x] 비행기 모드 ON 상태로 첫 실행 시 인디케이터/인라인 표기 즉시 unknown→offline (절대 ON 잠깐 보이지 않음)
- [x] 새로고침 disabled tap → Toast(info, "오프라인 시 갱신할 수 없어요")
- [x] VoiceOver: 인디케이터에 "오프라인" / "온라인" 레이블
- [x] API 일시 실패 시 2초 간격 2회 재시도 후 캐시 fallback 또는 에러 노출 (Step 3)
- [x] 오프라인 인라인 캐시 시각은 상대 시각(`방금` / `N분 전` / `N시간 전` / `N일 전`) 으로 표시 — 절대 시간 표기는 사용하지 않음

---

## 파일 구조 (생성/수정 예정)

```
TravelCalculator/
├── Core/
│   └── App/
│       ├── AppStore.swift                           ← MOD (Step 1+2)
│       └── AppCurrencyStore.swift                   ← MOD (Step 1)
├── Data/
│   └── Network/
│       ├── NetworkMonitor.swift                     ← NEW (Step 1)
│       └── ExchangeRateAPI.swift                    ← MOD (재시도, Step 3)
├── Domain/
│   ├── Protocols/
│   │   └── NetworkMonitorProtocol.swift             ← NEW (Step 1)
│   └── Models/
│       └── ExchangeRateError.swift                  ← MOD (메시지, Step 3)
├── TravelCalculatorApp.swift                        ← MOD (Step 1)
└── Presentation/
    └── Calculator/
        ├── CalculatorView.swift                     ← MOD (Step 2)
        ├── CalculatorDisplay.swift                  ← MOD (Step 2 — 인라인 캐시 시각)
        └── CalculatorToolbar.swift                  ← MOD (Step 2)

TravelCalculatorTests/
├── Core/
│   └── AppCurrencyStoreOfflineTests.swift           ← NEW (Step 1)
├── CalculatorReducerTests.swift                     ← NEW (Step 4)
└── ExchangeRateConversionTests.swift                ← NEW (Step 5)
```

---

## V2 백로그 (팀 검증에서 분리된 항목)

- **AppCurrencyStore 옵셔널 의존성 제거** (`exchangeRateAPI`, `networkMonitor`) — non-optional + 명시적 mock 주입으로 정리. Preview 동작 검토 필요.
- **색맹 인디케이터** — online dot에 아이콘 추가(현재 색만 의존), Toolbar 인디케이터 일관성.
- **Dynamic Type** — Toolbar 의 `.system(size: 11/12/13)` 고정 폰트 → `.caption2`/`.caption` relative 폰트로 전환.
- **캐시 없음 + 오프라인** 별도 톤 — 인라인 표기를 `appDanger`(빨강) 톤으로 차별화.
- **MockNetworkMonitor 정책 문서화** — 재사용 mock은 `Helpers/`로 분리한다는 정책을 docs/harness.md에 1줄.

## 다음 Phase

V1 완료 → 앱스토어 배포 준비 + 통화 확장(JPY, EUR 등) 백로그 처리.
