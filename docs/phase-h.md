# Phase H — VoiceOver 접근성 보강 (계산기 키패드 + 환율 영역)

> 브랜치: `phase/h-voiceover-accessibility`
> 목표: Spec-Tasks §9 리뷰 5.1(Medium, 부분 완료)을 종결. 현재 검색바·Toolbar 네트워크 인디케이터·Toast에만 적용된 `accessibilityLabel`/`Hint`/`Action`을 **계산기 키패드 17개 버튼**과 **환율 영역(Display)**·**Toolbar 통화 pill**까지 확장.

---

## 영향 문서 (Impact)

이 Phase가 spec에 미치는 영향. 작업 진행 중 추가/수정 발견 시 누적 갱신.

- **추가/수정한 spec 섹션**:
  - [Spec-UI §3.1 계산기 화면](../specs/Spec-UI.md#31-계산기-화면-메인) — Toolbar/Display 서브섹션에 VoiceOver 라벨 매핑 cross-link 1줄씩 추가 (§6.6 신설 섹션 참조)
  - [Spec-UI §6.6 접근성](../specs/Spec-UI.md#66-접근성) — **신설**. VoiceOver 라벨/힌트 정책 (계산기 키패드 17개 / 환율 영역 refresh·toggle·rate row / Toolbar 통화 pill) + 검증 가능 항목 (grep으로 확인 가능한 accessibility 모디파이어 카운트)
  - [Spec-Tasks §9 리뷰 5.1](../specs/Spec-Tasks.md#9-개선-백로그) — 🟡 부분 → ✅ 완료 (Phase H) 상태 갱신
  - [Spec-Tasks §9 개선 백로그](../specs/Spec-Tasks.md#9-개선-백로그) — Phase H UX V2 백로그 1건 추가: 통화 변경 후 `UIAccessibility.post(.announcement, ...)` 자동 알림 (Step 3 팀 리뷰 UX HIGH-5)
- **참조만 (변경 없음)**:
  - [Spec-UI §3.1 Toolbar 구성 — VoiceOver `accessibilityLabel`](../specs/Spec-UI.md#31-계산기-화면-메인) — 기존 `"온라인"`/`"오프라인"`/비표시 정책 유지 (Phase E에서 정의)
  - [Spec-UI §6.3 햅틱 피드백](../specs/Spec-UI.md#63-햅틱-피드백) — 햅틱은 VoiceOver와 독립 (둘 다 동시 발화 OK), 표 변경 없음

---

## 구현 목표

1. **Calculator 키패드 17개 버튼** 전부에 `accessibilityLabel` 적용 — 기호(`×`/`÷`/`←`/`AC`/`C`/`=`/`.`)는 한국어 음성 라벨로 의미 전달
2. **CalculatorDisplay 환율 영역** — 새로고침·방향 전환 아이콘 버튼에 `accessibilityLabel` + `Hint`, rate row(환율 + 캐시 시각/일자)와 input/result row를 `accessibilityElement(.combine)`으로 묶어 통화코드·금액 일체 발화
3. **CalculatorToolbar 통화 pill** — 국기 + 통화코드 + chevron 컴비를 `accessibilityElement(.combine)` + `accessibilityLabel("통화 선택, …")` + `Hint`로 그룹핑
4. **Spec-UI §6.6 신설** — VoiceOver 라벨 매핑표 + 검증 가능 항목(grep 카운트) 명세
5. **시뮬레이터 VoiceOver 수동 검증** — Light/Dark 1회씩, Accessibility Inspector로 라벨 텍스트 확인

> **테스트 범위**: 본 프로젝트는 ViewInspector 미사용. SwiftUI accessibility 모디파이어는 unit test로 직접 검증이 어렵기에, **spec의 "검증 가능 항목" 블록에서 grep 기반 카운트**(`accessibilityLabel` 17건+, `accessibilityElement(.combine)` 5건+ 등)로 정합성을 보장. 동작 검증은 시뮬레이터 수동.

---

## 자산 매핑 (VoiceOver 라벨 명세)

### Calculator 키패드 (17개 버튼)

| 표시 | accessibilityLabel | 비고 |
|---|---|---|
| `0` ~ `9` | `"0"` ~ `"9"` | 기본 음성과 동일 — 명시 라벨로 일관성 |
| `.` | `"소수점"` | 기호만으로는 음성 모호 |
| `=` | `"같음"` | iOS 한국어 기본 계산기 관용 (Step 1 팀 리뷰 반영) |
| `+` | `"더하기"` | |
| `-` | `"빼기"` | |
| `×` | `"곱하기"` | iOS 기본 계산기 관용 (asterisk 아닌 multiplication sign U+00D7) |
| `÷` | `"나누기"` | division sign U+00F7 |
| `AC` | `"전체 지우기"` | |
| `C` | `"지우기"` | iOS 기본 계산기 비대칭 정합 (Step 1 팀 리뷰 반영) |
| `←` | `"삭제"` | backspace — 단음절 명사로 단축 (Step 1 팀 리뷰 반영) |

> **힌트는 생략** — 키패드는 매우 빈번히 사용되어 hint 발화가 노이즈가 됨. iOS 기본 계산기도 hint 없음.

### CalculatorDisplay 환율 영역

| 요소 | accessibilityLabel | accessibilityHint |
|---|---|---|
| Rate row 텍스트 그룹 (`"1 USD = 1,350 KRW · 최신"` 등) | rate + 일자/캐시 시각 결합 텍스트 (자식 자동 결합, Loading 시 `"환율 갱신 중"` 추가) | (없음 — 정보성 텍스트) |
| 새로고침 ↻ 버튼 | `"새로고침"` | `"환율 정보를 다시 불러옵니다"` |
| 방향 전환 ↕ 버튼 | `"방향 전환"` | `"입력 통화와 결과 통화를 바꿉니다"` |
| Input row | `"입력 통화 USD, 금액 1,234.56"` 형식 (combine, Step 2 팀 리뷰 반영) | (없음) |
| Result row | `"결과 통화 KRW, 금액 1,672,656"` 형식 (combine, Step 2 팀 리뷰 반영) | (없음) |

### CalculatorToolbar 통화 pill

| 요소 | accessibilityLabel | accessibilityHint |
|---|---|---|
| 통화 선택 pill | `"통화 선택, \(currency.currencyName), \(currency.currencyUnit)"` (예: "통화 선택, 미국 달러, USD" — Step 3 팀 리뷰 반영, flag/chevron은 hidden) | `"통화 선택 화면을 엽니다"` (Step 3 팀 리뷰 반영 — state transition 명시) |

---

## 태스크 목록

### Step 1: Calculator 키패드 라벨

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 1.1 | `TravelCalculator/Presentation/Calculator/CalculatorKeypad.swift` | `KeypadButton`에 `accessibilityLabel` 파라미터 추가(default = `label`). 호출 측 17개 버튼 중 기호계(`×` `÷` `+` `-` `←` `AC` `C` `=` `.`)에 한국어 라벨 명시 부여. | Spec-UI §6.6 (신설), 본 doc 자산 매핑 |

### Step 2: CalculatorDisplay 환율 영역

| # | 파일 | 태스크 | Spec 참조 |
|---|------|--------|-----------|
| 2.1 | `TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` | 새로고침 버튼 `accessibilityLabel("새로고침")` + `accessibilityHint("환율 정보를 다시 불러옵니다")`. disabled 시 hint 변경 또는 trait 의존(disabled trait 자동). | Spec-UI §6.6 |
| 2.2 | `TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` | 방향 전환 버튼 `accessibilityLabel("방향 전환")` + `accessibilityHint("입력 통화와 결과 통화를 바꿉니다")`. | Spec-UI §6.6 |
| 2.3 | `TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` | `inputRow`/`resultRow`에 `.accessibilityElement(children: .combine)` + `.accessibilityLabel("입력, \(currencyCode), \(formattedAmount)")` 형식. | Spec-UI §6.6 |
| 2.4 | `TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` | `rateRow` HStack 전체에 `.accessibilityElement(children: .combine)` (Spacer 제외 자연스러운 결합). 새로고침 버튼은 `.accessibilityElement(children: .ignore)` 등 별도 요소로 분리해 두 요소(텍스트 1, 버튼 1)로 보이도록. | Spec-UI §6.6 |

### Step 3: CalculatorToolbar 통화 pill + Spec 반영

| # | 파일 | 태스크 |
|---|------|--------|
| 3.1 | `TravelCalculator/Presentation/Calculator/CalculatorToolbar.swift` | 통화 pill 버튼에 `.accessibilityElement(children: .combine)` + `.accessibilityLabel("통화 선택, \(currency.currencyUnit)")` + `.accessibilityHint("통화를 변경합니다")`. 내부 chevron/flag는 trait 자동 무시되지만 명시적 `.accessibilityHidden(true)` 부여 (Sub-element 노출 방지). |
| 3.2 | `specs/Spec-UI.md` | §6.5 다음 위치에 §6.6 "접근성" 섹션 신설. 본 doc 자산 매핑표를 spec 본문으로 옮기고, "검증 가능 항목" 블록에 grep 기준 명시 (`accessibilityLabel` 출현 횟수, `accessibilityElement(children: .combine)` 위치 5종, `accessibilityHint` 3종). |
| 3.3 | `specs/Spec-UI.md` | §3.1 Toolbar 구성 / Display 영역 끝에 한 줄 cross-link("→ §6.6 접근성 참조") 추가. 본문 동작은 변경 없음. |
| 3.4 | `specs/Spec-Tasks.md` | §9 백로그 표 리뷰 5.1 행: 🟡 부분 → ✅ Phase H 완료, 우측 비고에 "계산기 키패드/환율 영역/Toolbar 통화 pill 적용" 명시. |

### Step 4: 빌드 + 수동 VoiceOver 검증

| # | 태스크 |
|---|--------|
| 4.1 | `xcodebuild ... build` 성공 (warning 0, error 0) — `iPhone 16` 시뮬레이터 |
| 4.2 | `xcodebuild ... test` 성공 — 기존 테스트 회귀 없음 (accessibility 변경은 동작에 영향 없어야 함) |
| 4.3 | 시뮬레이터에서 VoiceOver(또는 Accessibility Inspector) 활성 → 키패드 17개 버튼·새로고침·방향 전환·통화 pill 라벨 음독 확인 (Light/Dark 1회씩) |

---

## 완료 기준

- [ ] `xcodebuild` 빌드 성공 (warning 0, error 0)
- [ ] `xcodebuild test` 성공 (기존 테스트 회귀 0건)
- [ ] `CalculatorKeypad.swift` — 17개 `KeypadButton` 호출 전부에 명시 또는 default 라벨 적용 (기호 9개는 한국어 라벨 명시)
- [ ] `CalculatorDisplay.swift` — `accessibilityLabel("새로고침")` / `accessibilityLabel("방향 전환")` 존재, `inputRow`/`resultRow`에 `accessibilityElement(children: .combine)` 적용
- [ ] `CalculatorToolbar.swift` — 통화 pill 버튼에 `accessibilityElement(children: .combine)` + `accessibilityLabel`(currency.currencyUnit 포함) + `accessibilityHint("통화를 변경합니다")` 적용
- [ ] `specs/Spec-UI.md` §6.6 "접근성" 섹션 신설, "검증 가능 항목" 블록 포함 (grep 카운트 기준 명시)
- [ ] `specs/Spec-UI.md` §3.1 Toolbar/Display 서브섹션에 §6.6 cross-link 1줄씩 추가
- [ ] `specs/Spec-Tasks.md` §9 리뷰 5.1 ✅ 갱신
- [ ] 시뮬레이터 VoiceOver(Light) — 키패드 기호 9개 한국어 라벨 음독 확인
- [ ] 시뮬레이터 VoiceOver(Dark) — Display 새로고침/방향 전환 라벨 + 통화 pill 라벨 음독 확인
- [ ] **영향 문서 섹션의 모든 추가/수정 항목이 spec에 실제로 반영됨**

---

## 파일 구조 (수정 예정)

```
TravelCalculator/Presentation/Calculator/
├── CalculatorKeypad.swift     ← 수정 (KeypadButton에 accessibilityLabel)
├── CalculatorDisplay.swift    ← 수정 (refresh/toggle 라벨 + row combine)
└── CalculatorToolbar.swift    ← 수정 (currency pill combine + 라벨)

specs/
├── Spec-UI.md                  ← 수정 (§6.6 신설, §3.1 cross-link)
└── Spec-Tasks.md               ← 수정 (§9 리뷰 5.1 ✅)
```

---

## 결정 기록

- **VoiceOver only, Dynamic Type 제외**: Spec-Tasks §9 리뷰 5.1은 "VoiceOver accessibilityLabel/Hint 추가"로 한정. Dynamic Type(폰트 크기 사용자 설정)은 Spec-Tasks §9 Phase G UX 백로그(런치 스크린 접근성)와 묶여 있고 별도 호흡이라 본 Phase 범위 밖. SwiftUI는 기본적으로 Dynamic Type을 따르므로 회귀 검증만 추가.
- **키패드에 hint 미부여**: iOS 기본 계산기 동작과 정합. 빈번한 입력에서 hint 발화가 노이즈가 되어 사용성 저하.
- **숫자 0~9 라벨 명시**: SwiftUI Button의 default label은 visible Text를 그대로 읽지만, 명시 부여로 누가 봐도 일관성 있는 spec 기준점이 생기고 향후 표시 글자 변경(예: 다국어)에서 라벨 분리됨.
- **rateRow combine 시 Spacer 분리**: SwiftUI `accessibilityElement(.combine)`은 자식 가시 요소만 결합하므로 Spacer는 자동 무시. 새로고침 버튼은 이미 별도 Button — 결합되지 않음. 단, label 결합 순서가 코드 순서를 따르므로 Text 노출 순서를 그대로 유지.

---

## 다음 Phase

V1+ 릴리스 준비 잔여:
- AppIcon Tinted PNG grayscale L* 채널 재export (Phase G 백로그, High, V1+ TestFlight 전 게이트) — 디자이너 자산 트랙
- App Store Connect 미리보기 4종 + 메타데이터 업로드 — 외부 트랙 (코드 0건)
- Phase F V2 후보 가드 테스트 3건 (정수 통화 소수점 거부 / VND 7자리 폭 회귀 / EUR 부동소수 통합) — Low~Medium
