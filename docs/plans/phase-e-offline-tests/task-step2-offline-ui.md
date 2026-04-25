# Phase E Step 2 — 오프라인 UI

> 브랜치: `phase/e-offline-tests`
> 의존: Step 1 완료 (`NetworkState` enum, `AppCurrencyStore.networkState/isOffline/cachedAt` 노출)
> 새 세션 진입점: `/start-task phase-e.md Step 2 — 오프라인 UI` 또는 이 파일 경로 인용

---

## Context (작업 설명)

Step 1에서 노출한 `networkState`/`isOffline`을 UI에 반영. Toolbar 인디케이터, 환율 영역 위 배너, 새로고침 버튼 비활성화/affordance, 복귀 시 시각 신호를 추가한다.

**Spec 참조**: Spec-Overview §2.5.2/§2.5.3 / Spec-UI §1, §3.4 / Spec-Tasks 3.3.1/3.3.2/3.3.3

## 결정사항 (인터뷰 확정 — `/start-task` 인터뷰 단계 단축용)

| 항목 | 결정 | 근거 |
|------|------|------|
| 온→오프 Toast | **없음** (배너만) | 사용자 결정. Toast 스팸 방지 |
| 오프→온 복귀 신호 | **환율 영역 pulse 애니** (scale 1.0→1.02→1.0 한 번) | UX A-3, 햅틱·Toast 없이 시각 신호만 |
| 새로고침 disabled affordance | **tap 시 Toast(info, "오프라인 시 갱신할 수 없어요")** | UX A-7 |
| Toolbar 인디케이터 | **색 + 아이콘 모양 변경 + VoiceOver 레이블** | UX A-9, 색맹/저시력/VoiceOver 사용자 대응 |
| 배너 grace period | **1초 지연** (`Task.sleep` + cancellation) | flapping 시 깜빡임 흡수 |
| 배너 시간 포맷 | `yyyy-MM-dd HH:mm` | Spec-Overview §2.5.2 |
| `unknown` 상태 UI | 배너/인디케이터 비표시, 새로고침 disabled | Step 1 결정 |
| "N일 전" grain | 단일 ("N일 전") | V1 단순화, V2 백로그 (1일/3일+ 단계화) |
| `networkMonitor.start()` 위치 | **`AppStore.init`으로 이동** (TravelCalculatorApp 단순화) | 컨벤션 M3 |
| 입력 보존 / 캡티브 포털 / progressive timeout | Step 3+4 분리 | 범위 분리 |

## 구현 계획

### 신규 파일

**1. `TravelCalculator/Presentation/Common/OfflineBanner.swift`**
- `struct OfflineBanner: View`
- 입력: `cachedAt: Date?`
- `cachedAt != nil` 일 때만 시각 표시. 포맷: `"오프라인 — yyyy-MM-dd HH:mm 기준 데이터"` (KST)
- 1초 grace period: 부모가 `state == .offline`이 된 후 1초 뒤 등장 시작 (`task` modifier + Task.sleep + cancellation으로 짧은 flapping 흡수)
- 스타일: 환율 영역 위, warning 톤 (Spec-UI §1)

### 수정 파일

**2. `TravelCalculator/Presentation/Calculator/CalculatorToolbar.swift`**
- 인디케이터 추가: `state == .offline` 시 wifi-off 아이콘 + warning 색, `state == .online` 시 ● 또는 비표시
- `state == .unknown` 시 비표시
- `.accessibilityLabel("오프라인" / "온라인")` 분기
- 색맹 대응: 색 + 모양 이중 신호

**3. `TravelCalculator/Presentation/Calculator/CalculatorView.swift`**
- OfflineBanner 통합: 환율 정보 영역 위에 배치
- 새로고침 버튼: `disabled(currencyStore.networkState != .online)` 또는 기존 `isRefreshEnabled`와 결합 — 단, **disabled여도 tap action 받기** 위해 별도 처리
  - 옵션 A: `Button { ... }` 에 `.allowsHitTesting(true)` + 내부 분기로 disabled 시 Toast 발화
  - 옵션 B: 시각적 disabled + 별도 tap gesture
  - **권장 옵션 A** — 간단
- 복귀 pulse: `onChange(of: currencyStore.networkState)` 에서 `online` 진입 시 환율 영역 scale 애니메이션 1회 (이전이 `.offline`인 경우만, `unknown→online`은 발화 X)
  - State 1개 추가: `@State private var pulseTrigger = 0`, `.scaleEffect(...)` 또는 `phaseAnimator`

**4. `TravelCalculator/Core/App/AppStore.swift`**
- `init` 끝부분에 `networkMonitor.start()` 호출 추가
- `currencyStore` 생성 후

**5. `TravelCalculator/TravelCalculatorApp.swift`**
- `init()` 제거 → `@State private var appStore = AppStore()` 원복

### 영향 범위 / 회귀 위험

- 기존 새로고침 버튼 동작 회귀 위험 (옵션 A 적용 시 tap action 두 분기) — 테스트 필요
- 배너 등장 grace period 1초가 너무 길어 보이면 0.5초로 단축 (UX 검증 후 조정)
- pulse 애니메이션이 키 입력 중 발생하면 산만 — 이미 입력 중인 텍스트는 영향 X (별도 영역)

## TDD 전략

### Red
- `OfflineBannerTests`: 시간 포맷팅 단위 테스트
- `CalculatorViewSmokeTests` 또는 기존 smoke에 추가:
  - `state == .offline + cachedAt 있음` → 배너 노출 (1초 후)
  - `state == .unknown` → 배너 미노출
  - `state == .online` → 배너 미노출, 새로고침 enabled
- `CalculatorRefreshActionTests`:
  - `state == .offline` 일 때 refresh tap → ToastManager.show 호출됨 (Mock)

> SwiftUI View 자체의 시각 상태(scale, opacity 등)는 단위 테스트 어려움. 핵심 로직(분기/Toast 발화/포맷팅)만 단위 테스트로 잠그고, 시각은 시뮬 수동 검증.

### Yellow
1. OfflineBanner 신규 (포맷팅 + grace period 로직)
2. CalculatorToolbar 인디케이터 분기
3. CalculatorView 통합 + refresh action 분기 + pulse 트리거
4. AppStore.init에 start() 이동
5. TravelCalculatorApp 단순화

### Green
- 빌드 warning 0
- pulse 애니메이션 자연스러움 (스프링 0.3s 등 default)

## Codex Review

(Step 2 시작 시 plan 검증 단계에서 채움)

## TDD 사이클 로그

(승인 후 채움)

## 검증 시나리오 (Step 7)

### 자동
- `xcodebuild ... test -only-testing:TravelCalculatorTests/{OfflineBannerTests, CalculatorRefreshActionTests}`

### 수동 (시뮬레이터, 이번엔 UI 들어가니 수동 시나리오 의미 있음)

| # | 시나리오 | 기대 |
|---|---------|------|
| A | Wi-Fi 켠 채 앱 실행 | 인디케이터 ●(online), 배너 없음, 새로고침 enabled |
| B | **비행기 모드 ON 상태로 첫 실행** | 인디케이터 처음 비표시(unknown) → 배너/인디케이터 1초 뒤 offline 표시. **잠깐도 online처럼 안 보임** |
| C | 실행 중 Wi-Fi off | 1초 후 배너 등장, 인디케이터 wifi-off, 새로고침 disabled, **Toast 없음** |
| D | 새로고침 disabled 상태 tap | Toast(info, "오프라인 시 갱신할 수 없어요") |
| E | Wi-Fi 복구 (오프→온) | 배너 사라짐 + 환율 영역 짧은 pulse, **Toast 없음** |
| F | 짧은 flapping (1초 안 끊김 → 복귀) | 배너 등장 안 함 (grace period 흡수) |
| G | VoiceOver | 인디케이터 포커스 시 "오프라인" / "온라인" 음성 |

### 엣지 케이스
- pulse 애니메이션 중 사용자가 키 입력 → 입력 영향 없음 확인
- cachedAt이 nil인데 offline 진입 (캐시 없음 + 오프라인) → 배너 어떻게 표시? (Step 3 전체화면 에러 영역과 충돌 가능, 정책 정리 필요)
