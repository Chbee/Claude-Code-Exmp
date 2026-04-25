# 하네스 엔지니어링 구성 문서

> 마지막 갱신: 2026-04-23

---

## 전체 구성 지도

```
[글로벌]  ~/.claude/settings.json
              └─ 모델 / 환경변수 / 플러그인 / effortLevel

[프로젝트] .claude/settings.local.json   ← git ignored
              ├─ permissions.allow (자동 승인 목록)
              └─ hooks
                   ├─ UserPromptSubmit → pre-prompt-harness-reminder.sh
                   ├─ PreToolUse(Edit|Write) → pre-edit-tdd-check.sh
                   └─ Stop → 완료 알림 (osascript + 소리)

[슬래시 커맨드] .claude/commands/
              ├─ start-task.md   — 태스크 단위 작업 진입점
              ├─ start-phase.md  — Phase 단위 작업 진입점
              └─ update-docs.md  — Phase 완료 후 문서 동기화

[메모리]  ~/.claude/projects/.../memory/
              ├─ feedback_harness_workflow.md
              └─ feedback_swiftui_fullscreencover_overlay.md
```

---

## 설정 파일 상세

### `~/.claude/settings.json` (글로벌)

| 항목 | 값 | 설명 |
|------|----|------|
| `model` | `sonnet` | 기본 모델 |
| `effortLevel` | `medium` | 응답 노력 레벨 |
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `"1"` | 팀 에이전트 기능 활성화 |
| `enabledPlugins.swift-lsp@claude-plugins-official` | `true` | Swift LSP 플러그인 |
| `hooks.PermissionRequest` | `[]` | 커스텀 훅 없음 |

> Stop hook은 이 파일에서 **제거됨** — 프로젝트 레벨 `settings.local.json`으로 이동.

---

### `.claude/settings.local.json` (프로젝트, git ignored)

#### permissions.allow 목록

| 패턴 | 목적 |
|------|------|
| `Bash(grep:*)` | 코드 검색 |
| `Bash(ls:*)` | 디렉토리 탐색 |
| `Bash(find:*)` | 파일 탐색 |
| `Bash(cat)` | 파일 읽기 |
| `Bash(python3:*)` | 스크립트 실행 |
| `Bash(swift:*)` | Swift 스크립트 |
| `Bash(open:*)` | 앱/파일 열기 |
| `Bash(defaults read:*)` | macOS 기본값 조회 |
| `Bash(xcodebuild -project TravelCalculator.xcodeproj ...)` | 빌드 |
| `Bash(xcodebuild test *)` | 테스트 실행 |
| `Bash(xcodebuild -showdestinations ...)` | 시뮬레이터 목록 |
| `Bash(xcrun simctl:*)` | 시뮬레이터 제어 |
| `Bash(gem list:*)` | Ruby gem 조회 |
| `Bash(/usr/libexec/PlistBuddy:*)` | plist 편집 |
| `Bash(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" ...)` | 번들 ID 확인 |
| `Bash(ffmpeg:*)` | 영상 처리 (패턴) |
| `Bash(sips:*)` | 이미지 처리 (패턴) |
| `Bash(wait)` | 프로세스 대기 |
| `Bash(git push *)` | 원격 푸시 |
| `Bash(gh pr:*)` | GitHub PR |
| `Bash(claude mcp:*)` | MCP 관리 |
| `Bash(claude plugin:*)` | 플러그인 관리 |
| `Bash(curl -s "https://open.er-api.com/v6/latest/USD")` | 환율 API 조회 |
| `Bash(curl -sI "https://open.er-api.com/v6/latest/USD")` | 환율 API 헤더 확인 |
| `Bash(awk -F'=' '/EXCHANGE_RATE_API_KEY/ ...')` | API 키 상태 확인 |
| `mcp__figma__get_design_context` | Figma 디자인 컨텍스트 |
| `mcp__figma__get_screenshot` | Figma 스크린샷 |
| `mcp__figma__get_metadata` | Figma 메타데이터 |
| `mcp__figma__use_figma` | Figma 일반 사용 |
| `mcp__figma__search_design_system` | 디자인 시스템 검색 |
| `mcp__codex__codex` | Codex MCP 검증 |
| `WebSearch` | 웹 검색 |
| `Read(//Users/jiyoung/Library/Developer/CoreSimulator/...)` | 시뮬레이터 앱 데이터 읽기 |
| `Read(//Applications/**)` | /Applications 읽기 |

#### hooks

| 이벤트 | 매처 | 스크립트 | 동작 |
|--------|------|----------|------|
| `UserPromptSubmit` | (없음) | `pre-prompt-harness-reminder.sh` | 구현 키워드 감지 시 경고 (비차단) |
| `PreToolUse` | `Edit\|Write` | `pre-edit-tdd-check.sh` | Store/Reducer/Models 레이어 편집 시 테스트 없으면 **차단** |
| `Stop` | (없음) | `osascript + afplay` | Claude 응답 완료 시 macOS 알림 + 소리 (async) |

---

## Hooks 상세

### `pre-prompt-harness-reminder.sh`

**이벤트**: `UserPromptSubmit` — 사용자가 프롬프트를 제출할 때마다 실행

```
입력 텍스트
  │
  ├─ /start-task 로 시작? → exit 0 (패스)
  ├─ read-only 키워드만? (확인/분석/알려/보여줘/읽어/검토/찾아/조회) → exit 0 (패스)
  └─ 구현 키워드 포함? (구현/추가해/만들어/수정해/작성해/개발/코딩/변경해/리팩터...) 
       → ⚠️ 경고 출력 후 exit 0 (차단 안 함)
```

> **의도**: 사용자가 `/start-task` 없이 구현 요청 시 하네스 우회를 상기시킴.
> **한계**: exit 0이므로 무시해도 Claude가 계속 진행 가능.

---

### `pre-edit-tdd-check.sh`

**이벤트**: `PreToolUse(Edit|Write)` — Edit/Write 도구 호출 직전 실행

```
편집 대상 파일
  │
  ├─ TravelCalculator/*.swift 아님? → exit 0 (패스)
  ├─ /Tests/ 경로? → exit 0 (테스트 파일 자체는 패스)
  ├─ /(Store|Reducer|Models)/ 경로 아님? → exit 0 (View 등 다른 레이어는 패스)
  └─ {BaseName}Tests.swift 파일 존재 여부 탐색
       ├─ 존재? → exit 0 (통과)
       └─ 없음? → ⛔ 차단 메시지 출력 + exit 2 (편집 불가)
```

**차단되는 레이어 (테스트 파일 필요)**:
- `TravelCalculator/*/Store/*.swift`
- `TravelCalculator/*/Reducer/*.swift`
- `TravelCalculator/*/Models/*.swift`

**차단 안 되는 레이어 (자유 편집)**:
- `*View.swift`, `*Display.swift`, `*Toolbar.swift` 등 UI 레이어
- `Core/`, `Data/` 내 Store·Reducer·Models 外 파일
- 테스트 파일 자체

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

---

## Multi-AI 구성 (`Plan.md` 참조)

| 도구 | 역할 | 마일스톤 |
|------|------|---------|
| **Claude Sonnet** (이 인스턴스) | 오케스트레이터 / 구현 | 전체 |
| **Claude Opus** | 설계 / Senior 리뷰어 | 1, 4 |
| **Codex MCP** (`mcp__codex__codex`) | 세컨드 오피니언 / plan 검증 | 1, 4 |
| **Figma MCP** (`mcp__figma__*`) | 디자인 → SwiftUI 변환 | 0, 1 |
| **Gemini CLI** (`gemini -p`) | 딥 리서치 / API 문서 | 2 |

---

## 알려진 한계

| 항목 | 내용 |
|------|------|
| `pre-prompt-harness-reminder.sh` | 한국어 오탐 가능성으로 차단 안 함 — 경고에 의존 |
| TDD 차단 범위 | Store/Reducer/Models 에만 적용. View/Extension 계층은 테스트 강제 없음 |
| Codex fallback | 3회 재시도 후 사용자가 승인하면 검증 없이 진행 가능 |
| `settings.local.json` | git ignored — 팀 공유 불가, 개인 오버라이드 전용 |
