# TravelCalculator 포팅 + 개발 설계 플랜

## Context
기존 `Chbee/TravelCalculator` (develop 브랜치)의 MVI 아키텍처 기반 여행 계산기 앱을
`Chbee/Claude-Code-Exmp` 레포로 포팅한다.
이 레포는 **바이브 코딩으로 생산성을 측정하기 위한 개인 실험 프로젝트**이다.

---

## 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 아키텍처 | MVI (Model-View-Intent) — 기존 유지 |
| 최소 iOS 버전 | **iOS 18** (95%+ 점유율, 현재-1 원칙) |
| .xcodeproj | 기존 유지 (fileSystemSynchronization 활용) |
| 보일러플레이트 | Infrean20260327 → TravelCalculator로 리네이밍 |
| Figma MCP | 나중에 연결 |
| API 키 | APIKeys.swift (.gitignore) + 템플릿 |

---

## iOS 버전 점유율 분석 (2026년 4월)

| iOS 버전 | 점유율 | 누적 |
|----------|--------|------|
| iOS 26 | ~79% | 79% |
| iOS 18 | ~16% | 95% |
| iOS 17 이하 | ~5% | 100% |

→ **iOS 18을 최소 지원 버전으로 설정** (95%+ 커버리지)

---

## 기존 TravelCalculator 분석

### 아키텍처: MVI + Clean Architecture
```
State (순수 struct) → Reducer (순수 함수) → Store (@Observable) → View (SwiftUI)
```

### 진행률: 14/48 (29%)
- Milestone 1 계산기 UI: 78% (사칙연산, 포맷, 통화 선택, 8자리 제한)
- Milestone 2 환율 로직: 0% (API 연동, 실시간 변환)
- Milestone 3 오프라인: 0%
- Milestone 4 테스트: 0%

### 기존 32개 파일 구조
```
Core/         AppStore, AppCurrencyStore, Haptic, Extensions
Domain/       Currency.swift (KRW, USD, TWD)
Data/         ExchangeRateAPI, LocationService, PermissionService
Presentation/ Calculator(9), CurrencySelect(4), Components(1), Toast(5)
```

---

## iOS 18 적응 사항

- `@Observable` 매크로 안정적 사용 (iOS 17+)
- `@Environment(Type.self)` 패턴 사용
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 유지
- 순수 값 타입에 `nonisolated` 추가

---

## 구현 순서 (6 Phase, 33파일)

### Phase 0: 정리 + 리네이밍 ✅
- 기존 보일러플레이트 삭제
- `Infrean20260327/` → `TravelCalculator/` 리네이밍
- `project.pbxproj` 수정 (path, bundle ID, deployment target)

### Phase A: Domain + Core (6파일)
- Currency.swift, AppCurrencyStore, AppStore, Double+Format, Preview+ColorScheme, Haptic

### Phase B: 공통 컴포넌트 (6파일)
- IconButton, Toast 시스템 5파일

### Phase C: 계산기 MVI 모듈 (9파일) — 핵심
- CalculatorView/Store/State/Reducer/Intent/Display/DisplayModel/Keypad/Toolbar

### Phase D: 통화 선택 MVI 모듈 (4파일)
- CurrencySelectView/Store/State/Intent

### Phase E: Data 레이어 (4파일)
- ExchangeRateAPI, LocationService, PermissionService, LocationPermissionService

### Phase F: 앱 진입점 + 설정 (4파일)
- TravelCalculatorApp.swift, ContentView.swift, APIKeys.swift, APIKeys.swift.template

---

## 최종 파일 트리

```
TravelCalculator/
├── TravelCalculatorApp.swift
├── ContentView.swift
├── Assets.xcassets/
├── Config/APIKeys.swift (.gitignore)
├── Core/App/          AppStore, AppCurrencyStore
├── Core/Extensions/   Double+Format, Preview+ColorScheme
├── Core/              Haptic.swift
├── Domain/Models/     Currency.swift
├── Data/Network/      ExchangeRateAPI.swift
├── Data/Location/     LocationService.swift
├── Data/Permission/   PermissionService, LocationPermissionService
├── Presentation/Calculator/       (MVI 9파일)
├── Presentation/CurrencySelect/   (MVI 4파일)
├── Presentation/Components/       IconButton.swift
└── Presentation/Common/Toast/     (5파일)
```

---

## 검증
1. Phase A: 컴파일 성공
2. Phase C: 계산기 키패드/사칙연산 동작
3. Phase F: 앱 실행, 전체 기능 동작
4. Strict Concurrency 경고 0개
