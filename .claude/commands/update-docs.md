# /update-docs

현재 완료된 Phase의 문서를 자동으로 업데이트합니다.

## 수행 작업

1. 현재 git 브랜치에서 Phase를 감지 (예: `phase/a-foundation` → Phase A)
2. 해당 Phase의 `docs/phase-X.md` 완료 기준 `[ ]` → `[x]` 체크
3. `CLAUDE.md` Milestones 테이블 상태 업데이트
4. `specs/Spec-Tasks.md` 완료된 태스크 `[ ]` → `[x]` 체크
5. 변경된 파일을 docs 커밋으로 저장 (선택: 커밋 여부 확인 후)

## 실행 절차

### Step 1: 현재 Phase 감지

현재 git 브랜치를 확인하여 Phase를 파악하세요:
```bash
git branch --show-current
```

브랜치 패턴: `phase/a-foundation` → Phase A, `phase/b-calculator-ui` → Phase B, 등

### Step 2: phase-X.md 완료 기준 확인

`docs/phase-X.md`의 `## 완료 기준` 섹션을 읽고, 각 항목을 현재 코드베이스 상태와 비교하여 충족 여부를 판단하세요.

판단 기준:
- `xcodebuild` 빌드 성공 → `xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator -destination 'generic/platform=iOS Simulator' build` 실행 결과로 확인
- 파일 존재 여부 → Glob으로 확인
- 기능 구현 여부 → 해당 파일 Read 후 확인

완료된 항목은 `[ ]` → `[x]` 로 변경하세요.

### Step 3: specs/Spec-Tasks.md 태스크 체크

`specs/Spec-Tasks.md`를 읽고, 해당 Phase에서 구현된 태스크를 파악하세요.

판단 기준:
- 코드베이스에서 Glob/Grep으로 구현 여부 직접 확인
- 구현된 태스크는 `[ ]` → `[x]` 로 변경

Phase와 태스크 대응:
- Phase A → MS1 1.1.x (계산 로직), 1.2.x (디스플레이), 1.3.x (통화), 1.7.x (상태 구조)
- Phase B → MS1 1.4.x (환율 표시), 1.5.x (방향 전환), 1.6.x (변환 결과), 1.8.x (숨김 버튼)
- Phase C → MS2 전체, MS4 4.3.x (API 테스트)
- Phase D → MS0 전체
- Phase E → MS3 전체, MS4 4.1.x~4.2.x

미완료 항목은 절대 `[x]`로 표시하지 말 것.

### Step 3-보조: Phase별 태스크 판정 기준

코드베이스에서 직접 검증 가능한 대표 커맨드 목록입니다. 아래 패턴을 참고하여 각 서브섹션의 나머지 태스크도 동일한 방식으로 판정하세요.

#### Phase A (MS1: 1.1~1.3, 1.7 / Toast / 전역 상태)

| 태스크 ID | 판정 방법 |
|---|---|
| 1.1.1 | `grep -r "enum Operator" TravelCalculator/Domain/Models/` 결과 존재 |
| 1.1.5 | `grep "lastOperator\|lastOperand" TravelCalculator/Presentation/Calculator/CalculatorReducer.swift` 결과 존재 |
| 1.1.9 | `grep "showAllClear\|isAllClear" TravelCalculator/Presentation/Calculator/` 결과 존재 |
| 1.2.1 | `TravelCalculator/Core/Extensions/Decimal+Format.swift` 파일 존재 + `grep "Locale\|groupingSeparator" ...` 로 로케일 고정 확인 |
| 1.2.3 | `grep "CurrencyAmountDisplayModel" TravelCalculator/Presentation/Calculator/CalculatorDisplayModel.swift` 결과 존재 |
| 1.3.1 | `grep "fractionDigits" TravelCalculator/Domain/Models/Currency.swift` 결과 존재 |
| 1.3.5 | `grep "resetForCurrencyChange" TravelCalculator/Presentation/Calculator/CalculatorReducer.swift` 결과 존재 |
| 1.7.1 | `grep "ExchangeRateStatus" TravelCalculator/Core/App/AppCurrencyStore.swift` 결과 존재 |
| 1.7.2 | `grep "UserDefaults" TravelCalculator/Core/App/AppCurrencyStore.swift` 결과 존재 |

#### Phase B (MS1: 1.4~1.6, 1.8)

| 태스크 ID | 판정 방법 |
|---|---|
| 1.4.1 | `grep "rateDisplay\|= KRW" TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` 결과 존재 |
| 1.4.3 | `grep "isRefreshEnabled\|refreshButton" TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` 결과 존재 |
| 1.5.1 | `grep "directionToggle\|↓\|toggleDirection" TravelCalculator/Presentation/Calculator/CalculatorDisplay.swift` 결과 존재 |
| 1.5.3 | `grep "directionTogglePressed" TravelCalculator/Presentation/Calculator/CalculatorReducer.swift` 결과 존재 |
| 1.6.2 | `grep "computeConvertedAmount\|multiply\|divide" TravelCalculator/Presentation/Calculator/CalculatorDisplayModel.swift` 결과 존재 |
| 1.8.1 | `grep "opacity.*0\|\.opacity(0)" TravelCalculator/Presentation/Calculator/CalculatorToolbar.swift` 결과 존재 |

#### Phase C (MS2: 2.1~2.4 / MS4: 4.3)

| 태스크 ID | 판정 방법 |
|---|---|
| 2.1.1 | `TravelCalculator/Domain/Models/ExchangeRate.swift` 파일 존재 |
| 2.2.1 | `grep "conversionDirection\|multiply\|divide" TravelCalculator/Presentation/Calculator/CalculatorDisplayModel.swift` 결과 존재 |
| 2.4.1 | `TravelCalculator/Data/Network/ExchangeRateAPI.swift` 존재 + `grep "URLSession" ...` 호출 확인 |
| 2.4.2 | `grep "fallback\|searchDate\|Calendar" TravelCalculator/Data/Network/ExchangeRateAPI.swift` 결과 존재 |
| 2.4.5 | `grep "noCacheAvailable\|ExchangeRateErrorView" TravelCalculator/` 결과 존재 |
| 2.4.7 | `grep "invalidRate\|<= 0\|isNaN" TravelCalculator/Data/Network/ExchangeRateAPI.swift` 결과 존재 |
| 4.3.1 | `grep "MockExchangeRateAPI" TravelCalculatorTests/` 결과 존재 |
| 4.3.5 | `grep "deal_bas_r\|쉼표\|replacingOccurrences" TravelCalculatorTests/` 결과 존재 |

### Step 4.5: Spec-Tasks.md ↔ docs/phase-X.md 불일치 경고

`docs/phase-X.md`의 `## 완료 기준` 체크 상태와 `specs/Spec-Tasks.md`의 해당 Phase 태스크 체크 상태를 비교하세요.

판정 방법:
- `docs/phase-X.md` 완료 기준이 모두 `[x]`인데 `Spec-Tasks.md`에 `[ ]`(미완료) 태스크가 남아 있으면 **경고** 출력
- 반대로 `Spec-Tasks.md`가 모두 `[x]`인데 `docs/phase-X.md` 완료 기준에 `[ ]`가 있어도 **경고** 출력
- 불일치 항목을 목록으로 제시하고, 사용자에게 실제 완료 여부를 확인하도록 안내

> 예시 경고 출력:
> ⚠️ 불일치 감지: `docs/phase-b.md` 완료 기준 중 `[ ] xcodebuild 빌드 성공`이 미완료 상태이나,
> `Spec-Tasks.md`의 1.4.x~1.8.x 태스크는 모두 완료로 표시되어 있습니다. 실제 빌드 결과를 확인하세요.

### Step 4: CLAUDE.md 마일스톤 업데이트

`CLAUDE.md`의 `## Milestones` 테이블에서 현재 Phase에 해당하는 마일스톤 상태를 업데이트하세요.

상태 패턴 예시:
- `미착수` → `Phase A(Foundation) 완료 / Phase B(UI) 대기`
- `포팅 중` → `완료`

Phase와 마일스톤 대응:
- Phase A → Milestone 1 (Calculator UI의 Foundation 부분)
- Phase B → Milestone 1 (Calculator UI 완성)
- Phase C → Milestone 2 (Exchange Rate)
- Phase D → Milestone 0 (온보딩)
- Phase E → Milestone 3+4 (Offline + Testing)

### Step 4.6: Phase ↔ Spec Forward 검증 (영향 섹션 누락 점검)

phase 종료 시점에 spec 변경분과 phase 문서 영향 섹션이 일치하는지 양방향으로 검증한다.

#### 4.6.1 Spec 변경분 추출

```bash
git diff --name-only main..HEAD -- 'specs/Spec-*.md'
```

각 변경 파일에 대해 `git diff main..HEAD -- specs/Spec-XXX.md` 의 hunk header(`@@ -a,b +c,d @@`)를 읽고, 각 hunk의 신규 라인 번호 위쪽에서 가장 가까운 `##` / `###` 헤딩을 매칭하여 변경 섹션 목록을 만든다 (`/start-task` Step 6.7 과 동일 알고리즘).

알고리즘 가이드:
- `grep -nE '^(## |### )' specs/Spec-XXX.md` 로 헤딩 목록 + 라인 번호 확보
- diff hunk 의 신규 시작 라인을 헤딩 목록과 비교하여 "그 hunk가 속한 가장 가까운 위 헤딩" 결정
- `## 영향 문서 (Impact)` 같은 메타 섹션이 잡히면 무시

#### 4.6.2 phase 영향 섹션 비교

`docs/phase-X.md` 의 `## 영향 문서 (Impact)` 섹션에서 등록된 spec 링크(`(../specs/Spec-XXX.md#...)`)를 모두 추출한 뒤, 4.6.1 결과와 비교한다:

| 분류 | 조건 | 출력 |
|---|---|---|
| **누락** | git diff 에는 변경 있는데 영향 섹션엔 없음 | ⚠️ 경고 — phase 문서 보완 필요 |
| **Stale** | 영향 섹션엔 있는데 실제 git diff 에는 없음 | ⚠️ 경고 — 의도된 reference-only 인지 확인 |
| **참조만 (변경 없음) bucket** | 영향 섹션 "참조만" bucket 에 등록 | Stale 검증 대상 제외 (참조만 항목은 git diff 에 안 잡혀도 정상) |

> 영향 섹션이 없는 레거시 phase 문서(phase-a~phase-f)는 검증 대상에서 제외. 새 phase 부터 적용.

#### 4.6.3 사용자 확인

경고가 1건 이상이면 작업을 멈추고 사용자에게 처리 옵션을 제시한다 (AskUserQuestion):

- **영향 섹션 보완 후 재실행** — `/update-docs` 중단. 사용자가 phase 문서를 수정하고 다시 호출.
- **의도된 누락으로 통과** — 예: typo / 주석 정비. plan 파일 또는 phase 문서 하단에 "Forward 검증 통과 (의도된 누락: {이유})" 한 줄 기록 후 진행.

`TODO:` 마커가 영향 섹션에 남아 있으면 (즉 `/start-task` Step 6.7 자동 추가 모드의 placeholder 가 미완성) 누락에 준해 경고하고 보완 요구.

### Step 4.7: Spec → Phase 역링크 자동 append (Backward 자동화)

Step 4.6 검증 통과 후 자동 실행. phase 에서 추가/수정한 각 spec 섹션 끝에 역링크 한 줄을 자동 추가한다.

#### 4.7.1 대상 섹션 특정

4.6.1 에서 추출된 spec 변경 섹션 목록 사용 (Forward 검증과 동일 소스).

#### 4.7.2 역링크 라인 형식

```
> **수정 이력**: [Phase X](../docs/phase-X.md)
```

#### 4.7.3 Idempotency 판정

같은 spec 섹션이 여러 phase 에서 수정되면 라인이 누적된다 (각 phase 마다 한 줄). 따라서 단순히 `> **수정 이력**:` 접두사만 검사하면 안 된다 — `[Phase X]` 토큰까지 같이 비교하여 **이번 phase 의 라인이 이미 존재하면 skip**, 다른 phase 라인이 있으면 그 다음 줄에 추가한다.

#### 4.7.4 삽입 위치

해당 섹션의 본문 마지막 라인 다음, 다음 `##` / `###` 헤딩 직전(또는 파일 끝 EOF)의 위치에 삽입한다:

- 섹션 본문 끝이 일반 문단 → 빈 줄 한 줄 추가 후 역링크 라인 삽입
- 섹션 본문 끝이 이미 `>` 블록 인용(예: 다른 phase 의 `> **수정 이력**: [Phase A]`) → 같은 인용 블록에 이어 붙이지 말고, 빈 줄 없이 바로 다음 줄에 같은 `>` 인용으로 추가 (인용 블록 자연스럽게 누적)

#### 4.7.5 적용 결과 보고

- 추가한 라인 수 / 파일별 변경 위치 요약 출력
- skip 한 항목(이미 존재) 별도 카운트
- `git status` 로 변경된 spec 파일 목록을 사용자에게 보여준 뒤 Step 5 (커밋) 으로 진행

> 자동화에 의한 spec 수정이므로 Step 5 커밋에 함께 묶는다. 별도 커밋 권장하지 않음 — 메시지에 "역링크 자동 append 포함" 한 줄 추가.

### Step 5: 커밋 여부 확인

변경된 파일 목록을 보여주고, 커밋할지 사용자에게 확인하세요.

커밋 메시지 형식:
```
docs: Phase X 완료 기준 및 마일스톤 상태 업데이트

- 역링크 자동 append 포함 (Step 4.7)
```

> Step 4.7 이 spec 파일을 수정했다면 메시지 본문에 그 사실을 명시. 영향 섹션 보완 외 다른 변경이 없으면 통상 메시지만 사용.

## 주의사항

- 빌드를 실제로 돌려서 확인하거나, 이미 빌드 성공이 확인된 경우 그 결과를 기준으로 판단
- 미완료 항목은 절대 `[x]`로 표시하지 말 것
- CLAUDE.md 수정 시 기존 포맷 유지
- Step 4.6 Forward 검증에서 경고가 있으면 Step 4.7 Backward 자동화는 보류 (잘못된 spec 에 잘못된 역링크가 박히는 것 방지)
- Step 4.7 의 idempotency 는 `[Phase X]` 토큰 비교가 핵심 — `수정 이력:` 접두사만으로 판정 금지
