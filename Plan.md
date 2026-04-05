# TravelCalculator — AI & Figma 워크플로우

> 기획서: [Spec.md](Spec.md) (인덱스) → [specs/](specs/) 디렉토리 참조

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

### 마일스톤별 도구 매핑
| 마일스톤 | Claude 역할 | Gemini CLI | Codex CLI |
|----------|------------|------------|-----------|
| 0: 온보딩 | Sonnet 구현 | - | - |
| 1: 계산기 화면 | Opus 설계 → Sonnet 구현 | - | 세컨드 오피니언 Reducer |
| 2: 환율 로직 | Sonnet 구현 | **API 스펙 딥 리서치** | - |
| 3: 오프라인 대응 | Sonnet 구현 | - | - |
| 4: 테스트 코드 | Sonnet 구현 | - | 세컨드 오피니언 |

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
