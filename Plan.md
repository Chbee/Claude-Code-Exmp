# TravelCalculator 포팅 + 개발 설계 플랜

## Context
기존 `Chbee/TravelCalculator` (develop 브랜치)의 MVI 아키텍처 기반 여행 계산기 앱을
`Chbee/Claude-Code-Exmp` 레포로 포팅한다.
이 레포는 **바이브 코딩으로 생산성을 측정하기 위한 개인 실험 프로젝트**이다.

---

## 핵심 결정사항

| 항목 | 결정 |
|------|------|
| 아키텍처 | MVI (Model-View-Intent) — 기존 유지 |
| 최소 iOS 버전 | **iOS 18** (95%+ 점유율, 현재-1 원칙) |
| .xcodeproj | 기존 유지 (fileSystemSynchronization 활용) |
| 보일러플레이트 | Infrean20260327 → TravelCalculator로 리네이밍 |
| Figma MCP | 양방향 워크플로우 (Code ↔ Canvas) |
| AI 워크플로우 | Claude Code 오케스트레이터 + Gemini CLI + Codex CLI |
| CLI 인증 | OAuth 로그인 기반 (API 키 X) |
| API 키 | APIKeys.swift (.gitignore) + 템플릿 |

---

## iOS 버전 점유율 분석 (2026년 4월)

| iOS 버전 | 점유율 | 누적 |
|----------|--------|------|
| iOS 26 | ~79% | 79% |
| iOS 18 | ~16% | 95% |
| iOS 17 이하 | ~5% | 100% |

→ **iOS 18을 최소 지원 버전으로 설정** (95%+ 커버리지)

---

## 기존 TravelCalculator 분석

### 아키텍처: MVI + Clean Architecture
```
State (순수 struct) → Reducer (순수 함수) → Store (@Observable) → View (SwiftUI)
```

### 진행률: 14/48 (29%)
- Milestone 1 계산기 UI: 78% (사칙연산, 포맷, 통화 선택, 8자리 제한)
- Milestone 2 환율 로직: 0% (API 연동, 실시간 변환)
- Milestone 3 오프라인: 0%
- Milestone 4 테스트: 0%

### 기존 32개 파일 구조
```
Core/         AppStore, AppCurrencyStore, Haptic, Extensions
Domain/       Currency.swift (KRW, USD, TWD)
Data/         ExchangeRateAPI, LocationService, PermissionService
Presentation/ Calculator(9), CurrencySelect(4), Components(1), Toast(5)
```

---

## iOS 18 적응 사항

- `@Observable` 매크로 안정적 사용 (iOS 17+)
- `@Environment(Type.self)` 패턴 사용
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` 유지
- 순수 값 타입에 `nonisolated` 추가

---

## AI 워크플로우: Multi-AI 오케스트레이션

### 아키텍처
```
Claude Code (Opus 4.6 — 오케스트레이터/최종 판단)
  ├─ Gemini CLI: gemini -p "질문" → 딥 리서치, 웹 검색, API 문서
  ├─ Codex CLI: codex exec "작업" → 세컨드 오피니언 코드 생성
  ├─ /codex:rescue: 내장 스킬 → 디버깅, 리뷰
  └─ 모델 스위칭: Opus(설계) / Sonnet(구현) / Haiku(단순)
```

### Setup (OAuth 로그인 기반)
```bash
# Gemini CLI — Google 계정 로그인
npm install -g @google/gemini-cli
gemini  # 첫 실행 시 브라우저 OAuth 로그인 → 토큰 자동 저장

# Codex CLI — OpenAI 계정 로그인
npm install -g @openai/codex
codex auth login  # 브라우저 OAuth 로그인 → ~/.codex/auth.json 저장
```

### Phase별 도구 매핑
| Phase | Claude 역할 | Gemini CLI | Codex CLI |
|-------|------------|------------|-----------|
| A: Domain+Core | Opus 설계 → Sonnet 구현 | - | - |
| B: 컴포넌트 | Sonnet 구현 | - | - |
| C: 계산기 MVI | Opus 설계 → Sonnet 구현 | - | 세컨드 오피니언 Reducer |
| D: 통화 선택 | Sonnet 구현 | - | - |
| E: Data 레이어 | Sonnet 구현 | **API 스펙 딥 리서치** | - |
| F: 앱 진입점 | Sonnet 구현 | - | - |

---

## Figma 양방향 워크플로우 (토큰 최적화)

### 토큰 비용 분석
| 화면 | Figma 왕복 토큰 | 전략 |
|------|----------------|------|
| Calculator 키패드 | ~130K | Figma 활용 (복잡) |
| Currency 선택기 | ~86.5K | Figma 활용 |
| Toolbar | ~35.1K | Figma 활용 |
| Toast | ~15.6K | **직접 코딩** (단순) |

### 워크플로우
```
[Setup] Figma MCP 연결 (/mcp → figma → 인증)
[토큰] get_variable_defs → DesignTokens.json 로컬 캐싱
[복잡 화면] Claude SwiftUI → Code to Canvas → Figma 조정 → 읽기 → 업데이트
[단순 화면] Claude가 직접 SwiftUI 생성 (Figma 스킵)
```

### 토큰 최적화 전략 (33% 절감)
1. 디자인 토큰 1회 읽기 → `DesignTokens.json` 로컬 캐싱
2. `get_metadata` 먼저 → 필요한 노드만 `get_design_context` (2단계)
3. Toast 등 단순 컴포넌트는 Figma 스킵

---

## 구현 순서 (6 Phase, 33파일)

### Phase 0: 정리 + 리네이밍 ✅
- 기존 보일러플레이트 삭제
- `Infrean20260327/` → `TravelCalculator/` 리네이밍
- `project.pbxproj` 수정 (path, bundle ID, deployment target)

### Phase A: Domain + Core (6파일)
- Currency.swift, AppCurrencyStore, AppStore, Double+Format, Preview+ColorScheme, Haptic

### Phase B: 공통 컴포넌트 (6파일)
- IconButton, Toast 시스템 5파일

### Phase C: 계산기 MVI 모듈 (9파일) — 핵심
- CalculatorView/Store/State/Reducer/Intent/Display/DisplayModel/Keypad/Toolbar

### Phase D: 통화 선택 MVI 모듈 (4파일)
- CurrencySelectView/Store/State/Intent

### Phase E: Data 레이어 (4파일)
- ExchangeRateAPI, LocationService, PermissionService, LocationPermissionService

### Phase F: 앱 진입점 + 설정 (4파일)
- TravelCalculatorApp.swift, ContentView.swift, APIKeys.swift, APIKeys.swift.template

---

## 최종 파일 트리

```
TravelCalculator/
├── TravelCalculatorApp.swift
├── ContentView.swift
├── Assets.xcassets/
├── Config/APIKeys.swift (.gitignore)
├── Core/App/          AppStore, AppCurrencyStore
├── Core/Extensions/   Double+Format, Preview+ColorScheme
├── Core/              Haptic.swift
├── Domain/Models/     Currency.swift
├── Data/Network/      ExchangeRateAPI.swift
├── Data/Location/     LocationService.swift
├── Data/Permission/   PermissionService, LocationPermissionService
├── Presentation/Calculator/       (MVI 9파일)
├── Presentation/CurrencySelect/   (MVI 4파일)
├── Presentation/Components/       IconButton.swift
└── Presentation/Common/Toast/     (5파일)
```

---

## 검증
1. Phase A: 컴파일 성공
2. Phase C: 계산기 키패드/사칙연산 동작
3. Phase F: 앱 실행, 전체 기능 동작
4. Strict Concurrency 경고 0개
