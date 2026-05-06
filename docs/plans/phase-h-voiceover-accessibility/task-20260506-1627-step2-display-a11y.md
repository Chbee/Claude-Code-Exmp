# Phase H Step 2 — CalculatorDisplay 환율 영역 VoiceOver 보강

## 작업 설명

Phase H Step 2 — `TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` 단일 파일에 VoiceOver 라벨/힌트/combine 적용.

phase-h.md Step 2의 4개 작업:
- 2.1 새로고침 버튼 — label `"새로고침"` + hint `"환율 정보를 다시 불러옵니다"`
- 2.2 방향 전환 버튼 — label `"방향 전환"` + hint `"입력 통화와 결과 통화를 바꿉니다"`
- 2.3 inputRow / resultRow — `accessibilityElement(.combine)` + `accessibilityLabel("입력, USD, 1,234.56")` 형식
- 2.4 rateRow — 텍스트 그룹 combine, refresh 버튼은 별도 element 유지

Step 1과 동일 정책: 테스트 생략, grep 자가 검증 + 시뮬레이터 수동.

---

## 인터뷰 결과

- **Loading 발화**: ProgressView에 명시 라벨 `"환율 불러오는 중"` 부여 (시각장애 사용자에게 stale 상태 명시 전달). `Text("·")` 시각 구분자는 `accessibilityHidden(true)` — "점"으로 발화되는 것 방지.
- **Hint 부여**: phase-h.md 그대로. Refresh + Toggle 둘 다 hint. 키패드는 빈번 입력이라 hint 노이즈, 환율 영역은 1일 1~2회 탭이라 hint 도움.
- **TDD**: 생략 (Step 1과 동일).
- **Codex Review**: 생략 (Step 1과 동일 — 단순 모디파이어 추가, 알고리즘/아키텍처 결정 0건).

---

## 구현 계획

### 변경 파일
- `TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` — 단일 파일

### 변경 내용

#### 1. Refresh 버튼 (line 53~59)
```swift
Button(action: onRefresh) {
    Image(systemName: "arrow.clockwise") ...
}
.disabled(isLoading)
.buttonStyle(.plain)
.accessibilityLabel("새로고침")              // 신규
.accessibilityHint("환율 정보를 다시 불러옵니다")  // 신규
```
- `disabled` trait는 SwiftUI 자동 — VoiceOver가 "흐려짐" 또는 "비활성화됨" 자동 발화. 별도 처리 불필요.

#### 2. Toggle 버튼 (line 101~108)
```swift
Button(action: onToggleDirection) {
    Image(systemName: "arrow.up.arrow.down") ...
}
.buttonStyle(.plain)
.accessibilityLabel("방향 전환")               // 신규
.accessibilityHint("입력 통화와 결과 통화를 바꿉니다")  // 신규
```

#### 3. inputRow (line 79~94)
```swift
private var inputRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(displayModel.inputDisplay.currencyCode) ...
        Spacer()
        Text(displayModel.inputDisplay.formattedAmount) ...
    }
    .frame(height: 56)
    .accessibilityElement(children: .combine)                                                          // 신규
    .accessibilityLabel("입력, \(displayModel.inputDisplay.currencyCode), \(displayModel.inputDisplay.formattedAmount)")  // 신규
}
```
- combine 부여 시 두 Text 자동 결합되지만 "입력," 라벨 prefix가 의미 부여 — 명시 라벨로 override.
- 콤마(`,`)는 VoiceOver 짧은 호흡 처리 — 자연스러운 끊어 읽기.

#### 4. resultRow (line 117~132)
```swift
private var resultRow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(displayModel.resultDisplay.currencyCode) ...
        Spacer()
        Text(displayModel.resultDisplay.formattedAmount) ...
    }
    .frame(height: 56)
    .accessibilityElement(children: .combine)                                                            // 신규
    .accessibilityLabel("결과, \(displayModel.resultDisplay.currencyCode), \(displayModel.resultDisplay.formattedAmount)")  // 신규
}
```

#### 5. rateRow (line 28~61) — 가장 복잡
현재 구조:
```swift
HStack(spacing: 6) {
    Text(rateDisplay)          // "1 USD = 1,350 KRW"
    [조건부 ProgressView | "·" + 캐시 텍스트 | "·" + 일자 텍스트]
    Spacer()
    Button(refresh) { ... }
}
```

목표 ax tree:
- Element 1: 텍스트 그룹(rate + status) — combine으로 결합 발화
- Element 2: Refresh 버튼 — 별도 (이미 위 #1에서 라벨 부여)

구현:
```swift
private var rateRow: some View {
    HStack(spacing: 6) {
        // 텍스트 그룹 (분리된 inner HStack으로 묶어 combine)
        HStack(spacing: 6) {
            Text(displayModel.rateDisplay) ...
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(Color.appTextSub)
                    .accessibilityLabel("환율 불러오는 중")  // 신규
            } else if isOffline, let cachedAt {
                Text("·") ...
                    .accessibilityHidden(true)              // 신규 — 시각 구분자
                Text(Self.relativeLabel(from: cachedAt)) ...
            } else if let days = daysSinceSearchDate {
                Text("·") ...
                    .accessibilityHidden(true)              // 신규 — 시각 구분자
                Text(Self.dateLabel(for: days)) ...
            }
        }
        .accessibilityElement(children: .combine)            // 신규
        // Spacer / Button은 outer HStack — combine 영향 안 받음
        Spacer()
        Button(action: onRefresh) {
            Image(systemName: "arrow.clockwise") ...
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
        .accessibilityLabel("새로고침")
        .accessibilityHint("환율 정보를 다시 불러옵니다")
    }
}
```

핵심 trick: 텍스트 그룹을 별도 inner HStack으로 묶어야 outer HStack의 Spacer/Button과 분리되어 ax tree에 두 요소(텍스트 1, 버튼 1)로 노출.

발화 결과:
- 일반(online, 최신): `"1 USD = 1,350 KRW 최신"` (자동 결합)
- 일반(N일 전): `"1 USD = 1,350 KRW 2일 전"`
- Loading: `"1 USD = 1,350 KRW 환율 불러오는 중"`
- Offline: `"1 USD = 1,350 KRW 5분 전"` (warning 색은 시각만, 발화 텍스트 동일)

> **결정**: rateRow 자체는 명시 accessibilityLabel을 **부여하지 않는다**. 자식 Text들의 자동 결합으로 충분하고, 명시 라벨은 dynamic state(isLoading/isOffline/days) 분기를 위해 별도 computed property가 필요해 over-engineering. inputRow/resultRow는 `"입력,"` `"결과,"` 같은 의미 prefix 부여 가치가 있어 명시 라벨, rateRow는 prefix 없이 자연스러운 결합이 더 정보 풍부.

### 변경하지 않는 것
- `dateLabel(for:)`, `relativeLabel(from:)` 헬퍼 — 텍스트만 반환, 발화 그대로 사용
- Color/foregroundStyle — 시각 정책, accessibility 무관
- Preview — 영향 없음

---

## Codex Review

생략. 본 task는 단순 SwiftUI 모디파이어 추가 + 텍스트 라벨 부여. 알고리즘/아키텍처 변경 0건. Step 1과 동일 사유 — Codex 세컨드 오피니언 가치 낮음.

over-engineering 자가 점검:
- [x] 1회성 추상화 없음 (computed property 추가 0건)
- [x] 헬퍼 함수 추가 없음
- [x] 요청 범위 밖 기능 없음 (rateRow 명시 라벨 의도적 회피 — over-engineering 차단)
- [x] MVI 무관 (View 모디파이어만)
- [x] @MainActor 준수 (View body 내부)
- [x] Decimal 무관

---

## TDD 사이클 로그

테스트 생략. 직접 수정 + 빌드 + 회귀 테스트.

---

## 팀 검증 반영

### Simplify (통과)
헬퍼 추출은 DRY 임계(3회) 미달, 인라인 유지. 적용 가치 항목 없음.

### HIGH 적용
- `:103` inputRow: `"입력, ..."` → `"입력 통화 \(currencyCode), 금액 \(formattedAmount)"` (Convention M1 + UX HIGH-1 합의 — 의미 prefix 강화 + Step 3 toolbar pill 어휘 일관)
- `:145` resultRow: `"결과, ..."` → `"결과 통화 \(currencyCode), 금액 \(formattedAmount)"` (동일 사유)

### MEDIUM 적용
- `:38` ProgressView: `"환율 불러오는 중"` → `"환율 갱신 중"` (Convention L1 + UX M-1 합의 — 톤 일관 + 1음절 단축)

### HIGH 보류 (Step 4 검증 후 결정)
- **UX HIGH-2 rateRow 명시 라벨** — combine 자동 결합 시 `=` 발화가 어색할 수 있다는 추측. 적용하려면 `CalculatorDisplayModel`에 `base/rate/quote/freshness` 분해 필드 추가 필요 → over-engineering 위험. Step 4 시뮬레이터에서 실제 발화 청취 후 결정.

### MEDIUM 보류 (별도 검토)
- **UX M-2 rate=nil 엣지** — `currentRate == nil` 시 라벨이 `"결과 통화 KRW, 금액 0"`으로 발화될 가능성. `displayModel.rateDisplay`/`resultDisplay.formattedAmount`의 nil 분기 동작은 Step 2 범위 외(`CalculatorDisplayModel` 영역). Step 4 검증에서 실제 발화 확인 후 별도 task로 분리할지 결정.

### LOW 백로그
- UX L-1 Toggle hint 단축(`"입력 통화와 결과 통화를 바꿉니다"` → `"입력과 결과 통화를 바꿉니다"`) — 미적용, V2 후보 아님(자연스러운 한국어 둘 다 OK).
- Convention L3 — Step 3 toolbar pill에서 같은 보간 패턴(`prefix \(value)`) 유지 필요성 메모.
- UX V2 백로그 — `accessibilityAddTraits(.updatesFrequently)`, `AccessibilityNotification.Announcement` 검토(통화 변경/오프라인 전환 시 자동 안내). Spec-Tasks §9 백로그 후보.

`docs/phase-h.md` 자산 매핑 표 동일 갱신.

### 회귀 검증
- `xcodebuild build`: ** BUILD SUCCEEDED **
- `xcodebuild test`: ** TEST SUCCEEDED **

---

## 검증

### grep 자가 검증
```bash
grep -nE "accessibilityLabel|accessibilityHint|accessibilityElement|accessibilityHidden" \
  TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift
```
기대 출력 (line 번호는 반영 후 변동):
- `accessibilityLabel("새로고침")` — 1건
- `accessibilityHint("환율 정보를 다시 불러옵니다")` — 1건
- `accessibilityLabel("방향 전환")` — 1건
- `accessibilityHint("입력 통화와 결과 통화를 바꿉니다")` — 1건
- `accessibilityElement(children: .combine)` — 3건 (rateRow 텍스트 그룹 / inputRow / resultRow)
- `accessibilityLabel("입력, ...")` — 1건
- `accessibilityLabel("결과, ...")` — 1건
- `accessibilityLabel("환율 불러오는 중")` — 1건
- `accessibilityHidden(true)` — 2건 (Text("·") × 2)

총 12건 이상.

### 빌드 + 테스트 회귀
```bash
xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator \
  -destination 'platform=iOS Simulator,id=7BA2C38E-D232-4692-851C-64737AEBDA37' build
xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator \
  -destination 'platform=iOS Simulator,id=7BA2C38E-D232-4692-851C-64737AEBDA37' test
```

### 시뮬레이터 VoiceOver 수동 (Step 4에서 일괄)
- 새로고침 버튼 발화: "새로고침, 버튼" + 짧은 지연 후 "환율 정보를 다시 불러옵니다" (hint)
- 방향 전환 버튼: "방향 전환, 버튼" + hint
- inputRow swipe: "입력, USD, 1,234.56" — 콤마에서 짧게 끊어 읽기
- rateRow swipe: 일반 시 "1 USD = 1,350 KRW 최신", loading 시 "환율 불러오는 중" 추가, offline 시 "5분 전" 추가
- 새로고침 disabled 시: "새로고침, 흐려짐, 버튼" 또는 "비활성화됨" — 시스템 자동 trait
