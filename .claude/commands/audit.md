# /audit

TravelCalculator의 spec ↔ 코드 일치 여부를 결재 에이전트로 검증합니다.

## 사용법

```
/audit
/audit phase-c
/audit phase-f
```

## 동작

`spec-auditor` 서브에이전트를 Agent 도구로 호출합니다:

- 인자 없음 → 전체 spec audit (`specs/Spec-*.md`의 모든 "검증 가능 항목" 블록)
- 인자가 phase 이름이면 → 해당 `docs/phase-X.md`의 "영향 문서" 섹션이 가리키는 spec 섹션만 검증

## 검증 범위

에이전트는 spec에 박힌 룰을 4가지 카테고리로 분류해 실행:
1. **Grep 자동** — Reducer 사이드 이펙트, Color/Combine 직접 참조 등
2. **단위 테스트** — fetchRates 계약 등 동작 계약
3. **코드 실재** — 특정 함수/fallback 존재 여부
4. **수동** — Figma 일치, PR 설명 등 (자동 불가 → 경고만)

추가로 **Phase ↔ Spec 양방향 링크** 누락/stale 점검.

## 호출 예

```
/audit
→ Agent(subagent_type="spec-auditor", prompt="전체 spec audit. ...")

/audit phase-c
→ Agent(subagent_type="spec-auditor", prompt="phase-c 영향 섹션 audit. ...")
```

리포트(✅/⚠️/❌ 카테고리별)는 메인 대화로 반환됩니다. 코드 수정은 하지 않으며, fail 발견 시 사용자가 직접 또는 별도 task로 처리합니다.

## 주의

- 자주 호출되는 명령이 아님 — PR 직전 또는 큰 spec 변경 후가 적절
- xcodebuild test는 시간 비용이 있으므로, spec에 카테고리 B 룰이 없으면 호출하지 않음
- spec의 "검증 가능 항목"이 룰의 단일 출처 — 룰을 추가하려면 spec을 수정 (별도 매니페스트 없음)
