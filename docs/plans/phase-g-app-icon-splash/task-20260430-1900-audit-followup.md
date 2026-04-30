# Phase G — Audit Followup (Step 2 storyboard pivot 결재 fix)

> 최종 위치: `docs/plans/phase-g-app-icon-splash/task-20260430-1900-audit-followup.md`
> 브랜치: `phase/g-app-icon-splash`
> 선행 commit: `f653537` (Step 2 storyboard pivot)
> 트리거: `/audit phase-g` 결재 결과 (Fail 1 + Warning 4)

## 작업 설명

`f653537` 적용 후 `/audit phase-g` 결재에서 **Fail 1건 + Warning 3건**(W4 Figma 수동 검증은 본 task 제외)이 검출됨. 모두 문서 표현 불일치로 코드 동작은 영향 없음. 본 task는 spec/phase 문서 정합성을 100%로 맞춰 Conditional Pass → Pass로 격상.

### 결재 결과 요약

| 우선순위 | 항목 | 위치 | 본 task 처리 |
|---|---|---|---|
| **Fail** | 구현 목표 §4번 Option B 서술 미취소 | `docs/phase-g.md:27` | ✅ 취소선 + Option A 보충 |
| W1 | `AssetCatalogRuntimeTests` 파일 경로 표기 (실제는 `AssetCatalogIntegrationTests.swift` 안 struct) | `specs/Spec-UI.md:234` | ✅ 정정 |
| W2 | `AppIconContentsTests` 파일 경로 표기 (동일 사유) | `specs/Spec-UI.md:206` | ✅ 정정 |
| W3 | "부동소수 8자리" 서술 vs 실제 3자리 | `docs/phase-g.md:56` | ✅ 정정 |
| W4 | Figma node-id 99-875 토큰 일치 (수동) | `specs/Spec-UI.md:124` | ❌ 본 task 제외 — Phase G가 토큰 구조 변경 0건이므로 저위험. `/update-docs` 단계에서 처리. |
| 추가 | Step 3.2 설명 "UILaunchScreen dict 방식" 잔존 (1차 audit W-2) | `docs/phase-g.md:73` | ✅ 함께 정정 — 동일 류 잔존 표현 |

## 인터뷰 결과

### Phase 1 탐색 결과 (audit 리포트에서 직접 차용)

- 4개 라인 모두 텍스트만 변경, 코드/테스트 변경 0건
- spec ↔ phase 양방향 링크 정합성 이미 통과 (audit Pass) — 이번 fix는 본문 표현만 패치
- W3 ("8자리" → "3자리"): `BrandSplashBG.colorset/Contents.json` 실제 값이 `0.357 / 0.659 / 0.925` 3자리. 8자리 표기는 Step 1 plan 작성 당시 가이드 표현을 그대로 옮긴 것으로 추정 — 실제 자산은 hex round-trip 정확도가 충족되는 최소 자릿수로 작성됨

### Phase 3 사용자 결정 (AskUserQuestion 결과)

1. **Codex 자문 — 스킵**: doc-only fix(텍스트 ~5줄), 알고리즘/아키텍처 결정 0건. plan에 스킵 사유 명시.
2. **W4 — 본 task 제외**: Figma MCP 수동 검증. Phase G가 토큰 구조 변경 0건이므로 현시점 재검증 불필요. 다음 `/update-docs` 단계에서 처리.

## 구현 계획

### 수정 파일 목록

| 경로 | 종류 | 변경 |
|------|------|------|
| `docs/phase-g.md:27` | 수정 | 구현 목표 §4번 ~~Option B~~ → Option A로 교체 (취소선 + 새 표현 병기, 결정 변경 이력 시각화) |
| `docs/phase-g.md:56` | 수정 | "부동소수 8자리 표기로 통일" → "소수점 3자리(hex round-trip 충족 최소 자릿수)" |
| `docs/phase-g.md:73` | 수정 | Step 3.2 설명에 "(→ Step 2 pivot 후 Option A storyboard 방식으로 재작성됨)" 주석 추가 |
| `specs/Spec-UI.md:206` | 수정 | `TravelCalculatorTests/Assets/AppIconContentsTests.appIconContents_hasExactlyThreeIOSEntries` → `TravelCalculatorTests/Assets/AssetCatalogIntegrationTests.AppIconContentsTests.appIconContents_hasExactlyThreeIOSEntries` |
| `specs/Spec-UI.md:234` | 수정 | `TravelCalculatorTests/Assets/AssetCatalogRuntimeTests.brandSplashBG_loadsFromHostAppBundle` / `splashCenter_loadsFromHostAppBundle` → `TravelCalculatorTests/Assets/AssetCatalogIntegrationTests.AssetCatalogRuntimeTests.brandSplashBG_loadsFromHostAppBundle` / `splashCenter_loadsFromHostAppBundle` |

### 수정 내용 상세

#### 1. `docs/phase-g.md:27` (Fail)

**Before**:
```
4. `Info.plist` `UILaunchScreen` dict에 `UIColorName=BrandSplashBG` / `UIImageName=SplashCenter` / `UIImageRespectsSafeAreaInsets=true` 적용
```

**After**:
```
4. ~~`Info.plist` `UILaunchScreen` dict에 `UIColorName=BrandSplashBG` / `UIImageName=SplashCenter` / `UIImageRespectsSafeAreaInsets=true` 적용~~ → **`UILaunchStoryboardName=LaunchScreen` 키 + `LaunchScreen.storyboard` 신규 (Option B → A pivot, 결정 기록 참조)**
```

#### 2. `docs/phase-g.md:56` (W3)

**Before**: `... 부동소수 8자리 표기로 통일.`
**After**: `... 소수점 3자리(hex round-trip 충족 최소 자릿수).`

#### 3. `docs/phase-g.md:73` (1차 audit W-2 잔존)

**Before**:
```
| 3.2 | `specs/Spec-UI.md` | §6.5 "런치 스크린" 섹션 신설 — `UILaunchScreen` dict 방식, ...
```

**After**:
```
| 3.2 | `specs/Spec-UI.md` | §6.5 "런치 스크린" 섹션 신설 — ~~`UILaunchScreen` dict 방식~~ (→ Step 2 pivot 후 Option A `UILaunchStoryboardName` + storyboard 방식으로 재작성), ...
```

#### 4. `specs/Spec-UI.md:206` (W2)

**Before**: `TravelCalculatorTests/Assets/AppIconContentsTests.appIconContents_hasExactlyThreeIOSEntries`
**After**: `TravelCalculatorTests/Assets/AssetCatalogIntegrationTests.AppIconContentsTests.appIconContents_hasExactlyThreeIOSEntries`

#### 5. `specs/Spec-UI.md:234` (W1)

**Before**: `TravelCalculatorTests/Assets/AssetCatalogRuntimeTests.brandSplashBG_loadsFromHostAppBundle / splashCenter_loadsFromHostAppBundle`
**After**: `TravelCalculatorTests/Assets/AssetCatalogIntegrationTests.AssetCatalogRuntimeTests.brandSplashBG_loadsFromHostAppBundle / splashCenter_loadsFromHostAppBundle`

### 실행 순서

1. **No Red 단계** — 본 task는 spec 텍스트 fix이라 테스트 추가/변경 0건. TDD 사이클 미적용.
2. 5개 라인 패치 적용 (Edit 5회).
3. **검증**: `/audit phase-g` 재실행 → Fail 0 + Warning ≤ 1 (W4만 잔존 또는 0건) 확인.
4. 커밋 + 푸시.

### 검증 항목

- [ ] `git diff` 5개 라인만 변경 (코드 0건)
- [ ] `/audit phase-g` 재실행 → Fail 0
- [ ] W1/W2/W3 항목이 audit 리포트에서 사라짐
- [ ] W4만 잔존 가능 (수동 위임)
- [ ] phase-g.md `구현 목표` §4번이 Option A 표현 + Option B 취소선 이력으로 시각화

### 범위 외

- **W4 (Figma 토큰)**: 본 task 제외. `/update-docs` 단계에서 처리.
- **테스트 코드**: 변경 없음. 테스트 메서드명/struct명 자체는 정확하므로 spec 표기만 fix.
- **Anti Over-Engineering**: doc fix이라 N/A. 헬퍼/추상화 추가 0건.

## Codex Review

**스킵** — 사용자 결정 (AskUserQuestion).

스킵 사유:
- doc-only fix (텍스트 5줄 패치)
- 알고리즘/아키텍처 결정 0건
- 코드 변경 0건이라 over-engineering 위험 자체가 없음
- audit 리포트가 단일 출처로 fix 위치/내용을 모두 제공 — 검증 대상 자체가 이미 결재 통과

## TDD 사이클 로그

**N/A** — spec 텍스트 fix이라 TDD 사이클 미적용. 적용 후 `/audit phase-g` 재실행으로 검증 갈음.

## 팀 검증 반영

(Step 6 종료 후 채움 — 본 task가 코드 변경 0건이므로 Simplify/컨벤션/UX 리뷰어 호출 가치가 없을 수 있음. 사용자 확인 필요.)
