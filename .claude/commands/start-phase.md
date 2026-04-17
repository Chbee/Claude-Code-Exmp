# /start-phase

새 Phase 작업을 시작합니다. 브랜치 생성 → 문서 작성 → 팀 에이전트 할당까지 진행합니다.

## 사용법

```
/start-phase B
/start-phase C
```

## 수행 작업

1. **브랜치 생성**: `git checkout -b phase/X-name`
2. **`docs/phase-X.md` 작성**: 태스크 목록 + 구현 목표 + 완료 기준
3. **팀 에이전트 할당**: Step별 Worker(Sonnet) 배정, Senior(Opus) 리뷰어 지정

---

## 실행 절차

### Step 1: Phase 확인

args에서 Phase 문자를 읽습니다 (예: `B`, `C`, `D`, `E`).

Phase별 브랜치명 및 설명:
- B → `phase/b-calculator-ui` — 계산기 UI (CalculatorView, Keypad, Display, Toolbar) + 통화 선택 UI
- C → `phase/c-exchange-rate` — 환율 API 연동 (한국수출입은행 API)
- D → `phase/d-onboarding` — 온보딩 화면
- E → `phase/e-offline-tests` — 오프라인 대응 + 테스트

현재 브랜치가 `main`인지 확인:
```bash
git branch --show-current
git status
```

`main`이 아니거나 uncommitted 변경사항이 있으면 사용자에게 알리고 중단.

### Step 2: 브랜치 생성

```bash
git checkout -b phase/X-name
```

### Step 3: docs/phase-X.md 작성

`specs/` 디렉토리의 관련 Spec 파일을 읽어 해당 Phase의 태스크를 파악:
- `specs/Spec-Tasks.md` — 마일스톤별 전체 태스크 목록
- `specs/Spec-Overview.md` — 기능 명세
- `specs/Spec-Architecture.md` — 아키텍처
- `specs/Spec-DataModel.md` — 데이터 모델
- `specs/Spec-UI.md` — UI 설계 (Phase B, D)

`docs/phase-a.md` 형식을 참고하여 작성:
```markdown
# Phase X — [제목]

> 브랜치: `phase/x-name`
> 목표: [한 줄 요약]

## 구현 목표
[번호 목록]

## 태스크 목록
### Step N: [단계명]
| # | 파일 | 태스크 | Spec 참조 |

## 완료 기준
- [ ] xcodebuild 빌드 성공 (warning 0, error 0)
- [ ] [기능별 확인 항목]

## 파일 구조 (생성/수정 예정)
[트리 구조]

## 다음 Phase
[다음 Phase 한 줄 설명]
```

### Step 4-A: 병렬화 가능성 판정

방금 작성한 `docs/phase-X.md`의 태스크 표에서 각 Step의 수정 파일 목록을 추출하고, Step 간 파일 교집합을 검사합니다.

**판정 기준:**
- Step 간 교집합이 있거나 순차 의존성이 있으면 → **직렬 실행 권장**
  - "직렬 실행 권장 — 단일 Task 에이전트로 Step을 순차 수행합니다. Step 4-B를 건너뜁니다."
  - 여기서 멈추고 사용자에게 결론을 보고합니다.
- Step 간 교집합이 없고 독립적이면 → **병렬 실행 가능**
  - "병렬 실행 가능 — Step별 Worker 에이전트를 동시 실행합니다. Step 4-B로 진행합니다."

### Step 4-B: 팀 구성 (병렬 가능한 경우만)

**Step 4-B 진입 전 사용자 승인을 받습니다.** 승인 후에는 자동 실행합니다.

Agent 도구를 사용하여 에이전트를 병렬 호출합니다:

1. **Worker 에이전트 병렬 실행**: 한 메시지 안에서 Step 개수만큼 Agent tool call을 동시에 발행합니다.
   - 각 Worker에게 전달할 내용:
     - 담당 Step의 파일 목록
     - 해당 Spec 파일 경로 및 참조 섹션
     - TDD 지침: Red(실패 테스트 작성) → Yellow(최소 구현) → Green(리팩터링)
     - 빌드 성공(warning 0, error 0) 기준 준수
   - 예시 (Step이 2개인 경우): Agent("Worker-1: Step N 구현 — 파일: A, B …"), Agent("Worker-2: Step M 구현 — 파일: C, D …") 를 동시에 호출

2. **모든 Worker 완료 후** Opus Senior 리뷰어 에이전트를 순차 호출합니다.
   - Senior에게 전달: 각 Worker가 작성한 파일 전체, 통합 코드 일관성 검토 요청

3. **Leader(호출한 Claude 본인)가** 최종 빌드 확인 후 커밋합니다:
   ```bash
   xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator \
     -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

## 주의사항

- `docs/phase-X.md` 작성 전 반드시 Spec 파일을 읽어 정확한 태스크 파악
- 태스크 누락 없이 Spec-Tasks.md 기준으로 작성
- 완료 기준은 검증 가능한 항목만 포함
