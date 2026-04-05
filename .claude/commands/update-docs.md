# /update-docs

현재 완료된 Phase의 문서를 자동으로 업데이트합니다.

## 수행 작업

1. 현재 git 브랜치에서 Phase를 감지 (예: `phase/a-foundation` → Phase A)
2. 해당 Phase의 `docs/phase-X.md` 완료 기준 `[ ]` → `[x]` 체크
3. `CLAUDE.md` Milestones 테이블 상태 업데이트
4. 변경된 파일을 docs 커밋으로 저장 (선택: 커밋 여부 확인 후)

## 실행 절차

### Step 1: 현재 Phase 감지

현재 git 브랜치를 확인하여 Phase를 파악하세요:
```bash
git branch --show-current
```

브랜치 패턴: `phase/a-foundation` → Phase A, `phase/b-calculator-ui` → Phase B, 등

### Step 2: phase-X.md 완료 기준 확인

`docs/phase-X.md`의 `## 완료 기준` 섹션을 읽고, 각 항목을 현재 코드베이스 상태와 비교하여 충족 여부를 판단하세요.

판단 기준:
- `xcodebuild` 빌드 성공 → `xcodebuild -project TravelCalculator.xcodeproj -scheme TravelCalculator -destination 'generic/platform=iOS Simulator' build` 실행 결과로 확인
- 파일 존재 여부 → Glob으로 확인
- 기능 구현 여부 → 해당 파일 Read 후 확인

완료된 항목은 `[ ]` → `[x]` 로 변경하세요.

### Step 3: CLAUDE.md 마일스톤 업데이트

`CLAUDE.md`의 `## Milestones` 테이블에서 현재 Phase에 해당하는 마일스톤 상태를 업데이트하세요.

상태 패턴 예시:
- `미착수` → `Phase A(Foundation) 완료 / Phase B(UI) 대기`
- `포팅 중` → `완료`

Phase와 마일스톤 대응:
- Phase A → Milestone 1 (Calculator UI의 Foundation 부분)
- Phase B → Milestone 1 (Calculator UI 완성)
- Phase C → Milestone 2 (Exchange Rate)
- Phase D → Milestone 0 (온보딩)
- Phase E → Milestone 3+4 (Offline + Testing)

### Step 4: 커밋 여부 확인

변경된 파일 목록을 보여주고, 커밋할지 사용자에게 확인하세요.

커밋 메시지 형식:
```
docs: Phase X 완료 기준 및 마일스톤 상태 업데이트
```

## 주의사항

- 빌드를 실제로 돌려서 확인하거나, 이미 빌드 성공이 확인된 경우 그 결과를 기준으로 판단
- 미완료 항목은 절대 `[x]`로 표시하지 말 것
- CLAUDE.md 수정 시 기존 포맷 유지
