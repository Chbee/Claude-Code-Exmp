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

### Step 4: 팀 에이전트 할당 계획 제시

작성된 태스크 목록을 기반으로 Step별 에이전트 배정 계획을 사용자에게 제시:

```
Worker-1 (Sonnet): Step N — [파일 목록]
Worker-2 (Sonnet): Step M — [파일 목록]
Senior (Opus): 각 Worker 설계 리뷰
Leader: 최종 통합 + 빌드 확인
```

**사용자 승인을 받은 후** 에이전트를 실제로 할당합니다.

## 주의사항

- `docs/phase-X.md` 작성 전 반드시 Spec 파일을 읽어 정확한 태스크 파악
- 태스크 누락 없이 Spec-Tasks.md 기준으로 작성
- 완료 기준은 검증 가능한 항목만 포함
