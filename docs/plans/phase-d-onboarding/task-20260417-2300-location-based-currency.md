# Phase D Step 2 — 위치 기반 통화 자동 선택

## 작업 설명

CurrencySelectView 위치 버튼을 활성화하여, 사용자가 탭하면 현재 위치의 ISO 국가코드를 조회해 Currency로 매핑하고 자동 선택한다. 권한/결과 케이스별로 Toast 피드백을 다르게 표시한다.

- 권한 `.notDetermined` → 시스템 권한 팝업 → 결과에 따라 아래 분기
- 권한 `.denied`/`.restricted` → Toast(info) 설정 안내 문구
- 권한 허용 + GPS → 역지오코딩 → ISO 코드
  - `KR` → Toast(info) "현재 위치는 한국입니다. 여행지 통화를 직접 선택해주세요" (통화 변경 없음)
  - `US`/`TW` → 자동 선택 (currencyStore.selectedCurrency = 해당 Currency) + Toast(success)
  - 기타 → Toast(warning) "현재 위치는 지원하지 않는 지역입니다"
  - 에러/10초 타임아웃 → Toast(error)

## 인터뷰 결과

- **딥링크**: Toast 본문 안내 문구만 (MVP). ToastPayload 인프라 변경 없음. 추후 개선 백로그.
- **타임아웃**: 10초 타임아웃 적용 (UX 보수적). `withTaskCancellationHandler` + `Task.sleep`으로 구현.
- **Info.plist**: pbxproj의 `INFOPLIST_KEY_*` 빌드 설정 패턴을 따라 `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` 추가 (Debug/Release 양쪽).
- **테스트**: `LocationServiceProtocol` Mock으로 Store 분기 로직을 테스트. 실제 `CLLocationManager` 래퍼는 단위 테스트 제외(통합성).

## 구현 계획

### 신규/수정 파일

1. **`Domain/Protocols/CurrentCountryCodeProvider.swift` (NEW)**
   ```swift
   @MainActor
   protocol CurrentCountryCodeProvider: Sendable {
       func requestCurrentCountryCode() async throws -> String  // ISO Alpha-2
   }

   enum LocationError: Error, Sendable {
       case permissionDenied
       case unavailable       // GPS/지오코딩 실패 / 타임아웃 통합
   }
   ```
   - 기능 중심 이름 (Codex 권고). 에러 2종 통합 유지.

2. **`Data/Location/LocationService.swift` (NEW)** — `@MainActor final class LocationService: NSObject, CurrentCountryCodeProvider, CLLocationManagerDelegate`
   - **단일 resume 중앙화**: `continuation: CheckedContinuation<String, Error>?` 프로퍼티 + `resume(with:)` private helper가 nil 체크 후 한 번만 resume + cleanup (delegate nil, geocoder cancel, timeout task cancel).
   - `requestCurrentCountryCode()`:
     1. 기존 continuation 있으면 `throw .unavailable` (중복 호출 방지)
     2. 권한 상태 확인:
        - `.denied`/`.restricted` → 즉시 `throw .permissionDenied` (권한 요청 재요청 금지)
        - `.notDetermined` → `requestWhenInUseAuthorization()` 호출, `locationManagerDidChangeAuthorization` 델리게이트 콜백에서 허용 시에만 `requestLocation()`, 거부 시 `.permissionDenied` resume
        - `.authorizedWhenInUse`/`.authorizedAlways` → 즉시 `requestLocation()`
     3. **타임아웃은 서비스 내부에서** (Codex 권고): `withCheckedThrowingContinuation`과 별도 Task.sleep(10s) 경쟁 → 타임아웃 시 cleanup + `.unavailable` resume
     4. `didUpdateLocations` → `CLGeocoder.reverseGeocodeLocation` → `.isoCountryCode` → resume(성공). nil/실패면 `.unavailable`
     5. `didFailWithError` → `.unavailable` resume
   - **늦은 콜백 무시**: cleanup 후 `continuation = nil`이라 후속 델리게이트 콜백은 resume helper의 nil 체크로 폐기.

3. **`Domain/Models/Currency.swift` (MOD)** — extension
   ```swift
   extension Currency {
       static func from(countryCode: String) -> Currency? {
           switch countryCode.uppercased() {
           case "KR": .KRW
           case "US": .USD
           case "TW": .TWD
           default: nil
           }
       }
   }
   ```

4. **`Presentation/CurrencySelect/CurrencySelectState.swift` (MOD)**
   - `isRequestingLocation: Bool = false` 추가 (버튼 disable + 스피너용).

5. **`Presentation/CurrencySelect/CurrencySelectIntent.swift` (MOD)**
   - `.requestLocation` / `.locationRequestStarted` / `.locationRequestFinished` 추가 (Codex 권고: 의미 기반 Intent).

6. **`Presentation/CurrencySelect/CurrencySelectReducer.swift` (MOD)**
   - `.locationRequestStarted` → `isRequestingLocation = true`
   - `.locationRequestFinished` → `isRequestingLocation = false`
   - `.requestLocation`은 순수 kickoff 신호 — State 변경 없음 (Store의 side effect로 처리).

7. **`Presentation/CurrencySelect/CurrencySelectStore.swift` (MOD)**
   - init에 `locationService: (any CurrentCountryCodeProvider)? = nil` 주입.
   - **공통 private method 추출** (Codex 권고): `applySelectedCurrency(_ currency: Currency, source: SelectionSource)`
     - `SelectionSource = .userTap | .location` 로 Toast 텍스트/생략 분기
     - 기존 `.selectCurrency` 흐름(Step 1에서 만든 것)도 이 메서드로 경유
     - 온보딩 모드 완료 처리(conversionDirection + callback)도 이 메서드에서 일관 처리
   - `send(.requestLocation)` 처리:
     ```
     guard !state.isRequestingLocation else { return }
     Task { await handleLocationRequest() }
     ```
   - `handleLocationRequest()`:
     1. `send(.locationRequestStarted)`
     2. `defer { send(.locationRequestFinished) }`
     3. `do { let code = try await locationService?.requestCurrentCountryCode() ... }`
     4. 성공 + `Currency.from(countryCode:)` 매핑:
        - `.KRW` → Toast(info) "현재 위치는 한국입니다. 여행지 통화를 직접 선택해주세요" (통화 변경 없음)
        - `.USD`/`.TWD` → `applySelectedCurrency(.USD/.TWD, source: .location)` (Toast success + 온보딩 완료 분기)
        - nil → Toast(warning) 미지원 지역
     5. `catch LocationError.permissionDenied` → Toast(info) 설정 안내 문구
     6. `catch` (그 외) → Toast(error) "현재 위치를 확인할 수 없습니다"

8. **`Presentation/CurrencySelect/CurrencySelectView.swift` (MOD)**
   - 위치 버튼: `.disabled(store.state.isRequestingLocation || locationService == nil)` 대신, `.disabled(store.state.isRequestingLocation)` (서비스 주입 여부는 Store가 판단하여 no-op 무시).
   - `store.send(.requestLocation)` 연결.
   - 로딩 중 `ProgressView()` 동반 표시.

9. **`TravelCalculator.xcodeproj/project.pbxproj` (MOD)**
   - Debug/Release 양쪽 빌드 설정에 추가:
     `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "현재 위치의 여행지 통화를 자동으로 선택하는 데 사용합니다.";`

### TDD 접근

- **Red**: `CurrencySelectStoreTests.swift` 에 테스트 추가
  - `MockLocationService` (작동/에러 주입 가능)
  - `requestLocation_korea_showsInfoToast_keepsCurrency` (KRW 감지)
  - `requestLocation_supportedForeign_selectsCurrency` (US → USD)
  - `requestLocation_unsupported_showsWarningToast` (JP → 변경 없음 + warning)
  - `requestLocation_denied_showsInfoToast` (LocationError.permissionDenied)
  - `requestLocation_unavailable_showsErrorToast`
  - `requestLocation_onboardingMode_completesOnSupportedForeign` (callback 호출 + conversionDirection)
  - Loading flag on/off 전이 확인
  - Toast 검증은 `ToastManager` 노출 상태(최근 toast)로 가능한지 확인 후 진행; 불가하면 `ToastManager` 스파이 주입
- **Yellow**: 최소 구현 — Intent 추가, Reducer 분기, Store async 처리, LocationService는 skeleton (테스트는 Mock으로만).
- **Green**: 실제 `LocationService` 구현 + Info.plist 키 추가 + View 연결. 빌드 성공 확인.

### Anti Over-Engineering 체크

- [x] 1회성 추상화: LocationServiceProtocol — 테스트 DI 목적으로 합리적 (2회 사용: 실구현 + Mock).
- [x] 헬퍼 3회 이상? `Currency.from(countryCode:)`는 1회 사용이지만 순수 함수 확장으로 인라인 불가.
- [x] 요청 범위 밖 추가: 없음 (settings deep link button 등은 MVP 제외).
- [x] MVI 패턴: Reducer는 `isRequestingLocation` 전이만, 나머지는 Store side effect.
- [x] `@MainActor`/Sendable: LocationService @MainActor, Protocol Sendable.
- [x] Decimal: 해당 없음.

## Codex Review

### 반영한 지적

1. **Protocol 이름을 기능 중심으로** — *반영함*. `LocationServiceProtocol` → `CurrentCountryCodeProvider`. `@MainActor` 프로토콜 격리 추가.
2. **`.setLocationLoading(Bool)` Intent 부자연스러움** — *반영함*. `.locationRequestStarted` / `.locationRequestFinished` 두 Intent로 교체 (의미 기반).
3. **타임아웃은 LocationService 내부에서 처리** — *반영함*. Store에서 처리 시 늦은 델리게이트 콜백 정리를 놓치기 쉬움.
4. **US/TW 자동 선택 시 재귀 `.selectCurrency` 디스패치 대신 공통 private method** — *반영함*. `applySelectedCurrency(_:source:)` 추출, Step 1의 `.selectCurrency` 핸들링도 이 메서드로 경유하도록 리팩터링.
5. **CLLocationManager 브리징 함정**:
   - 단일 resume 중앙화 (`resume(with:)` helper + nil 체크 + cleanup) — *반영함*
   - `.notDetermined` → `locationManagerDidChangeAuthorization` 콜백 후에만 `requestLocation()` — *반영함*
   - 이미 denied면 권한 재요청 금지 — *반영함*
   - timeout 후 늦은 콜백은 `continuation == nil`로 무시, `geocoder.cancelGeocode()` — *반영함*

### 유지한 설계

- `LocationError` 2종(denied/unavailable) 통합 — *유지*. UI 분기 수준에서 적절.
- locationService 옵셔널 주입 (nil 허용) — *유지*. 테스트/Preview 편의.

### 무시한 지적

없음.

## TDD 사이클 로그

- **Red**: `CurrencySelectStoreLocationTests` 8케이스 + `CurrencyFromCountryCodeTests` 5케이스 작성. `MockCountryCodeProvider` 스파이 추가. 컴파일 실패(프로토콜/에러 미정의)로 Red 확인.
- **Yellow**: `CurrentCountryCodeProvider` 프로토콜 + `LocationError` 신규, `Currency.from(countryCode:)` nonisolated 확장, `CurrencySelectState.isRequestingLocation`, `CurrencySelectIntent` 확장(.requestLocation/.locationRequestFinished), `CurrencySelectStore`에 `locationService` 주입 + `applySelectedCurrency(_:source:)` 공통 메서드 + `handleLocationRequest()` async 분기. 테스트 pollution 이슈(shared UserDefaults) 해결 위해 makeStore에서 suite-scoped UD 주입. 전체 테스트 통과.
- **Green**: 실제 `LocationService` 구현 (CheckedContinuation 단일 resume + 10s 타임아웃 + delegate 콜백 브리징), `CurrencySelectView` 위치 버튼 활성화 + 로딩 표시, `CalculatorView` sheet 경로에 `LocationService()` 주입, `project.pbxproj` Debug/Release 양쪽에 `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` 추가. 전체 테스트 통과.

## 검증 방법

- 단위 테스트: `xcodebuild … test` — 6~7개 신규 케이스 통과.
- 수동 테스트(시뮬레이터): Features → Location → Apple → 미국 좌표 선택 → 위치 버튼 탭 → USD 자동 선택. Custom Location으로 한국(37.5, 127) → Toast info 확인.
- 권한 팝업: 첫 실행 시 `.notDetermined` 확인.
