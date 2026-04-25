# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TravelCalculator — 여행지 환율 계산기 iOS 앱. 현지 통화 금액 입력 → 실시간 KRW 변환.
바이브 코딩 실험 프로젝트로, 기존 [Chbee/TravelCalculator](https://github.com/Chbee/TravelCalculator) (develop 브랜치)를 포팅 중.

## Build & Run

```bash
# 빌드
xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator -destination 'platform=iOS Simulator,name=iPhone 16' build

# 테스트
xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator -destination 'platform=iOS Simulator,name=iPhone 16' test
```

> 마일스톤 4는 전체 테스트 스위트를 정리하는 일정이고, TDD(개발 시 테스트 선행)와 별개다.

## Tech Constraints

- **Swift 6.0**, SwiftUI, iOS 17+ (iPhone portrait only)
- **Strict Concurrency**: `@MainActor` default, `@Sendable` 처리 필수
- **@Observable** (not Combine's ObservableObject)
- 숫자 포맷 로케일 고정: 소수점 `.`, 천단위 `,` — 기기 로케일 무시
- 모든 금액 연산은 **Decimal** 타입 (Float/Double 사용 금지)

## Architecture: MVI (Model-View-Intent)

```
View → Intent(enum) → Reducer(순수 함수: State + Intent → State) → Store(@Observable) → View
```

- **Reducer는 순수 함수** — 사이드 이펙트 없음. 사이드 이펙트는 Store에서 처리
- **Store는 @Observable** — 상태 보유 + API 호출, 위치 조회 등 비동기 처리
- 전역 상태 흐름(AppStore/AppCurrencyStore/ToastManager 주입 구조)은 `specs/Spec-Architecture.md` §4.3 참조

## Key Specs

기획서는 `specs/` 디렉토리에 분리되어 있고, `Spec.md`가 인덱스:
- `specs/Spec-Overview.md` — 기능 명세 (계산기 엣지 케이스, 환율 API, 오프라인 대응, Toast)
- `specs/Spec-UI.md` — 화면 설계, 디자인 시스템
- `specs/Spec-Architecture.md` — MVI 아키텍처, 폴더 구조
- `specs/Spec-DataModel.md` — 전체 데이터 모델 정의
- `specs/Spec-Tasks.md` — 마일스톤별 태스크 목록 (74개)

## Milestones

| # | Milestone | Status |
|---|-----------|--------|
| 0 | 온보딩 | 완료 (Phase D) |
| 1 | Calculator UI | 완료 (Phase A+B) |
| 2 | Exchange Rate (open.er-api.com) | 완료 (Phase C) |
| 3 | Offline Support | 미착수 |
| 4 | Testing | 일부 완료 (4.3 API 테스트, 나머지 미착수) |

## Multi-AI Workflow

이 프로젝트는 Multi-AI 오케스트레이션을 사용 (자세한 내용은 `Plan.md` 참조):
- **Gemini CLI** (`gemini -p "질문"`): 딥 리서치, API 문서 검색
- **Codex CLI** (`codex exec "작업"`): 세컨드 오피니언 코드 생성
- **Figma MCP**: 디자인 토큰/화면 → SwiftUI 변환 — node-id 등 상세는 `docs/figma.md`
- 모델 스위칭: Opus(설계) / Sonnet(구현) / Haiku(단순)

## Harness Workflow

모든 작업은 `/start-task`로 시작 — Plan Mode 인터뷰 → Codex 검증 → TDD(Red→Yellow→Green). 자세한 구성(훅/슬래시 커맨드/메모리 구조)은 `docs/harness.md` 참조.

## Important Notes

- 환율 API는 `open.er-api.com/v6/latest/USD` (USD 기준, 인증 불필요, 24h 갱신) — API 키 없음
  - KRW 환산은 `USD→KRW / USD→X`를 API 레이어에서 사전 계산 (spec 2.2.3 은행 반올림, scale 8)
  - 캐시 유효성은 `searchDate == 오늘 KST` 기준 (24h TTL 아님)
- iOS 기본 계산기와 동일한 AC/C 토글, `=` 반복 동작을 정확히 따라야 함 (상세 엣지케이스는 `specs/Spec-Overview.md` §2.1 참조)
