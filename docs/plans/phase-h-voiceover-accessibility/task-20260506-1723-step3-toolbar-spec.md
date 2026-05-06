# Phase H Step 3 — Toolbar 통화 pill VoiceOver + Spec-UI §6.6 신설 + Spec-Tasks §9 갱신

## 작업 설명

Phase H Step 3 — Phase H의 마지막 코드 + spec 작업. Step 1·2의 a11y 적용을 spec에 단일 출처(SoT)로 명시 + 미적용 영역(Toolbar 통화 pill)에도 적용 + Spec-Tasks §9 리뷰 5.1 ✅.

**범위**: 3개 파일.
1. `TravelCalculator/Presentation/Calculator/CalculatorToolbar.swift` — 통화 pill 버튼 a11y
2. `specs/Spec-UI.md` — §6.6 "접근성" 신설 + §3.1 Toolbar/Display cross-link
3. `specs/Spec-Tasks.md` — §9 리뷰 5.1 🟡 → ✅

본 task가 Phase H에서 **유일한 spec 변경 발생 task** — Step 6.7 영향 섹션 누적 갱신이 의미 있는 시점. phase-h.md "영향 문서 (Impact)"가 이미 §6.6 신설 / §3.1 cross-link / Spec-Tasks §9 갱신을 명시 → 본 task가 그 계획대로 진행되면 누락 0건.

---

## 인터뷰 결과

- **§6.6 자산 매핑 범위**: networkIndicator(Phase E 적용, §3.1 명시) 포함 — 화면 전체 a11y SoT 완성.
- **TDD/Codex/테스트 생략**: Step 1/2와 동일 — 단순 모디파이어 + spec 본문 작성.
- **chevron/flag `accessibilityHidden`**: phase-h.md 권고 그대로 명시 부여 (`.combine`이 sub-element를 무시하지만 안전 + spec 정합).
- **`currency.currencyUnit` 발화**: ISO 코드(USD/KRW) 발화 — countryName 사용은 본 Step 범위 외, 팀 리뷰에서 결정.

---

## 구현 계획

### CalculatorToolbar.swift — 통화 pill (line 13~29)

`Button` 호출 후미에 `.accessibilityElement(children: .combine)` + `.accessibilityLabel("통화 선택, \(currency.currencyUnit)")` + `.accessibilityHint("통화를 변경합니다")`. 내부 `Text(currency.flag)` 와 `Image(systemName: "chevron.down")` 에 `.accessibilityHidden(true)`. 기존 networkIndicator(Phase E)는 변경 없음.

### Spec-UI.md — §6.6 신설 (§6.5 끝 line 239 이후)

`### 6.6 접근성 (VoiceOver)` 섹션. 본문:
- 정책 원칙 4개 (인터랙티브 라벨 의무 / hint 부여 기준 / 시각 구분자 hidden / 라벨 톤)
- §6.6.1 키패드 자산 매핑 (17개)
- §6.6.2 환율 영역 자산 매핑 (5종)
- §6.6.3 Toolbar 자산 매핑 (통화 pill + networkIndicator 3 상태)
- 검증 가능 항목 (`CalculatorKeypad.swift` / `CalculatorDisplay.swift` / `CalculatorToolbar.swift` 각 파일별 grep 카운트 기준)
- 수정 이력 [Phase H]

§3.1 Toolbar 구성 끝(line 39 다음) + Display 영역 끝(line 46 다음)에 cross-link 1줄씩 추가.

### Spec-Tasks.md — §9 리뷰 5.1 (line 170)

`🟡 부분 ...` → `✅ Phase H (계산기 키패드 + 환율 영역 + Toolbar 통화 pill — Spec-UI §6.6)`.

---

## Codex Review

생략. 단순 모디파이어 + spec 본문 작성, 알고리즘/아키텍처 결정 0건.

over-engineering 자가 점검:
- [x] 1회성 추상화 없음 / 헬퍼 추가 없음 / 요청 범위 밖 기능 없음 (countryName 발화는 팀 리뷰 위임)
- [x] MVI 무관 / @MainActor 준수 / Decimal 무관

---

## TDD 사이클 로그

테스트 생략. 직접 수정 + 빌드 + 회귀 테스트.

---

## 팀 검증 반영

### Simplify (LOW)
- `+` 표기 모호성 → MEDIUM(Convention M2)와 합의로 정확 카운트 변경

### Convention HIGH 적용
- **H1**: `Spec-UI.md` §6.6 끝에 `> **갱신 컨벤션**:` 줄 추가 (§6.4/§6.5 일관성)

### Convention MEDIUM 적용
- **M1 (`accessibilityLabel:` 호출 측 표기 명시)**: keypad 검증 항목 `"호출 측 17건"` → `"KeypadButton init 파라미터 사이트, 17건"`
- **M2 (`+` 표기 정확화 + Simplify L 합의)**: `5건+`/`3건+` → 정확 카운트(`5건`/`3건`)

### UX HIGH 적용
- **H1 (currencyName 도입)**: `CalculatorToolbar.swift:33` label `"통화 선택, \(currency.currencyName), \(currency.currencyUnit)"` (예: "통화 선택, 미국 달러, USD") + Spec-UI §6.6.3 표 갱신. 근거: Currency 모델에 `currencyName` 이미 존재("미국 달러" 등), VoiceOver "유에스디" 음역 모호 해소 + Apple Wallet 정합

### UX MEDIUM 적용
- **M2 (hint state transition)**: `:34` hint `"통화를 변경합니다"` → `"통화 선택 화면을 엽니다"` (모달 전환 정확 표현)
- **M4 (정책 원칙 4 구체화)**: §6.6 정책 원칙 4 라벨 톤을 (a) 액션 / (b) 토글·상태 / (c) 연산자 / (d) hint 4분류 가이드라인으로 확장

### UX HIGH 보류 → V2 백로그 등록
- **H5 (통화 변경 후 announcement)**: `UIAccessibility.post(.announcement, ...)` 자동 알림. Spec-Tasks §9에 "Phase H UX | Medium | ⬜ V2 후보" 등록.

### 회귀 검증
- `xcodebuild build`: ** BUILD SUCCEEDED **
- `xcodebuild test`: ** TEST SUCCEEDED **

---

## 검증

### grep 자가 검증
```bash
grep -nE "accessibilityLabel|accessibilityHint|accessibilityElement|accessibilityHidden" \
  TravelCalculator/Presentation/Calculator/CalculatorToolbar.swift
# 기대: 통화 pill 4건 + flag/chevron hidden 2건 + 기존 networkIndicator 5건 = 11건+

grep -n "^### 6\.6 접근성" specs/Spec-UI.md       # 1건
grep -n "리뷰 5\.1.*✅ Phase H" specs/Spec-Tasks.md  # 1건
```

### 빌드 + 테스트 회귀
```bash
xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator \
  -destination 'platform=iOS Simulator,id=7BA2C38E-D232-4692-851C-64737AEBDA37' build
xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator \
  -destination 'platform=iOS Simulator,id=7BA2C38E-D232-4692-851C-64737AEBDA37' test
```

### 시뮬레이터 VoiceOver (Step 4 일괄)
- 통화 pill: "통화 선택, USD, 버튼" + hint "통화를 변경합니다"
- flag(🇺🇸) / chevron sub-element 발화 안 됨 확인
- networkIndicator: "온라인"/"오프라인" 회귀 없음
