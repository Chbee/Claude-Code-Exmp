# Phase E Step 1 — 네트워크 모니터 + 오프라인 State

> 브랜치: `phase/e-offline-tests`
> 생성: 2026-04-25
> 하네스 plan 원본 위치: 시스템 강제 경로 사용 (`docs/plans/phase-e-offline-tests/`로 이동 예정)

---

## Context (작업 설명)

마일스톤 3 오프라인 대응의 진입점. `NWPathMonitor`로 실시간 네트워크 상태를 감지하고, 온→오프 전환 시 `AppCurrencyStore`가 Toast(info)를 띄운다. 후속 Step에서 이 `isOffline`을 읽어 배너/인디케이터/새로고침 비활성화 UI를 만든다.

**Spec 참조**: Spec-Overview §2.5.1, §2.5.3 / Spec-Tasks 3.1.2, 3.2.1, 3.2.2, 3.2.3

## 인터뷰 결과

- **NetworkMonitor 추상화**: Protocol + concrete (테스트 mock 가능, 기존 `ExchangeRateAPIProtocol` 패턴 일관성)
- **isOffline 위치**: `AppCurrencyStore`에 추가 (cascade 환경 주입 흐름 유지, 새 Store 생성 X)
- **fetchedAt 노출**: `ExchangeRate.fetchedAt: Date`이 이미 존재 → 별도 추가 없이 `AppCurrencyStore.cachedAt: Date?` computed로만 노출 (3.1.2 완성)

## 구현 계획

### 신규 파일

**1. `Core/Network/NetworkMonitorProtocol.swift`**
```swift
@MainActor
protocol NetworkMonitorProtocol: AnyObject, Observable {
    var isOffline: Bool { get }
    func start()
}
```
- `@MainActor` 격리. `Observable`로 단언 (concrete가 `@Observable`이므로 호환)

**2. `Core/Network/NetworkMonitor.swift`**
```swift
@MainActor
@Observable
final class NetworkMonitor: NetworkMonitorProtocol {
    private(set) var isOffline = false
    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private let queue = DispatchQueue(label: "NetworkMonitor")

    private var hasStarted = false

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        monitor.pathUpdateHandler = { [weak self] path in
            let offline = path.status != .satisfied
            Task { @MainActor [weak self] in
                self?.isOffline = offline
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
```
- `pathUpdateHandler`는 `@Sendable` — weak self만 캡처, 값 캡처 후 MainActor로 hop
- `start()`는 idempotent (Codex 권고). `TravelCalculatorApp.init` 1회 호출

### 수정 파일

**3. `Core/App/AppStore.swift`**
- 의존성 추가: `init(..., networkMonitor: any NetworkMonitorProtocol = NetworkMonitor())` — **non-optional** (Codex 권고: 실서비스 wiring 누락 방지)
- `@ObservationIgnored let networkMonitor`: 보유
- `currencyStore` 초기화 시 `networkMonitor` 같이 넘김

**4. `Core/App/AppCurrencyStore.swift`**
- init에 `networkMonitor: (any NetworkMonitorProtocol)? = nil` 추가 (optional — 테스트 churn 최소화)
- 새 computed: `var cachedAt: Date? { currentResponse?.fetchedAt }` ← Codex 정정 (현재 코드는 `currentResponse` 사용)
- 새 computed: `var isOffline: Bool { networkMonitor?.isOffline ?? false }`
- **온→오프 Toast 트리거는 Step 2의 View `onChange`에서 처리** (Codex 권고 (B)안). Step 1에선 isOffline 노출까지만.

**5. `TravelCalculatorApp.swift`**
- `AppStore()` 생성 후 `App.init`에서 `appStore.networkMonitor.start()` 1회 호출 (`body` 안에서 호출 금지 — Codex 권고)

### 호출 그래프

```
TravelCalculatorApp
  └─ AppStore (networkMonitor: NetworkMonitor)
        └─ AppCurrencyStore (networkMonitor: 같은 인스턴스)
              └─ View가 .isOffline 관찰
```

### 영향 범위

- View는 변경 없음 (Step 2에서 처리)
- 기존 테스트는 `AppCurrencyStore` init 시그니처 변경 영향만 받음 — 모두 default 인자라 호환
- Spec-Tasks 3.1.2 (cachedAt), 3.2.1~3.2.3 충족

## UX 결정 (인터뷰 #2)

- **Debounce**: 적용 안 함 — NWPathMonitor 원시 이벤트 그대로. iOS가 어느 정도 안정화해서 주는 편.
- **오프→온 복귀 알림**: Toast 없음. 배너 사라짐 + 디스플레이 자동 업데이트로 처리 (Step 2 범위).
- **앱 시작 시 isOffline 초기값**: `false`로 두고 첫 콜백 대기 (단순 구현). **TODO**: 실제 오프라인 첫 진입 시나리오 테스트 후 재검토 (사용자 메모 "isOffline일 때 다시 고민해").

## TDD 전략

- **Red**: `NetworkMonitorTests` — Mock으로 `pathUpdateHandler` 흉내내기 어려움. 대신 `NetworkMonitorProtocol` 만족하는 `MockNetworkMonitor`를 테스트 헬퍼로 만들고, `AppCurrencyStore`가 `mock.isOffline = true`를 읽어 `isOffline`이 true가 되는지 검증
- **Yellow**: AppCurrencyStore에 isOffline computed 추가
- **Green**: 리팩터링 (cachedAt computed 정리)

> NetworkMonitor 자체의 NWPathMonitor 통합 테스트는 단위 테스트 어려움 — 수동 검증(시뮬 Wi-Fi off)으로 대체.

## Codex Review

Codex MCP 응답 (요약 항목별 반영):

- **NetworkMonitorProtocol 정당화**: 테스트 mock 의도 있음 → 반영함 (유지)
- **start() idempotency**: 중복 시작 방지 `hasStarted` 플래그 추가 → 반영함
- **start() 호출 위치**: `body`가 아닌 `App.init` 또는 1회 보장 위치에서 호출 → 반영함 (`TravelCalculatorApp.init`)
- **cachedAt 소스 정정**: 현재 코드는 `lastResponse`가 아닌 `currentResponse` 사용 → 반영함 (`currentResponse?.fetchedAt`)
- **Toast 트리거**: (B) View onChange 권장 — 시스템 이벤트 기반 전역 UI effect는 Store가 직접 처리하면 의존성 누수 → **반영함** (Step 2에서 CalculatorView에 `onChange(of: networkMonitor.isOffline)` 두는 것으로 결정. Step 1 범위 밖이지만 의사결정 기록)
- **networkMonitor 주입**: AppStore에선 non-optional (실서비스 wiring 누락 방지), AppCurrencyStore에선 optional 유지(테스트 churn 최소화) → 반영함
- **withObservationTracking 사용**: 비추천 → 반영함 (사용 안 함)
- **MVI 충돌 없음**: 확인
- **요청 범위 외 기능 추가 없음**: 확인 (재시도/배너 문구/disable 정책은 Step 2/3로 분리 유지)

## TDD 사이클 로그

### Red (실패 테스트)
- `TravelCalculatorTests/Core/AppCurrencyStoreOfflineTests.swift` 작성: MockNetworkMonitor + 4개 테스트 (isOffline 반영, 기본값 false, cachedAt nil/value)
- `xcodebuild build-for-testing` → **TEST BUILD FAILED** (Protocol/init param/computed 없음)

### Yellow (최소 구현)
1. `Core/Network/NetworkMonitorProtocol.swift` 신규 — `@MainActor protocol NetworkMonitorProtocol: AnyObject, Observable`
2. `Core/Network/NetworkMonitor.swift` 신규 — NWPathMonitor 래핑, `hasStarted` idempotent, `pathUpdateHandler` MainActor hop
3. `Core/App/AppCurrencyStore.swift` — `networkMonitor` 의존성 + `isOffline`/`cachedAt` computed
4. `Core/App/AppStore.swift` — `networkMonitor: any NetworkMonitorProtocol` non-optional, `currencyStore` 생성 시 cascade
5. `TravelCalculatorApp.swift` — `init()`에서 `appStore.networkMonitor.start()` 1회

→ `xcodebuild test` → **TEST SUCCEEDED** (142초, 신규 4개 통과, 기존 회귀 0)

### Green (리팩터링)
- 추가 정리 없음. 코드 깔끔. anti over-engineering 준수 (1회성 추상화 없음, 헬퍼 0개)
- `xcodebuild build` → **BUILD SUCCEEDED** (warning 0)

## 검증 (수동)

- [ ] `xcodebuild build` 성공 (warning 0)
- [ ] 시뮬레이터 → Settings → Wi-Fi off → 콘솔/로그로 `isOffline=true` 확인 (Step 2의 UI 없이는 시각 검증 불가, Step 1 단독 완료 기준은 빌드+테스트)
- [ ] `AppCurrencyStore` 단위 테스트: MockNetworkMonitor.isOffline 토글 시 store.isOffline 반영
