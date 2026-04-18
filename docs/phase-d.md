# Phase D — Onboarding (온보딩 화면)

> 브랜치: `phase/d-onboarding`
> 목표: 첫 실행 시 통화 선택을 강제하는 온보딩 플로우 + 위치 기반 통화 자동 선택 구현.

---

## 구현 목표

1. `CurrencySelectView` 온보딩 모드 지원 (`isOnboarding: Bool`) — KRW 제외, X 버튼 숨김, 타이틀 교체, 스와이프-다운 차단
2. `ContentView` 에서 `hasCompletedOnboarding` 기반 온보딩/계산기 분기
3. 온보딩 플로우: 통화 선택 → `hasCompletedOnboarding = true` → 계산기 진입 (환율 로딩과 병렬)
4. 위치 기반 자동 선택: `CLLocationManager` + 역지오코딩 → Currency 매핑
5. 위치 감지 결과 분기: 한국(KRW) → Toast(info), 지원 여행지(USD/TWD) → 자동 선택, 미지원 → Toast(warning), 권한 거부 → Toast(info) + 설정 딥링크
6. 온보딩 완료 직후 `conversionDirection = .selectedToKRW` 보장

---

## 태스크 목록

### Step 1: 온보딩 모드 — CurrencySelectView / Store / State

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `Presentation/CurrencySelect/CurrencySelectState.swift` | `isOnboarding: Bool` 추가 (기본 false). 온보딩 모드에서만 currencies에서 KRW 제외 유지, 일반 모드에서는 KRW 포함 | Spec-Overview §2.7.2 |
| 1.2 | `Presentation/CurrencySelect/CurrencySelectStore.swift` | init에 `isOnboarding: Bool = false` 파라미터 추가. 온보딩 선택 시 `currencyStore.hasCompletedOnboarding = true` + `conversionDirection = .selectedToKRW` 세팅 (AppStore 주입 필요) | Spec-Overview §2.7.4~2.7.5 |
| 1.3 | `Presentation/CurrencySelect/CurrencySelectView.swift` | `isOnboarding` 시 X 버튼 숨김, 타이틀 "여행지 통화를 선택해주세요", subtitle 문구 조정, `.interactiveDismissDisabled()` | Spec-UI §3.3 |

### Step 2: 위치 기반 자동 선택 — LocationService + Currency 매핑

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `Data/Location/LocationService.swift` | `LocationServiceProtocol: Sendable` 정의 + `CLLocationManager` + `CLGeocoder` 구현. `requestCurrentCountryCode() async throws -> String` (ISO country code) | Spec-UI §3.2, Spec-Overview §2.7.3 |
| 2.2 | `Domain/Models/Currency.swift` (확장) | `Currency.from(countryCode:) -> Currency?` 헬퍼 (KR→KRW, US→USD, TW→TWD 등) | Spec-DataModel |
| 2.3 | `Presentation/CurrencySelect/CurrencySelectIntent.swift` | `.requestLocation`, `.locationResolved(Currency?)`, `.locationFailed(LocationError)` Intent 추가 | Spec-Overview §2.7.3 |
| 2.4 | `Presentation/CurrencySelect/CurrencySelectStore.swift` | `LocationServiceProtocol` 주입 + `handleLocationRequest()` async 처리. 한국→Toast(info) 통화 변경 없음, 지원 여행지→자동 선택+Toast(success), 미지원→Toast(warning), 권한 거부→Toast(info) + 설정 딥링크 버튼 | Spec-UI §3.2, Spec-Overview §2.7.3 |
| 2.5 | `Presentation/CurrencySelect/CurrencySelectView.swift` | 위치 버튼 `.disabled(false)` + action 연결, 로딩 중 상태 반영 | Spec-UI §3.2 |
| 2.6 | `TravelCalculator/Info.plist` 또는 프로젝트 설정 | `NSLocationWhenInUseUsageDescription` 추가 (한국어 안내 문구) | iOS 권한 |

### Step 3: ContentView 분기 + AppStore 통합

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `TravelCalculator/ContentView.swift` | `appStore.hasCompletedOnboarding == false` → `CurrencySelectView(isOnboarding: true)` 풀스크린 표시, true → `CalculatorView` | Spec-Overview §2.7.1 |
| 3.2 | 〃 | 온보딩 중에도 `loadExchangeRates()` 병렬 실행 (앱 시작 .task 유지) | Spec-Overview §2.7.4 |
| 3.3 | `Core/App/AppStore.swift` | 온보딩 `CurrencySelectStore` 팩토리 메서드 (`makeOnboardingStore(toastManager:)`) — LocationService 포함 DI | Spec-Architecture §4.3 |
| 3.4 | `Core/App/AppCurrencyStore.swift` | 온보딩 완료 시 `conversionDirection = .selectedToKRW`로 재설정하는 경로 확인 (이미 기본값이면 no-op, 아니면 API 추가) | Spec-Overview §2.7.5 |

---

## 완료 기준

- [ ] `xcodebuild` 빌드 성공 (warning 0, error 0)
- [ ] 첫 실행 (`hasCompletedOnboarding = false`) 시 CurrencySelectView 풀스크린 표시 + X 버튼 비노출 + 스와이프-다운 차단
- [ ] 온보딩 통화 목록에 KRW 미포함, 일반 모드에서는 KRW 포함
- [ ] 통화 선택 시 `hasCompletedOnboarding = true` 저장 + 계산기 화면 자동 진입 + `conversionDirection = .selectedToKRW`
- [ ] 위치 버튼: `.notDetermined` → 권한 팝업, `.denied` → Toast(info) + 설정 딥링크, `.granted` → 국가 감지
- [ ] 한국(KR) 감지 → Toast(info) "현재 위치는 한국입니다…" + 통화 변경 없음
- [ ] 지원 여행지(US/TW) 감지 → 자동 선택 + Toast(success) + 모달 닫힘 (온보딩에서는 계산기 진입)
- [ ] 미지원 국가 감지 → Toast(warning)
- [ ] 온보딩과 환율 로딩 병렬 진행 (통화 선택 즉시 계산기 진입 가능, 환율 로딩 중이면 스피너)
- [ ] 앱 재실행 시 온보딩 건너뛰고 계산기 바로 진입

---

## 파일 구조 (생성/수정 예정)

```
TravelCalculator/
├── ContentView.swift                              ← MOD
├── Info.plist (프로젝트 설정)                      ← MOD
├── Core/
│   └── App/
│       ├── AppStore.swift                         ← MOD
│       └── AppCurrencyStore.swift                 ← MOD (확인)
├── Data/
│   └── Location/
│       └── LocationService.swift                  ← NEW
├── Domain/
│   └── Models/
│       └── Currency.swift                         ← MOD (from(countryCode:))
└── Presentation/
    └── CurrencySelect/
        ├── CurrencySelectIntent.swift             ← MOD
        ├── CurrencySelectState.swift              ← MOD
        ├── CurrencySelectStore.swift              ← MOD
        └── CurrencySelectView.swift               ← MOD
```

---

## 다음 Phase

Phase E (`phase/e-offline-tests`): 오프라인 대응 (NWPathMonitor, 배너) + Reducer/환율 변환 단위 테스트
