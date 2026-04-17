# Phase D Step 3 — ContentView 온보딩 분기 + AppStore 통합

## 작업 설명

`appStore.hasCompletedOnboarding` 기반으로 첫 실행 시 `CurrencySelectView(isOnboarding: true)` 를 풀스크린 표시하고, 사용자가 통화를 선택하면 플래그가 켜지면서 `CalculatorView`로 전환되는 플로우 완성. 온보딩과 환율 API 로딩은 병렬 실행.

## 인터뷰 결과

- 내부 스코프 판단:
  - ContentView 분기: `hasCompletedOnboarding` 관찰 + 2분기 렌더링
  - AppStore 팩토리: `makeOnboardingCurrencySelectStore(toastManager:)` — 본 태스크 내 유일한 호출부(ContentView) + 테스트에서 재사용되므로 `3회 미만`이지만 `AppStore`의 concern(온보딩 완료 처리)을 캡슐화하는 것이 MVI coordinator 역할에 부합.
  - callback 캡처: `[weak self]`. Store의 수명이 온보딩 도중이지만 view cycle에 따라 꼬일 수 있어 retain 사이클 방지.
  - 환율 에러 오버레이: 온보딩 중에는 숨김(스펙 2.7.4 — 계산기 진입 후에만 전체 화면 에러).

## 구현 계획

### 수정 파일

1. **`Core/App/AppStore.swift`**
   - `@MainActor` 팩토리 추가:
     ```swift
     func makeOnboardingCurrencySelectStore(toastManager: ToastManager) -> CurrencySelectStore {
         CurrencySelectStore(
             toastManager: toastManager,
             currencyStore: currencyStore,
             isOnboarding: true,
             onOnboardingComplete: { self.hasCompletedOnboarding = true },
             locationService: LocationService()
         )
     }
     ```
   - **weak self 불필요** (Codex 권고): AppStore → onboardingStore 역방향 참조 없음. 순환 참조 없으므로 strong capture.

2. **`ContentView.swift` + 신규 `OnboardingCurrencySelectContainer`**
   - Codex 권고: optional lazy state 대신 온보딩 전용 컨테이너 분리.
     ```swift
     struct OnboardingCurrencySelectContainer: View {
         @State private var store: CurrencySelectStore
         init(appStore: AppStore, toastManager: ToastManager) {
             _store = State(initialValue: appStore.makeOnboardingCurrencySelectStore(toastManager: toastManager))
         }
         var body: some View { CurrencySelectView(store: store) }
     }
     ```
   - `ContentView`:
     ```swift
     if !appStore.hasCompletedOnboarding {
         OnboardingCurrencySelectContainer(appStore: appStore, toastManager: toastManager)
     } else {
         CalculatorView(toastManager: toastManager, currencyStore: appStore.currencyStore)
             .overlay { if let e = appStore.currencyStore.unavailableRateError { ExchangeRateErrorView(...) } }
     }
     ```
   - 상위에 `.task { await appStore.currencyStore.loadExchangeRates() }` 유지 (Spec 2.7.4 "앱 실행과 동시에 환율 API 호출 시작" — preload 의도).
   - 에러 오버레이는 Calculator 분기 내부에만 적용.

3. **`CurrencySelectStore`에 공개 getter 추가 필요 여부 검토**
   - Step 1에서 `isOnboarding`/`onOnboardingComplete` 이미 init으로 수용. 추가 변경 없음.

4. **conversionDirection = .selectedToKRW 보장**
   - Step 1의 `applySelectedCurrency` 가 onboarding에서 이미 세팅. 본 Step에서 별도 코드 추가 불필요. 완료 기준 검증만.

### 테스트 대상

`AppStoreTests.swift` 신규(또는 기존 파일 확장):
- `makeOnboardingCurrencySelectStore_returnsStore_withIsOnboardingTrue`
- `makeOnboardingCurrencySelectStore_callback_flipsHasCompletedOnboarding` (콜백을 통해 selectCurrency 후 플래그 true 확인)
- `hasCompletedOnboarding_persists_toUserDefaults` (Step 0.1.1 검증 — 없으면 추가)

`ContentView` 분기는 SwiftUI 뷰라 단위 테스트 제외. 시뮬레이터 수동 검증으로 갈음.

### TDD

- Red: `AppStoreTests` 에 위 케이스 추가. 팩토리 메서드 없어서 컴파일 실패.
- Yellow: `makeOnboardingCurrencySelectStore(toastManager:)` 최소 구현. 테스트 통과.
- Green: `ContentView` 분기 코드 반영 + 빌드 성공.

### Anti Over-Engineering 체크

- [x] 1회성 추상화: 팩토리 메서드는 AppStore(coordinator) 책임에 맞고, 테스트/호출부 2곳에서 사용 — 유지.
- [x] 헬퍼 3회 이상 재사용? 2회지만 DI 캡슐화 목적 — 유지.
- [x] 요청 범위 밖 기능: 없음.
- [x] MVI 일관성: Reducer 변경 없음. AppStore가 상위 coordinator로서 factory 제공은 기존 패턴.
- [x] `@MainActor`/Sendable: 팩토리와 콜백 모두 @MainActor. weak self 캡처.
- [x] Decimal: 해당 없음.

## Codex Review

### 반영한 지적

1. **Optional lazy state → 온보딩 전용 컨테이너 분리** — *반영함*. `OnboardingCurrencySelectContainer`에 `@State initialValue`로 store를 1회 생성. `onAppear` + optional placeholder 제거.
2. **`[weak self]` 불필요** — *반영함*. AppStore는 앱 수명 내내 생존, 순환 참조 없음. strong capture로 단순화.
3. **환율 preload는 `.task` 상위 유지** — *반영함*. Spec 2.7.4 의도에 부합.

### 유지한 설계

- 팩토리 메서드 `makeOnboardingCurrencySelectStore(toastManager:)` — *유지*. Codex도 유지 권장 (컨텍스트별 DI 책임 캡슐화).
- Calculator 에러 오버레이는 else 분기 한정 — *유지*.

### 무시한 지적

없음.

## TDD 사이클 로그

- **Red**: `TravelCalculatorTests/Core/AppStoreTests.swift` 신규(3 케이스: 팩토리 반환 store의 isOnboarding, 콜백 동작으로 hasCompletedOnboarding flip, UserDefaults persist). 팩토리 미존재로 컴파일 실패.
- **Yellow**: `AppStore.makeOnboardingCurrencySelectStore(toastManager:)` 구현. 3/3 신규 테스트 + 전체 회귀 없음.
- **Green**: `ContentView` 분기 + private `OnboardingCurrencySelectContainer` wrapper 추가. `.task` 상위 유지. 에러 오버레이는 Calculator 분기 한정. 전체 테스트 통과.

## 검증 방법

- `xcodebuild test` — 신규 AppStore 테스트 통과.
- 시뮬레이터: 앱 삭제 → 첫 실행 → 통화 선택 화면 풀스크린 + X버튼/스와이프 dismiss 차단 → 통화 선택 → 계산기 전환. 재실행 시 온보딩 건너뛰기.
- 온보딩 중 env.Features → Location으로 US 좌표 선택 → 위치 버튼 탭 → USD 자동 선택 + 계산기 진입.
