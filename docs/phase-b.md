# Phase B — Calculator UI (계산기 UI + 통화 선택)

> 브랜치: `phase/b-calculator-ui`
> 목표: Phase A 기반 위에 계산기 화면 전체 UI 구현. 키패드, 디스플레이, 통화 선택, 방향 전환, 환율 표시(mock).

---

## 구현 목표

1. CalculatorView 메인 화면 조립 (Toolbar + Display + Keypad)
2. CalculatorKeypad — 키패드 그리드 UI
3. CalculatorDisplay — 입력/결과 표시, 환율 행, 방향 전환 버튼
4. CalculatorToolbar — 통화 pill 버튼, 상태 dot, 숨김 버튼
5. CurrencySelect MVI 모듈 — 통화 선택 모달 (fullScreenCover)
6. CalculatorStore 확장 — currencyStore 연동, mock 환율, 방향 전환, 음수 Toast
7. CalculatorDisplayModel 수정 — 양방향 환산 (multiply/divide)
8. Haptic 유틸리티 — Toast 외 햅틱 피드백

---

## 태스크 목록

### Step 1: Store 확장 + Haptic + DisplayModel 수정

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `Core/Haptic.swift` | `@MainActor enum Haptic` — impact/notification 정적 메서드 | Spec-UI §3.4 |
| 1.2 | `Presentation/Calculator/CalculatorIntent.swift` | `directionTogglePressed(String)` 케이스 추가 | 1.5.2 |
| 1.3 | `Presentation/Calculator/CalculatorReducer.swift` | `directionTogglePressed` 처리: display=전달값, calc 상태 리셋 | 1.5.2~1.5.3 |
| 1.4 | `Presentation/Calculator/CalculatorStore.swift` | init에 `currencyStore: AppCurrencyStore` 추가 | Spec-Architecture §4.2 |
| 1.5 | 〃 | `displayModel` computed property (mock 환율) | Spec-DataModel §5.5 |
| 1.6 | 〃 | `toggleDirection()` — Reducer 경유 + currencyStore 토글 + haptic | 1.5.2~1.5.4 |
| 1.7 | 〃 | `send(.equalsPressed)` 후 light impact haptic | Spec-UI §3.4 |
| 1.8 | 〃 | 음수 Toast: send 후처리에서 display 음수 전이 감지 → 1회 발생 | 1.6.5 |
| 1.9 | 〃 | 통화 변경 감지 → `send(.resetForCurrencyChange)` | 1.3.5 |
| 1.10 | 〃 | mock 환율 헬퍼: USD=1350, TWD=45 | — |
| 1.11 | `Presentation/Calculator/CalculatorDisplayModel.swift` | `computeConvertedAmount`에 방향 분기 (multiply/divide) | 1.6.2 |
| 1.12 | 〃 | `make()` 팩토리에 방향 정보 반영 | 1.6.2 |

### Step 2: CalculatorKeypad

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `Presentation/Calculator/CalculatorKeypad.swift` | 키패드 그리드 레이아웃 (AC/C, ←, ÷, 숫자, 연산자, 0(wide), ., =) | Spec-UI §2.2 |

### Step 3: CalculatorDisplay + CalculatorToolbar

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 3.1 | `Presentation/Calculator/CalculatorDisplay.swift` | 환율 행 (rateDisplay + 업데이트 시간 + ↻ 버튼) | 1.4.1~1.4.4 |
| 3.2 | 〃 | 입력 표시 (CurrencyCode + amount, minimumScaleFactor 폰트 축소) | 1.2.2 |
| 3.3 | 〃 | 방향 전환 ↓ 버튼 (원형, appPrimary) | 1.5.1 |
| 3.4 | 〃 | 결과 표시 (CurrencyCode + amount, 폰트 축소, 통화별 소수점) | 1.6.1~1.6.4 |
| 3.5 | `Presentation/Calculator/CalculatorToolbar.swift` | 통화 pill 버튼 (flag + code + chevron.down) | 1.3.2 |
| 3.6 | 〃 | 카메라/설정 버튼 opacity=0 숨김 | 1.8.1 |
| 3.7 | 〃 | 온라인 상태 dot | — |

### Step 4: CurrencySelect MVI + View

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 4.1 | `Presentation/CurrencySelect/CurrencySelectState.swift` | 통화 목록, 선택 상태, shouldDismiss | 1.3.3 |
| 4.2 | `Presentation/CurrencySelect/CurrencySelectIntent.swift` | selectCurrency, dismiss | 1.3.4 |
| 4.3 | `Presentation/CurrencySelect/CurrencySelectStore.swift` | currencyStore 업데이트, success haptic/toast, dismiss 시그널 | 1.3.4, 1.3.5 |
| 4.4 | `Presentation/CurrencySelect/CurrencySelectView.swift` | fullScreenCover 모달, 제목/부제목, 통화 리스트, 체크마크, X 닫기 | 1.3.2 |

### Step 5: CalculatorView 조립 + ContentView 연결

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 5.1 | `Presentation/Calculator/CalculatorView.swift` | 메인 화면 조립: VStack(Toolbar + Display + Keypad) | Spec-UI §2.1 |
| 5.2 | 〃 | fullScreenCover for CurrencySelectView | 1.3.2 |
| 5.3 | `ContentView.swift` | placeholder → CalculatorView 교체 | — |
| 5.4 | `TravelCalculatorApp.swift` | 필요시 의존성 전달 조정 | — |

---

## 완료 기준

- [ ] `xcodebuild` 빌드 성공 (warning 0, error 0)
- [ ] 계산기 키패드: 모든 버튼 탭 → 올바른 Intent 전달
- [ ] 디스플레이: 천단위 콤마, 입력/결과 모두 긴 숫자 폰트 축소
- [ ] AC/C 토글: `showAllClear` computed property 기반 텍스트 전환
- [ ] 통화 선택: pill 버튼 탭 → 모달 → 통화 선택 → Store 내부 감지 → 리셋
- [ ] 방향 전환: ↓ 버튼 → Reducer 통해 결과값 이전 + 방향 스왑
- [ ] 양방향 환율: selectedToKRW=multiply, krwToSelected=divide
- [ ] 환율 표시: "1 USD = 1,350.00 KRW" + 업데이트 시간 + ↻ 버튼(disabled)
- [ ] 변환 결과: 실시간 변환, 통화별 소수점 차등
- [ ] 음수 변환 Toast: display 음수 전이 시점 1회 발생
- [ ] 햅틱: =, 방향 전환, 통화 선택 시 피드백
- [ ] 카메라/설정 버튼: opacity=0 숨김 + 레이아웃 유지

---

## 파일 구조 (생성/수정 예정)

```
TravelCalculator/
├── Core/
│   └── Haptic.swift                              ← NEW
├── Presentation/
│   ├── Calculator/
│   │   ├── CalculatorView.swift                  ← NEW
│   │   ├── CalculatorKeypad.swift                ← NEW
│   │   ├── CalculatorDisplay.swift               ← NEW
│   │   ├── CalculatorToolbar.swift               ← NEW
│   │   ├── CalculatorStore.swift                 ← MOD
│   │   ├── CalculatorIntent.swift                ← MOD
│   │   ├── CalculatorReducer.swift               ← MOD
│   │   ├── CalculatorDisplayModel.swift          ← MOD
│   │   └── CalculatorState.swift                 (변경 없음)
│   └── CurrencySelect/
│       ├── CurrencySelectState.swift             ← NEW
│       ├── CurrencySelectIntent.swift            ← NEW
│       ├── CurrencySelectStore.swift             ← NEW
│       └── CurrencySelectView.swift              ← NEW
├── ContentView.swift                              ← MOD
└── TravelCalculatorApp.swift                      ← MOD (필요시)
```

---

## 미수정 이슈 (Phase B-2 테스트 피드백, 2026-04-09)

| # | 이슈 | 수정 대상 | 상세 |
|---|------|----------|------|
| 1 | 10자 초과 Toast 1회만 표시 | CalculatorReducer.swift | `isInputLimitExceeded` 플래그가 true 고정 → 이후 Toast 차단. 매번 피드백 표시 필요 |
| 2 | 입력 Display 높이 축소 | CalculatorDisplay.swift | 16 Pro, USD→KRW 기준 6자 초과 시 `minimumScaleFactor`로 행 높이도 축소됨. `.frame(height:)` 고정 필요 |
| 3 | 0 버튼 너비 복원 | CalculatorKeypad.swift | '0'의 leading='1' leading, trailing='2' trailing → double-width(`buttonWidth * 2 + spacing`). 현재 3등분으로 잘못 수정됨 |
| 4 | 키패드 Color Figma 불일치 | CalculatorKeypad.swift | utility 버튼(AC, C, ←)이 `appAccent`(노란색). Figma 컴포넌트(node 397:230) 기준으로 수정 필요 |

---

## 다음 Phase

Phase C (`phase/c-exchange-rate`): 한국수출입은행 API 연동 — mock 환율을 실제 API로 교체, searchdate 기반 새로고침 활성화
