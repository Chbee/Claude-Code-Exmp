# /start-task

하네스 워크플로우를 시작합니다. Plan Mode에서 인터뷰 → Codex 검증 → 승인 후 TDD 개발.

## 사용법

```
/start-task [작업 설명]
```

## 실행 절차

### Step 1: Plan Mode 진입

EnterPlanMode를 호출하여 Plan Mode로 전환한다.
Plan Mode에서는 코드 편집이 차단되므로 안전하게 분석/설계를 진행한다.

### Step 2: 인터뷰 (Phase 1)

1. args의 작업 설명을 분석한다.
2. 관련 코드를 Explore 에이전트로 탐색한다 (재사용 가능한 패턴/함수 파악).
3. 사용자에게 AskUserQuestion으로 구체화 질문을 한다:
   - **scope**: 어디까지 구현하는가?
   - **영향 범위**: 어떤 파일/모듈이 영향을 받는가?
   - **엣지케이스**: 놓칠 수 있는 케이스가 있는가?
   - **재사용**: 기존 코드에서 활용할 수 있는 것이 있는가?
4. 구현 계획 초안을 plan 파일에 기록한다.

### Step 3: Codex 검증 (Phase 2)

구현 계획을 Codex MCP(`mcp__codex__codex`)에 전달하여 검증을 받는다.

Codex에게 전달할 내용:
- 현재 아키텍처 컨텍스트 (MVI, @Observable, 프로젝트 구조)
- 구현 계획 (수정 파일 목록, 접근 방식, 핵심 코드 스니펫)
- 검증 요청:
  - **아키텍처 일관성** — 기존 패턴과 충돌이 없는가?
  - **Over-engineering 여부** — 불필요한 추상화/확장이 포함되어 있지 않은가?
  - **코드 레벨 세컨드 오피니언** — 핵심 로직에 대한 대안이나 개선점

Codex 피드백을 plan 파일에 반영한다. over-engineering 경고가 있으면 반드시 계획을 수정한다.

### Step 4: 승인 요청 (Phase 3)

인터뷰 결과 + Codex 피드백이 반영된 plan을 ExitPlanMode로 사용자에게 제시한다.
사용자가 승인하면 TDD 개발을 시작한다.

### Step 5: TDD 개발 (승인 후)

승인 후 normal mode에서 TDD 순서로 개발한다:

1. **Red** — 실패하는 테스트를 먼저 작성한다. `xcodebuild test`로 실패를 확인한다.
2. **Yellow** — 하드코딩이나 최소 구현으로 테스트를 통과시킨다. dirty OK.
3. **Green** — 리팩터링으로 코드를 정리한다. 테스트가 여전히 통과하는지 확인한다.

각 Red → Yellow → Green 사이클마다 사용자에게 진행 상황을 보고한다.

## 주의사항

- Plan Mode에서 절대 코드를 편집하지 않는다 (시스템이 차단).
- Codex 검증에서 over-engineering 경고 시 반드시 계획을 수정한다.
- TDD에서 테스트 없이 구현 코드를 먼저 작성하지 않는다.
- 요청된 것만 구현한다 — 추측성 확장/추상화 금지.
