# 하네스 엔지니어링 구성 문서

> 마지막 갱신: 2026-04-29
> 분리 문서: [Hooks 상세](harness-hooks.md) | [슬래시 커맨드 + 워크플로우](harness-commands.md)

---

## 전체 구성 지도

```
[글로벌]  ~/.claude/settings.json
              └─ 모델 / 환경변수 / 플러그인 / effortLevel

[프로젝트] .claude/settings.json         ← committed (팀 공유)
              └─ hooks
                   ├─ UserPromptSubmit → pre-prompt-harness-reminder.sh
                   └─ PreToolUse(Edit|Write) → pre-edit-tdd-check.sh

[프로젝트] .claude/settings.local.json   ← git ignored (개인 오버라이드)
              ├─ permissions.allow (자동 승인 목록)
              └─ hooks
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

### `.claude/settings.json` (프로젝트, committed — 팀 공유)

> 2026-04-29: 팀 공유 가치가 있는 TDD 가드 훅 2종을 `settings.local.json`에서 이동.

#### hooks

| 이벤트 | 매처 | 스크립트 | 동작 |
|--------|------|----------|------|
| `UserPromptSubmit` | (없음) | `pre-prompt-harness-reminder.sh` | 구현 키워드 감지 시 경고 (비차단) |
| `PreToolUse` | `Edit\|Write` | `pre-edit-tdd-check.sh` | Store/Reducer/Models 레이어 편집 시 테스트 없으면 **차단** |

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

#### hooks (개인 오버라이드)

| 이벤트 | 매처 | 스크립트 | 동작 |
|--------|------|----------|------|
| `Stop` | (없음) | `osascript + afplay` | Claude 응답 완료 시 macOS 알림 + 소리 (async) |

> 팀 공유 훅(UserPromptSubmit, PreToolUse)은 `settings.json`으로 이동 (2026-04-29).

---

## Hooks / 슬래시 커맨드

상세는 별도 문서로 분리:
- [Hooks 상세](harness-hooks.md) — `pre-prompt-harness-reminder.sh`, `pre-edit-tdd-check.sh`
- [슬래시 커맨드 + 워크플로우 흐름도](harness-commands.md) — `/start-task`, `/start-phase`, `/update-docs`

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
| `settings.local.json` | git ignored — 팀 공유 불가, 개인 오버라이드 전용 (팀 공유 훅은 `settings.json`으로 이동: 2026-04-29) |
