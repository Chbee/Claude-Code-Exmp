# 하네스 — Hooks 상세

> 마지막 갱신: 2026-04-29
> 관련: [하네스 개요](harness.md) | [슬래시 커맨드](harness-commands.md)

---

## `pre-prompt-harness-reminder.sh`

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

## `pre-edit-tdd-check.sh`

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
