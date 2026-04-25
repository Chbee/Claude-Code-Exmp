# Phase E — Step 2 (오프라인 UI) + Step 3 (재시도 로직)

## Context

Phase E의 Step 1(NetworkMonitor + AppCurrencyStore.isOffline/networkState/cachedAt computed)은 완료된 상태. 이제 다음 두 step을 함께 진행한다.

- **Step 2 (오프라인 UI)**: 사용자에게 오프라인 상태를 시각적으로 명확히 알리고, 새로고침을 안전하게 막는다. (배너, Toolbar 인디케이터, disabled affordance, 복귀 pulse)
- **Step 3 (재시도 + 에러 메시지)**: 일시적 네트워크/서버 장애에 자동 복구 — 2회 2초 간격 재시도, 친화적 메시지.

진행 후 `phase-e.md`의 완료 기준 8개 중 UI/재시도 관련 7개를 충족할 수 있다 (Step 4/5의 테스트 항목은 별도 task).

## 작업 설명

`/start-task phase-e.md` — 사용자 선택: **Step 2 + Step 3** 묶음.

## 인터뷰 결과

| 질문 | 결정 |
|------|------|
| 진행 범위 | Step 2 + Step 3 (UI + 재시도) |
| OfflineBanner 시간 표시 | **KST 고정 only** (`yyyy-MM-dd HH:mm KST`). 기기 로컬은 V2 백로그. |
| Step 3 재시도 적용 범위 | **network + 5xx 서버 에러**. 4xx/parsing은 즉시 fail. |
| 재시도 모두 실패 후 동작 | 기존 fallback 유지 (`fetchRates`의 cache → `noCacheAvailable` 에러). 재시도는 `fetchFromAPI` 내부에서만. |

phase-e.md에 이미 확정된 Step 2 결정사항(온→오프 Toast 없음, 복귀 pulse, disabled tap → Toast info, Toolbar 색+아이콘+a11y, 1초 grace period, unknown 비표시)은 그대로 따른다.

## 구현 계획

### Step 2: 오프라인 UI

#### 2-A. AppCurrencyStore — refresh 가능 조건에 online 결합
- **파일**: `TravelCalculator/Core/App/AppCurrencyStore.swift`
- **변경**: `isRefreshEnabled` 게터에 `&& networkState == .online` 추가.
  - 현재: `Date.now >= r.validUntil`
  - 변경 후: `Date.now >= r.validUntil && networkState == .online`
- **이유**: UI에서 disabled 토글을 위한 단일 진실 소스. tap-affordance Toast는 별도 처리(아래 2-D).

#### 2-B. OfflineBanner 신규 컴포넌트
- **파일 (신규)**: `TravelCalculator/Presentation/Common/OfflineBanner.swift`
- **API**:
  ```swift
  struct OfflineBanner: View {
      let isOffline: Bool          // state == .offline 일 때만 true
      let cachedAt: Date?
      // body: isVisible(@State, 1s grace 후 true)일 때 표시
  }
  ```
- **동작**:
  - `isOffline`이 true가 된 후 **1초 동안 유지되어야 표시**(`Task.sleep(nanoseconds: 1_000_000_000)` + `.task(id: isOffline)`로 cancellation 자연 처리). flapping 시 grace 안에 다시 false면 미표시.
  - `isOffline = false`로 바뀌면 즉시 사라짐.
  - 텍스트: `"오프라인 — \(KST formatted) 기준 데이터"` (cachedAt 없으면 `"오프라인 — 캐시 없음"`).
  - DateFormatter는 view 내부 `private static let formatter` (KST, `yyyy-MM-dd HH:mm`) — 1회성, 유틸 추가 안 함.
  - 등장/퇴장 transition: `.opacity.combined(with: .move(edge: .top))` + spring 애니메이션 (`response: 0.45, dampingFraction: 0.86` — Toast와 통일).
- **`unknown` 처리**: `isOffline`이 false이므로 자연스럽게 비표시. 컴포넌트는 `NetworkState`를 직접 받지 않고 `Bool`만 받아 단순화.

#### 2-C. CalculatorToolbar — 인디케이터 동적화
- **파일**: `TravelCalculator/Presentation/Calculator/CalculatorToolbar.swift`
- **변경**:
  - `let networkState: NetworkState` prop 추가.
  - 중간 인디케이터 영역:
    - `.online`: `Circle().fill(Color.appSuccess)` + "온라인" (현행 유지).
    - `.offline`: `Image(systemName: "wifi.slash").font(.system(size: 11))` (또는 size 12) + 텍스트 "오프라인", `Color.appWarning` (또는 `.orange`).
    - `.unknown`: 비표시 (`EmptyView` 또는 `.opacity(0)` placeholder — placeholder 채택해 레이아웃 유지).
  - `.accessibilityLabel`: "온라인" / "오프라인" / (unknown은 hidden).

#### 2-D. CalculatorView — 통합
- **파일**: `TravelCalculator/Presentation/Calculator/CalculatorView.swift`
- **변경**:
  1. `CalculatorToolbar`에 `networkState: currencyStore.networkState` 전달.
  2. Toolbar 아래, `CalculatorDisplay` 위에 `OfflineBanner(isOffline: currencyStore.isOffline, cachedAt: currencyStore.cachedAt)` 삽입.
  3. **Pulse 애니메이션**: `currencyStore.networkState`가 `.offline → .online`으로 바뀌는 순간 1회 scale 1.0→1.02→1.0 (총 ~0.6s).
     - `@State private var pulseScale: CGFloat = 1.0`
     - `.onChange(of: currencyStore.networkState) { old, new in if old == .offline && new == .online { withAnimation(.easeOut(duration: 0.3)) { pulseScale = 1.02 }; ... } }` — 두 단계 withAnimation으로 복귀.
     - `CalculatorDisplay`에 `.scaleEffect(pulseScale)`.
  4. **Disabled tap → Toast**: `CalculatorDisplay`의 `onRefresh`에서 `isOffline`인 경우 toast 발화.
     - 가장 단순하게: `onRefresh: { if currencyStore.isOffline { toastManager.show(.init(style: .info, message: "오프라인 시 갱신할 수 없어요")) } else { Task { await calculatorStore.refreshRates() } } }`
     - **단, `isRefreshEnabled = false`면 SwiftUI 버튼 자체가 비활성화되어 tap 이벤트가 안 옴**. → `CalculatorDisplay`의 새로고침 버튼은 `.disabled` 대신 색/투명도만 disabled처럼 보이고 tap은 받게 두거나, 버튼 외부 영역에 onTapGesture 오버레이.
     - **결정 (Codex 검증 후 확정)**: `CalculatorDisplay.swift:44`의 `.disabled(!isRefreshEnabled)` 제거하고 시각만 `.opacity(0.4)`로 표현. CalculatorView의 onRefresh closure에서 `currencyStore.isOffline` 분기 → Toast OR refresh. AppCurrencyStore.refreshExchangeRates의 `isRefreshEnabled` 가드는 backstop으로 유지.

#### 2-E. AppStore — start() 호출 위치 이동
- **파일**: `TravelCalculator/Core/App/AppStore.swift`, `TravelCalculator/TravelCalculatorApp.swift`
- **변경**: `appStore.networkMonitor.start()` 호출을 `TravelCalculatorApp.init`에서 `AppStore.init` 끝으로 이동. `TravelCalculatorApp.init`에서는 호출 제거.
- **이유**: 컨벤션 — App 레이어는 root composition만, 라이프사이클은 Store가 소유.

### Step 3: 에러 핸들링 + 재시도

#### 3-A. ExchangeRateError — 친화 메시지 보강
- **파일**: `TravelCalculator/Domain/Models/ExchangeRateError.swift`
- **현황 검토**: 이미 `errorDescription`이 한국어 친화 메시지 제공 중. 추가 작업 불필요 — `phase-e.md`의 "친화적 메시지 컴퓨티드 추가"는 사실상 완료 상태로 판단.
- **변경**: **없음**. 단, plan에서 명시적으로 "검토 결과 기존 구현 충분, 변경 없음"이라고 기록.

#### 3-B. ExchangeRateAPI — fetchFromAPI 재시도 로직
- **파일**: `TravelCalculator/Data/Network/ExchangeRateAPI.swift`
- **변경**: `fetchFromAPI(currencies:)` 진입부에 retry loop 추가. 기존 단일 시도를 최대 3회(초기 + 2회 재시도)로 감싼다.
  ```swift
  // 초기 1회 + 재시도 2회 = 총 3회 시도 (spec "재시도 최대 2회")
  private static let maxAttempts = 3
  private let retryDelay: Duration  // default .seconds(2), tests inject .zero

  private func fetchFromAPI(currencies: [Currency]) async throws -> ExchangeRateResponse {
      var lastError: Error = ExchangeRateError.networkError
      for attempt in 0..<Self.maxAttempts {
          do {
              return try await fetchAttempt(currencies: currencies)
          } catch let error as ExchangeRateError where Self.shouldRetry(error) {
              lastError = error
              if attempt < Self.maxAttempts - 1 {
                  try await Task.sleep(for: retryDelay)
              }
          } catch {
              throw error  // 4xx, parsing, noDataAvailable 등 즉시 throw
          }
      }
      throw lastError
  }

  private static func shouldRetry(_ error: ExchangeRateError) -> Bool {
      switch error {
      case .networkError: return true
      case .serverError(let code): return (500...599).contains(code)
      default: return false
      }
  }
  ```
- 기존 `fetchFromAPI` 본문은 `fetchAttempt`로 이름 변경(rename refactor). 외부 동작 동일.
- **타임아웃 10초**: 현재 `URLSession.shared`의 기본 timeout(60s)을 그대로 사용 중. 이를 10s로 줄이려면 별도 `URLSessionConfiguration.timeoutIntervalForRequest = 10`이 필요한데, ExchangeRateAPI의 init이 외부 session을 받으므로 default session을 변경하면 부수 영향이 있다. → **최소 변경 원칙**: 이번 task에서는 timeout 변경 보류. spec 문구 "Timeout 10s"는 next iteration 또는 별도 결정 필요. plan에 명시.
- `Task.sleep` 호출이 cancellation을 throw할 수 있으므로 `try` 처리 — 호출자가 task를 취소하면 자연 전파.

### TDD 순서

1. **Red — Step 3 재시도**:
   - `ExchangeRateAPITests`에 신규 테스트:
     - `test_재시도_네트워크_에러_2회_후_성공` — MockURLSession이 2번 throw, 3번째 성공 → 정상 응답.
     - `test_재시도_5xx_후_성공` — 503 → 503 → 200.
     - `test_4xx_즉시_실패_재시도_없음` — 400 1회만 호출됨.
     - `test_3회_모두_실패_시_마지막_에러_throw` — call count == 3, error == networkError.
   - `Task.sleep`이 들어 있으므로 테스트에서는 빠른 진행이 필요 → **clock injection 도입 vs 짧은 실시간 슬립**: 실시간 2초 × 2 = 4초 추가/테스트. clock 주입 도입은 over-engineering 가능 → **결정**: 재시도 간격을 `private static let retryDelayNanos: UInt64 = 2_000_000_000`로 빼고, **테스트에서는 ExchangeRateAPI에 internal init 파라미터로 delayNanos 주입 가능하게**. 1회성 추상화이지만, 4초 슬립을 매 테스트마다 발생시키는 게 더 큰 비용이라 정당화. (Codex 검증에서 over-engineering 판단 받기.)
2. **Yellow** — 재시도 로직 작성, 테스트 통과.
3. **Green** — 정리 (메소드 분리 클린업).
4. **Red — Step 2 UI**:
   - UI는 단위 테스트보다 빌드 + manual 검증이 주. 단, `OfflineBanner.isVisible`의 1초 grace 로직은 분리해서 단위 테스트 가능 — 다만 `Task.sleep` 의존이라 over-engineering 우려. **결정**: View 통합 테스트는 생략, 로직 충분히 단순하므로 manual 검증.
5. **Yellow → Green** — UI 구현 후 빌드 통과, 시뮬레이터 수동 검증.

## Codex Review

Codex(GPT-5)에게 plan 검증 요청. 받은 피드백과 반영 결과:

1. **Grace period의 cancellation 처리** — 반영함
   - 지적: `.task(id: isOffline) { try? await Task.sleep(...); isVisible = true }`는 `try?`가 `CancellationError`를 삼켜서, 취소된 task가 여전히 `isVisible = true`를 set할 수 있는 race.
   - 수정: `try?` 대신 `do { try await Task.sleep(...) } catch { return }`로 cancellation 시 조기 return.
   - 코드 형태:
     ```swift
     .task(id: isOffline) {
         guard isOffline else { isVisible = false; return }
         do {
             try await Task.sleep(nanoseconds: 1_000_000_000)
         } catch { return }  // cancellation: do not flip visibility
         isVisible = true
     }
     ```

2. **Refresh 버튼 disabled affordance** — 반영함
   - 지적: 현재 `CalculatorDisplay.swift:44`에서 진짜 `.disabled`이고 store도 `refreshExchangeRates`에서 `isRefreshEnabled`로 가드. "시각적으로 disabled, tap 가능"으로 가려면 `.disabled` 제거 + view onRefresh closure에서 분기, store 가드는 backstop으로 유지.
   - 수정: CalculatorDisplay에서 새로고침 버튼의 `.disabled(!isRefreshEnabled)` 제거하고 `.opacity(...)`로 시각만 disabled. CalculatorView의 onRefresh closure에서 `isOffline` 분기 → toast OR refresh.

3. **재시도 횟수 표현 명확화** — 반영함
   - 지적: "max 3 attempts"가 모호. spec은 "재시도 2회".
   - 수정: 코드/주석 모두 "초기 1회 + 재시도 2회 = 총 3회 시도"로 명시.

4. **OfflineBanner API** — 반영함 (현행 유지)
   - 판단: 배너가 grace timer를 자체 소유하므로 `(isOffline, cachedAt)` API 유지 OK. 부모는 visibility 분기하지 않음.

5. **DateFormatter 스레드 안전성** — 반영함
   - 지적: `private static let formatter`(DateFormatter)는 스레드 안전 X.
   - 수정: `Date.FormatStyle`(`Asia/Seoul` TimeZone)로 변경. iOS 17+ 사용 가능.
     ```swift
     let kstStyle = Date.FormatStyle(date: .numeric, time: .shortened)
         .timeZone(TimeZone(identifier: "Asia/Seoul")!)
     ```
     또는 명시적 `verbatim`으로 `yyyy-MM-dd HH:mm`.

6. **retryDelayNanos → Duration 사용** — 반영함
   - 지적: raw nanoseconds보다 `Duration` 쓰는 게 깔끔.
   - 수정: 내부 init 파라미터를 `retryDelay: Duration = .seconds(2)`로. `Task.sleep(for: retryDelay)` 사용.

7. **재시도 헬퍼(retry(times:))** — 무시함: Codex도 "over-engineering, inline 유지" 지지.
8. **keyframeAnimator** — 무시함: Codex가 "one-shot scale pulse엔 두 단계 withAnimation이 더 적절" 지지.

Anti-OE 체크리스트 결과:
- 1회성 추상화: `retryDelay` injection은 테스트 시간 단축으로 정당화. OfflineBanner API는 grace 소유 덕에 OK.
- 헬퍼 3회+ 재사용: 해당 없음 — 모두 inline.
- 범위 외 추가: 없음 (timeout 10s는 명시적으로 제외).
- MVI 충돌: 없음 — banner grace/pulse/toast는 view 레이어, retry는 API 레이어.
- @MainActor/Sendable: grace task의 cancellation 정확화 반영.
- Decimal 보존: 변경 없음.

## TDD 사이클 로그

### Step 3 — 재시도 (Red → Yellow → Green)
- **Red**: `ExchangeRateAPIRetryTests` 4건 추가 (`SequencedHandler` actor + retryDelay: .zero 주입). 빌드 실패로 Red 확인 (extra argument 'retryDelay').
- **Yellow**: `ExchangeRateAPI`에 `retryDelay: Duration = .seconds(2)` init 인자, `maxAttempts = 3` 상수, `fetchFromAPI` 안에 retry loop, `fetchAttempt`로 본문 분리, `shouldRetry(_:)` static helper. 4건 통과.
- **Green**: 추가 정리 없음 — Codex 권고대로 inline 유지. 기존 테스트 회귀 없음 (apiFailure 계열 3건은 4초씩 걸리지만 결과 OK).

### Step 2-A — isRefreshEnabled (Red → Yellow → Green)
- **Red**: `AppCurrencyStoreOfflineTests`에 4건 추가 (online+expired/offline/unknown/online+notExpired).
- **Yellow**: `isRefreshEnabled`에 `&& networkState == .online` 추가. 4건 통과.
- **Green**: 회귀 — `AppCurrencyStoreTests`의 2건이 networkMonitor 미주입으로 깨짐 → `MockNetworkMonitor(state: .online)` 명시 주입으로 수정. 전체 테스트 통과.

### Step 2-B/C/D/E — UI (build-driven)
- 단위 테스트 없이 빌드 + 수동 검증 기반.
- `OfflineBanner.swift` 신규: `.task(id: isOffline)` + `try await Task.sleep` + `catch return`로 cancellation race 방지(Codex 지적 반영). KST 포맷은 `Calendar.kst.dateComponents` 인라인.
- `CalculatorToolbar.swift`: `networkIndicator` @ViewBuilder, online/offline/unknown 분기 + a11y 레이블.
- `CalculatorView.swift`: 배너 통합, `pulseScale` @State + `.onChange(of: networkState)` 두 단계 `withAnimation` (`DispatchQueue.main.asyncAfter`로 0.3s 후 복귀), `handleRefreshTap` private method에서 isOffline 분기 → ToastPayload(.info, "오프라인 시 갱신할 수 없어요").
- `CalculatorDisplay.swift`: `.disabled(!isRefreshEnabled || isLoading)` → `.disabled(isLoading)`로 변경. tap은 항상 받고 분기는 부모에서.
- `AppStore.init`에 `networkMonitor.start()` 추가, `TravelCalculatorApp.init`에서 호출 제거.
- `xcodebuild build` ✅ warning 0 / error 0.
- 전체 `xcodebuild test` ✅ 통과 (179s).

### 팀 검증 후 후속 패치 (사용자 승인)
1. **Pulse 애니 Task 기반 전환** — `DispatchQueue.main.asyncAfter` → `Task { @MainActor in ... try? await Task.sleep(for: .milliseconds(300)) }`. (Simplify+컨벤션 합의)
2. **`AppStore.networkMonitor` 죽은 저장 프로퍼티 제거** — 외부 참조 0건 grep 확인. init 인자(`networkMonitor:`)는 테스트 mock 주입용으로 유지, 단 `currencyStore`에만 주입 후 `start()` 호출.
3. **Spec-Overview §2.5.3 deviation 1줄 추가** — 기존 "Toast(info, ...)" 항목에 strikethrough + "구현 결정: Toast 미사용, 배너만" 명시.
4. **URLRequest timeout 10s 적용** — `ExchangeRateAPI.defaultSession`을 `URLSessionConfiguration.default(timeoutIntervalForRequest: 10, timeoutIntervalForResource: 30)`으로 인스턴스화. `nonisolated(unsafe)` static로 init 기본값 충돌 회피. 테스트는 MockURLSession이라 무관.
5. **Refresh tap unknown 분기 추가** — `handleRefreshTap`을 `switch networkState`로 변경: offline → "오프라인 시 갱신할 수 없어요", unknown → "네트워크 확인 중이에요", online → 실제 refresh.
6. **Refresh tap 0.8s throttle** — `@State lastRefreshTapAt`로 같은 안내 Toast 연타 중복 방지.

전체 테스트 통과 (170s, TEST SUCCEEDED).

---

## 영향 파일 요약

| 파일 | 변경 종류 | Step |
|------|-----------|------|
| `Core/App/AppCurrencyStore.swift` | MOD (`isRefreshEnabled` 조건 추가) | 2 |
| `Core/App/AppStore.swift` | MOD (`start()` 호출 추가) | 2 |
| `TravelCalculatorApp.swift` | MOD (`start()` 호출 제거) | 2 |
| `Presentation/Common/OfflineBanner.swift` | NEW | 2 |
| `Presentation/Calculator/CalculatorToolbar.swift` | MOD (networkState prop, 동적 인디케이터) | 2 |
| `Presentation/Calculator/CalculatorView.swift` | MOD (배너 통합, pulse, disabled tap) | 2 |
| `Presentation/Calculator/CalculatorDisplay.swift` | MOD 가능 (구조 보고 결정) | 2 |
| `Domain/Models/ExchangeRateError.swift` | NO-CHANGE | 3 |
| `Data/Network/ExchangeRateAPI.swift` | MOD (재시도 루프) | 3 |
| `TravelCalculatorTests/Data/ExchangeRateAPITests.swift` | MOD (재시도 테스트 4건 추가) | 3 |

## 검증 기준 (완료 시)

- `xcodebuild build` warning 0, error 0
- `xcodebuild test` 신규 재시도 테스트 4건 통과 + 기존 테스트 전부 통과
- 시뮬레이터: Wi-Fi off → 1초 후 배너 등장 + Toolbar 색/아이콘 전환
- 비행기 모드 첫 실행 → unknown→offline 즉시 (온라인 표시 안 보임)
- Wi-Fi on 복귀 → 환율 영역 pulse + 배너 사라짐
- 새로고침 disabled tap → Toast info "오프라인 시 갱신할 수 없어요"
- VoiceOver: "온라인" / "오프라인" 레이블

## 명시적 비범위 (이번 task에서 다루지 않음)

- Step 4: CalculatorReducer 단위 테스트 — 별도 task.
- Step 5: 환율 변환 테스트 — 별도 task.
- 기기 로컬 시간 병기 — V2.
- API timeout 10s 강제 — 별도 결정 필요 (현재 URLSession default 사용).
- 단일 N일 전 grain → V2.
