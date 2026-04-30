# Phase G Step 3 — Spec-UI §6.4 (앱 아이콘) + §6.5 (런치 스크린) 신설

> 최종 위치: `docs/plans/phase-g-app-icon-splash/task-20260430-1700-step3-spec-ui.md` (Plan Mode 종료 후 이동)
> 브랜치: `phase/g-app-icon-splash`
> Phase 문서: `docs/phase-g.md` (Step 3.1, 3.2)

## Context

Phase G Step 1 (asset wiring, `63f073c`) + Step 2 (Info.plist UILaunchScreen, `ac9bac5`)로 코드는 release-ready. Step 3는 그 결정을 spec에 잠그는 단계 — Spec-UI에 §6.4 (앱 아이콘) / §6.5 (런치 스크린) 신설.

Step 1 종료 시 spec-auditor가 보고한 Phase G 3 Fail 중:
- ✅ Info.plist UILaunchScreen 미완성 — Step 2(`ac9bac5`)로 해소
- ❌ Spec-UI §6.4 / §6.5 미신설 — **본 Step 3로 해소**
- ❌ Phase G 역링크 누락 — §6.4/§6.5에 `> **수정 이력**: [Phase G]` 포함하여 함께 해소

코드 변경 0건. 검증은 spec-auditor 재실행으로 3 Fail → 0 Fail 확인.

## 작업 설명

`specs/Spec-UI.md` 167행(`§6.3 햅틱 피드백` 끝) 직후에 §6.4 / §6.5 신설. 기존 §6.1 / §6.2 형식과 정합 — Source of Truth 계층 + 자산 표 + 정책 + 검증 가능 항목 + 역링크.

## 인터뷰 결과

### Phase 1 탐색 결과

- `Spec-UI.md` 현재 167행 종료, §6.3 햅틱 피드백 다음에 신설 자리 비어 있음
- 역링크 패턴 (`Spec-ExchangeRate.md:23` 등): 섹션 본문 끝에 `> **수정 이력**: [Phase X](../docs/phase-x.md)` — 각 섹션마다 별도 등록
- §6.1 컬러 / §6.2 아이콘 모두 "Source of Truth 계층 → 표 → 정책 → 검증 가능 항목" 4단 구조
- Phase G Step 1/2의 모든 결정은 phase-g.md `## 결정 기록` + 자산 가이드(`INTEGRATION_GUIDE.md`)에 누적 — spec으로 단순 lift

### Phase 3 사용자 결정

1. **단순 진행** — §6.1/§6.2 형식 정합으로 §6.4/§6.5 작성. Codex 자문 스킵(문서만이라 알고리즘 결정 0건). 검증은 spec-auditor 재실행.

## 구현 계획

### 수정·신규 파일 목록

| 경로 | 종류 | 내용 |
|------|------|------|
| `specs/Spec-UI.md` | 수정 (append) | §6.3 직후 §6.4 (앱 아이콘) + §6.5 (런치 스크린) 신설. 각 섹션 끝에 `> **수정 이력**: [Phase G]` 역링크. |

### Spec 섹션 내용 (초안)

#### §6.4 앱 아이콘

**Source of Truth 계층** (위에서 아래로 우선)
1. 브랜드 자산 팩 (canonical) — `Tripy/INTEGRATION_GUIDE.md` §3 (외부 디렉토리 `/Users/SONJIYONG/tripy-appstore/dist/appstore/`)
2. `Assets.xcassets/AppIcon.appiconset/` — 자산 팩 PNG 사본 + `Contents.json`. iOS 18 universal 1024 single-slot.
3. `project.pbxproj` build setting — `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` (변경 시 spec 동시 갱신)

**iOS 18 3-variant 정책 + Swap 규칙**

| 슬롯 | PNG (filename) | 적용 모드 |
|---|---|---|
| Any (Default) | `AppIcon-Dark-1024.png` (navy bg) | Light 시스템 모드 홈 |
| Dark | `AppIcon-Light-1024.png` (sky gradient) | Dark 시스템 모드 홈 |
| Tinted | `AppIcon-Tinted-1024.png` | iOS 18 Tinted 모드 |

> **Swap 의도**: iOS는 어두운 아이콘이 Light 홈에서 가독이 높고 밝은 아이콘이 Dark 홈에서 가독이 높음. 브랜드 default가 navy(어두운 톤)인 본 프로젝트에서는 파일명과 슬롯 이름이 반대로 매핑됨. (가이드 §3a 참조)

**HIG 준수**
- 1024×1024 정사각형, 모서리 마스킹 X(iOS 자동 squircle), 알파 채널 X
- Mac idiom 슬롯 미사용 (iPhone portrait only — Spec-Architecture)
- Tinted 원본은 8-bit RGB(grayscale 아님) — V1+ TestFlight 전 grayscale L* 채널 재export 필요 (Spec-Tasks §9 백로그)

**검증 가능 항목** (결재 에이전트용)
- `AppIcon.appiconset/Contents.json`에 iOS universal 1024 엔트리 정확히 3개(Any/Dark/Tinted), 각 entry에 `filename` 부여
- Mac idiom 슬롯 0건
- 3개 PNG가 디렉토리 내 실재 (`AppIcon-Dark-1024.png`, `AppIcon-Light-1024.png`, `AppIcon-Tinted-1024.png`)
- `TravelCalculatorTests/Assets/AppIconContentsTests.appIconContents_hasExactlyThreeIOSEntries` 통과

> **수정 이력**: [Phase G](../docs/phase-g.md)

#### §6.5 런치 스크린

**Source of Truth 계층** (위에서 아래로 우선)
1. 브랜드 자산 팩 (canonical) — `INTEGRATION_GUIDE.md` §2 (sRGB hex), §4 (transparent center)
2. `Assets.xcassets/BrandSplashBG.colorset/` — sRGB Light `#5BA8EC` / Dark `#1E2A38`. **런치 스크린 전용** — Swift `Color.app*` 시맨틱 별칭에 추가하지 않고 `Info.plist`가 이름으로 직접 참조.
3. `Assets.xcassets/SplashCenter.imageset/` — 1290×1290 transparent PNG, Any + Dark 변형.
4. `Info.plist` `UILaunchScreen` dict — `UIColorName=BrandSplashBG` / `UIImageName=SplashCenter` / `UIImageRespectsSafeAreaInsets=true`.

**합성 방식 — Option B (가이드 §4c)**

iOS Springboard가 부팅 시 `UILaunchScreen` dict를 직접 읽어 합성. SwiftUI/UIKit 런타임이 켜지기 전 단계라 Swift 코드 진입점 없음 — 모든 자산은 Asset Catalog 등록 이름으로만 참조. 본 프로젝트에 `LaunchScreen.storyboard` 미존재.

**정책 결정**
- **`UIImageRespectsSafeAreaInsets=true` lock decision** — 마크가 노치/Dynamic Island/홈 인디케이터를 피해 safe area 안에 배치. 향후 "full-bleed 브랜드 모먼트" 요청은 V2 분류.
- **`-Full` PNG 미반입** — 가이드 §4d의 `Splash-{Light,Dark}-Full.png`는 디자인 QA 참조용. 앱 번들 포함 금지.
- **정적 launch 채택** — SwiftUI 애니메이션 splash는 Apple HIG가 권장하지 않으며 system → 첫 frame 사이 visible flash/re-mount seam 발생. 정적이 정답. (V2 백로그 V2-4: 200ms cross-fade는 TestFlight 피드백 후 검토)

**검증 가능 항목** (결재 에이전트용)
- `BrandSplashBG.colorset/Contents.json` 존재, Light/Dark sRGB components가 가이드 hex(`#5BA8EC` / `#1E2A38`)와 일치
- `SplashCenter.imageset/Contents.json` 존재, `appearances: luminosity=dark` entry 명시, 두 PNG 파일 실재
- `Info.plist` `UILaunchScreen` dict에 `UIColorName=BrandSplashBG` / `UIImageName=SplashCenter` / `UIImageRespectsSafeAreaInsets=true` 키 정확히 3개
- `Splash-{Light,Dark}-Full.png`가 앱 번들·Asset Catalog에 포함되지 않음
- `TravelCalculatorTests/Assets/AssetCatalogRuntimeTests.brandSplashBG_loadsFromHostAppBundle` / `splashCenter_loadsFromHostAppBundle` / `InfoPlistLaunchScreenTests.infoPlist_uiLaunchScreen_hasExpectedKeys` 통과

> **수정 이력**: [Phase G](../docs/phase-g.md)

### 실행 순서

1. `specs/Spec-UI.md` 167행 직후에 §6.4 / §6.5 append (위 초안 그대로 — 표 + 정책 + 검증 가능 항목 + 역링크)
2. spec-auditor (`Skill /audit phase-g`) 재실행 → Phase G 3 Fail → 0 Fail 확인
3. `xcodebuild test`로 회귀 없음 (spec 변경뿐이지만 안전망 차원) — 기존 4 테스트 모두 pass 유지

### 검증 항목

- [ ] `Spec-UI.md`에 §6.4 / §6.5 신설, 각 섹션에 "검증 가능 항목" 블록 + Phase G 역링크
- [ ] §6.4 / §6.5 본문이 §6.1 / §6.2 형식 정합 (Source of Truth 계층 → 표 → 정책 → 검증 가능 항목)
- [ ] spec-auditor 재실행 시 Phase G Fail 0건
- [ ] `xcodebuild build` warning 0, 회귀 없음
- [ ] phase-g.md "완료 기준" 모든 체크박스 충족 (시각 검증 항목 제외 — Step 7에서 사용자 수행)

### 범위 외

- CLAUDE.md / Spec-Architecture의 "iOS 17+" 표기 정정 (Codex 발견 — 별도 task)
- App Store Connect 미리보기 업로드 (가이드 §5)
- V1+ TestFlight 전 Tinted grayscale 재export (Spec-Tasks §9 V2 백로그)

## Codex Review

스킵 — Step 1 자문에서 §3a swap 규칙, §4c Option B, HIG 준수 사항 모두 검증 완료. 본 Step은 그 결정을 spec 문서로 lift하는 단계로 알고리즘 결정 0건.

### Anti Over-Engineering 체크리스트

- [x] 1회성 추상화 없음 — 문서 작성
- [x] 헬퍼 0건 — 문서 작성
- [x] 요청 범위 밖 기능 없음 — Spec-UI §6.4 / §6.5만 추가
- [x] MVI N/A — 문서
- [x] @MainActor/Sendable N/A — 문서
- [x] Decimal N/A — 문서

## TDD 사이클 로그

> 코드 변경 0건이라 전통적 Red→Yellow→Green 미적용. 대신 **spec-auditor 재실행** 단일 검증.

### spec-auditor 재실행 — 2026-04-30 17:10

phase-g 인자로 호출.

**결과**: Pass 14건 / Warning 2건 / **Fail 0건** ✅

- Step 1 종료 시 3 Fail (§6.4 미신설 / §6.5 미신설 / 역링크 누락) 모두 자동 해소
- Pass 14건: AppIcon 3 entries + filename + idiom + Mac 슬롯 0 + PNG 실재 + 테스트 함수 / BrandSplashBG sRGB hex 일치 + SplashCenter dark appearance + Info.plist 키 3개 + Full PNG 미반입 + 테스트 함수 / Phase G 역링크 3건
- Warning 2건:
  - W1 (해소): phase-g.md "3건" → "5건" 정정 완료
  - W2 (자동 검증 불가): 시뮬레이터 시각 검증 — Step 7 사용자 수동 수행

## 팀 검증 반영

> 사용자 결정 2026-04-30: "HIGH+MEDIUM 전부 + LOW + V2 분리".

### HIGH

- **U1 (UX)** — §6.4에 자산 교체 5스텝 절차 추가 (자산 팩 → AppIcon.appiconset 갱신 → Tinted RGB 검증 → 빌드 → 시뮬레이터 시각 확인). §6.1 "갱신 절차" 표 형식과 정합.
- **U2 (UX)** — §6.1 본문 끝에 `BrandSplashBG` 예외 cross-link 추가. "뷰는 시맨틱만 참조" 규칙과 §6.5 "Color.app* 미추가" 충돌이 grep 검증 위반으로 오판되지 않도록 명시.

### MEDIUM

- **M1 (UX U3)** — §6.4 검증 가능 항목에 `[V1+ gate] AppIcon-Tinted-1024.png grayscale L* 채널 재export 완료` 추가 — TestFlight 진입 전 결재 누락 방지.
- **M2 (UX U4 — 거절)** — UX 리뷰의 "iPad/iOS 19 확장 트리거" 제안 모두 거절. 프로젝트가 iPhone portrait only(CLAUDE.md / Spec-Architecture)이고 iOS 19 4th variant도 미발표 가정. 사용자 결정: hypothetical future requirement는 미고려 대상이라 spec/백로그에 등록하지 않음.
- **M3 (UX U5 — 거절)** — UX 리뷰의 "정적 launch 재방문 트리거(TestFlight 임계 시 V2-4 재검토)" 거절. TestFlight 피드백 기반 미래 가정.
- **M4 (Simplify S1)** — §6.4 "단일 출처" → "canonical" 영문 통일.
- **M5 (Simplify S2)** — §6.5 "Color.app* 시맨틱 별칭" → "(§6.1)" 명시 링크.
- **M6 (Simplify S3)** — §6.4 검증 가능 항목 통합 — `Contents.json 3 entries 각 filename이 디렉토리 실재 PNG와 매칭`.

### LOW

- **L1 (UX U6)** — §6.4/§6.5 끝에 "갱신 컨벤션" 1줄 추가.
- **L2 (UX U7 — 거절)** — "현재 iOS 18 기준" 단서 거절. "향후 Apple이 새 키 도입 시" 미래 가정.

### V2 백로그 추가 (Spec-Tasks §9)

> 사용자 결정 2026-04-30: hypothetical/조건부 미래 가정 항목은 미고려 대상으로 모두 제거. Step 1/2/3에서 등록했던 V2-2(BrandNavy/BrandSky 조건부) / V2-4(post-launch shimmer) / V2-5(로컬라이제이션 SplashCenter) / V2-6(iPad idiom) / V2-7(full-bleed 옵션) / V2-8(iOS 19 4th variant) 6건 일괄 제거. Spec-Tasks §9에는 현 시점 결정된 후속 작업만 유지: Tinted grayscale 재export(V1+ TestFlight 게이트, High) + 런치 스크린 접근성(Reduce Transparency / Increase Contrast).

### 무시 항목

- **Convention C1**: §6.1 vs §6.2/§6.4/§6.5 "(위에서 아래로 우선)" divergence — pre-existing inconsistency. §6.4/§6.5는 §6.2와 정합 — 본 phase 결함 아님. 별도 task로 처리 가능.
- **Convention LOW**: §6.3 햅틱 소급 역링크 검토 — 블락 아님, 별도 task 가능.
- **Simplify L1**: ceremonial 표기 — 위 Convention C1과 동일 사유.
- **Simplify L2**: swap 규칙 재진술 중복 — spec canonical home이라 유지 정답.
