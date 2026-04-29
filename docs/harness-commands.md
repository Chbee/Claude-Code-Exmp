# 하네스 — 슬래시 커맨드 + 워크플로우

> 마지막 갱신: 2026-04-29
> 관련: [하네스 개요](harness.md) | [Hooks 상세](harness-hooks.md)

---

## 슬래시 커맨드

### `/start-task` — 태스크 단위 하네스 진입점

```
/start-task [작업 설명]
```

**실행 흐름:**

```
EnterPlanMode
    │
    ├─ Explore 에이전트로 관련 코드 탐색
    ├─ AskUserQuestion (scope / 영향범위 / 엣지케이스 / 재사용)
    ├─ plan 파일 작성
    │   └─ 경로: docs/plans/phase-{브랜치명}/ 또는 docs/plans/adhoc/
    │
    ├─ Codex MCP 검증 (Anti Over-Engineering 체크리스트)
    │   ├─ over-engineering 경고 → 계획 수정 후 재검증
    │   ├─ 아키텍처 충돌 → AskUserQuestion 재진입
    │   └─ Codex 응답 없음(3회 재시도 실패) → 중단 + AskUserQuestion (계속 진행 여부)
    │
ExitPlanMode → 사용자 승인
    │
TDD 개발 (Normal Mode)
    ├─ Red: 실패 테스트 작성 → xcodebuild test 실패 확인
    ├─ Yellow: 최소 구현으로 테스트 통과
    └─ Green: 리팩터링 + 테스트 재확인
```

**plan 파일 구조:**
```
## 작업 설명
## 인터뷰 결과
## 구현 계획
## Codex Review       ← 반영함/무시함: {이유} 명시
## TDD 사이클 로그
```

---

### `/start-phase` — Phase 단위 진입점

```
/start-phase B   # 계산기 UI
/start-phase C   # 환율 API
/start-phase D   # 온보딩
/start-phase E   # 오프라인 + 테스트
```

**실행 흐름:**

```
브랜치 확인 (main인지, uncommitted 없는지)
    │
git checkout -b phase/X-name
    │
Spec 파일 읽기 → docs/phase-X.md 작성
    │
Step 간 파일 교집합 분석
    ├─ 교집합 있음 (직렬 의존) → /start-task 자동 호출
    └─ 교집합 없음 (독립) → 사용자 승인 → Worker 에이전트 병렬 실행
                                              → Senior(Opus) 리뷰어
                                              → Leader 최종 빌드 확인 + 커밋
```

---

### `/update-docs` — Phase 완료 후 문서 동기화

```
현재 브랜치에서 Phase 감지
    │
docs/phase-X.md 완료 기준 [ ] → [x] 체크 (실제 코드 검증 후)
    │
specs/Spec-Tasks.md 태스크 체크
    │
불일치 감지 시 경고 출력
    │
CLAUDE.md Milestones 테이블 업데이트
    │
커밋 여부 확인 후 커밋
```

---

## 전체 워크플로우 흐름도

```
사용자 프롬프트 제출
        │
        ▼
[UserPromptSubmit hook]
pre-prompt-harness-reminder.sh
        │ 구현 키워드 감지 시 ⚠️ 경고 (비차단)
        │
        ▼
/start-phase X    ─────────────────────────────────────────────┐
        │                                                       │
        ▼                                                       │
브랜치 생성 + docs/phase-X.md                                  │
        │                                                       │
        ├─ 직렬 판정 ─→ /start-task 자동 호출                  │
        └─ 병렬 판정 ─→ Worker 에이전트 팀 구성                │
                                                               │
/start-task [작업설명] ◄──────────────────────────────────────┘
        │
        ▼
EnterPlanMode
 (편집 차단 상태)
        │
        ├─ Explore 에이전트 탐색
        ├─ AskUserQuestion 인터뷰
        ├─ plan 파일 기록
        └─ Codex MCP 검증
                │
        ExitPlanMode
                │
        사용자 승인
                │
                ▼
        TDD 개발 시작
                │
        [PreToolUse hook]
        pre-edit-tdd-check.sh
                │
                ├─ Store/Reducer/Models 레이어 편집 시
                │    └─ Tests 파일 없음? → ⛔ exit 2 차단
                │
                ▼
        Red → Yellow → Green 사이클
                │
                ▼
        /update-docs
                │
                ▼
        [Stop hook]
        완료 알림 + 소리
```
