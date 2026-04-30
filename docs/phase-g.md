# Phase G — App Icon + Launch Screen (앱 아이콘 + 스플래시)

> 브랜치: `phase/g-app-icon-splash`
> 목표: V1+ 릴리스 준비(Phase F §다음 Phase) — Tripy 브랜드 자산 가이드 [`/Users/SONJIYONG/tripy-appstore/dist/appstore/INTEGRATION_GUIDE.md`](../../../tripy-appstore/dist/appstore/INTEGRATION_GUIDE.md)에 따라 iOS 18 AppIcon 3 variants(Default/Dark/Tinted)와 런치 스크린(브랜드 색 배경 + 중앙 transparent 마크)을 적용.

---

## 영향 문서 (Impact)

이 Phase가 spec에 미치는 영향. 작업 진행 중 추가/수정 발견 시 누적 갱신.

- **추가/수정한 spec 섹션**:
  - [Spec-UI §6.1 컬러 팔레트](../specs/Spec-UI.md#61-컬러-팔레트) — Step 3에서 본문 끝에 `BrandSplashBG` 예외 cross-link 1줄 추가. "뷰는 시맨틱만 참조" 규칙과 §6.5 "Color.app* 미추가"의 충돌이 grep 검증 위반으로 오판되지 않도록 명시.
  - [Spec-UI §6.4 앱 아이콘](../specs/Spec-UI.md#64-앱-아이콘) — 신설. iOS 18 3-variant 정책(Any/Dark/Tinted), 1024×1024 단일 슬롯, 가이드 출처(Tripy brand pack), HIG 준수, 자산 교체 5스텝 절차, V1+ Tinted 게이트.
  - [Spec-UI §6.5 런치 스크린](../specs/Spec-UI.md#65-런치-스크린) — 신설 후 Step 2 재작성에서 Option A(`LaunchScreen.storyboard` + `UILaunchStoryboardName`) 기준으로 재작성. `BrandSplashBG` ColorSet + `SplashCenter` ImageSet 조합, "-Full" PNG 미반입 규칙, Aspect Fit + safe area centerY 정책, 정적 launch 채택.
  - [Spec-Tasks §9 개선 백로그](../specs/Spec-Tasks.md#9-개선-백로그) — Phase G UX 백로그 2건 추가: Tinted grayscale 재export (V1+ TestFlight 전 게이트, High) + 런치 스크린 접근성(Reduce Transparency / Increase Contrast).
- **참조만 (변경 없음)**:
  - [Spec-UI §6.2 아이콘](../specs/Spec-UI.md#62-아이콘) — UI 아이콘(Asset Catalog `MapPin`/`Toast*`, SF Symbols)과 분리. 표 변경 없음.

---

## 구현 목표

1. `AppIcon.appiconset` — iOS 18 3-variant(Any/Dark/Tinted) 1024×1024 PNG 등록 + Mac 슬롯 정리(iPhone-only 프로젝트)
2. `BrandSplashBG.colorset` — Light `#5BA8EC` / Dark `#1E2A38` 신규 (런치 스크린 전용)
3. `SplashCenter.imageset` — 1290×1290 transparent PNG Any/Dark 변형 신규
4. `Info.plist` `UILaunchScreen` dict에 `UIColorName=BrandSplashBG` / `UIImageName=SplashCenter` / `UIImageRespectsSafeAreaInsets=true` 적용
5. Spec-UI에 §6.4(앱 아이콘) / §6.5(런치 스크린) 신설 — 자산 출처·검증 가능 항목 명시
6. 시뮬레이터 빌드 후 Light/Dark 모드에서 아이콘·런치 스크린 가시 확인

---

## 자산 매핑 (가이드 §8 기준)

| 원본 파일 (`/Users/SONJIYONG/tripy-appstore/dist/appstore/`) | 목적지 |
|---|---|
| `AppIcon-Dark-1024.png` | `Assets.xcassets/AppIcon.appiconset/` → **Any (universal)** ※ 가이드 §3a 의도적 swap |
| `AppIcon-Light-1024.png` | `Assets.xcassets/AppIcon.appiconset/` → **Dark** |
| `AppIcon-Tinted-1024.png` | `Assets.xcassets/AppIcon.appiconset/` → **Tinted** |
| `launch-screen/SplashCenter-Light.png` | `Assets.xcassets/SplashCenter.imageset/` → **Any** |
| `launch-screen/SplashCenter-Dark.png` | `Assets.xcassets/SplashCenter.imageset/` → **Dark** |
| `launch-screen/Splash-*-Full.png` | (반입 금지 — 디자인 QA 참조용) |
| `previews/Preview-0*.png` | **본 Phase 범위 외** — App Store Connect 업로드 단계는 코드 변경 0건 |

> **swap 이유** (가이드 §3a): 가이드의 "Dark" 변형(navy bg)이 브랜드 default라 Light 모드 홈에서 가독이 좋고, "Light" 변형(sky gradient)은 Dark 모드 홈에서 가독이 좋음. 따라서 파일명과 슬롯 이름이 반대로 매핑됨.

---

## 태스크 목록

### Step 1: Asset Catalog 정비

| # | 파일 | 태스크 | 가이드/Spec 참조 |
|---|------|--------|------------------|
| 1.1 | `TravelCalculator/Assets.xcassets/AppIcon.appiconset/` | 가이드 §1의 PNG 3종(`AppIcon-Dark-1024.png` / `AppIcon-Light-1024.png` / `AppIcon-Tinted-1024.png`)을 복사. `Contents.json`을 가이드 §3b 형식으로 교체 — iOS universal 1024 Any/Dark/Tinted 3엔트리, Mac 슬롯 13개 전부 제거(프로젝트는 iPhone portrait only). | INTEGRATION_GUIDE §3 |
| 1.2 | `TravelCalculator/Assets.xcassets/BrandSplashBG.colorset/Contents.json` (신규) | Color Set 신규. `Any` = sRGB `#5BA8EC` (R 0.357 G 0.659 B 0.925), `Dark` = sRGB `#1E2A38` (R 0.118 G 0.165 B 0.220). 부동소수 8자리 표기로 통일. | INTEGRATION_GUIDE §2 |
| 1.3 | `TravelCalculator/Assets.xcassets/SplashCenter.imageset/` (신규) | `SplashCenter-Light.png` → Any, `SplashCenter-Dark.png` → Dark. `Contents.json`에 `appearances: luminosity=dark` 키 부여. `properties` 미설정(가이드 §4a "Single Scale, Preserve Vector off"). | INTEGRATION_GUIDE §4a |

### Step 2: 런치 스크린 (재작성 — Option B → A pivot)

| # | 파일 | 태스크 | 가이드/Spec 참조 |
|---|------|--------|------------------|
| 2.1 | ~~`TravelCalculator/Info.plist`~~ | ~~`UILaunchScreen` dict 내용 교체: `UIColorName=BrandSplashBG`, `UIImageName=SplashCenter`, `UIImageRespectsSafeAreaInsets=true`.~~ **(commit `ac9bac5` Option B 적용 후 시각 검증 시 SplashCenter PNG scale 처리 실패로 잘림 발견 — 아래 Step 2.2~2.4로 pivot)** | ~~INTEGRATION_GUIDE §4c (Option B)~~ |
| 2.2 | `TravelCalculator/LaunchScreen.storyboard` (신규) | UIKit launch screen 신설 — root view bg=`BrandSplashBG` named color, `UIImageView image=SplashCenter` + `contentMode=scaleAspectFit` + Auto Layout(centerX/centerY safe area, width ≤ view.width × 0.8, aspect 1:1). `useSafeAreas=YES` + `launchScreen=YES`. | INTEGRATION_GUIDE §4b (Option A) |
| 2.3 | `TravelCalculator/Info.plist` | `UILaunchScreen` dict 제거 + `UILaunchStoryboardName=LaunchScreen` 키 추가. | INTEGRATION_GUIDE §4b |
| 2.4 | `TravelCalculatorTests/Assets/InfoPlistLaunchScreenTests.swift` | 테스트 2건으로 교체 — `infoPlist_usesLaunchStoryboard` (UILaunchStoryboardName=LaunchScreen + 기존 dict 미존재 검증), `launchScreenStoryboard_existsAtExpectedPath` (storyboard 파일 실재 검증). storyboard XML 구조 파싱은 fragile하여 스킵. | docs/plans/phase-g-app-icon-splash/task-20260430-1800-step2-storyboard-pivot.md |

### Step 3: Spec 반영

| # | 파일 | 태스크 |
|---|------|--------|
| 3.1 | `specs/Spec-UI.md` | §6.3 햅틱 위에 §6.4 "앱 아이콘" 섹션 신설 — iOS 18 3-variant 정책, swap 이유, 1024 단일 슬롯, HIG 준수 항목, 자산 출처(Tripy brand pack), 검증 가능 항목(`AppIcon.appiconset` 슬롯 3개 채워짐 / Mac 슬롯 0건 / PNG 1024×1024 RGB). |
| 3.2 | `specs/Spec-UI.md` | §6.5 "런치 스크린" 섹션 신설 — `UILaunchScreen` dict 방식, `BrandSplashBG` ColorSet + `SplashCenter` ImageSet 조합, "-Full" PNG 미반입 규칙, 검증 가능 항목(Info.plist 키 3개 / ColorSet 존재 / ImageSet 존재 / "-Full" PNG bundle 미포함). |

### Step 4: 빌드 검증

| # | 태스크 |
|---|--------|
| 4.1 | `xcodebuild ... build` 성공 (warning 0, error 0) — `iPhone 16` 시뮬레이터 |
| 4.2 | 시뮬레이터에서 앱 실행 → 런치 스크린 1프레임 캡처 확인 (Light/Dark 모두) — `BrandSplashBG` 색이 깔리고 중앙에 `SplashCenter` 마크가 보이면 통과 |
| 4.3 | Springboard에 설치된 아이콘이 정상 렌더되는지 확인 (Light/Dark, Tinted는 iOS 18+ 기기에서 설정 → 아이콘 모드 변경) |

---

## 완료 기준

- [ ] `xcodebuild` 빌드 성공 (warning 0, error 0)
- [ ] `Assets.xcassets/AppIcon.appiconset/Contents.json` — iOS universal 1024 Any/Dark/Tinted 3엔트리만 존재 (Mac 슬롯 0건)
- [ ] `AppIcon-Dark-1024.png` / `AppIcon-Light-1024.png` / `AppIcon-Tinted-1024.png` 3개 PNG가 `AppIcon.appiconset/` 안에 존재 (1024×1024)
- [ ] `Assets.xcassets/BrandSplashBG.colorset/Contents.json` 존재, Any/Dark hex가 가이드와 일치
- [ ] `Assets.xcassets/SplashCenter.imageset/` 안에 `SplashCenter-Light.png` / `SplashCenter-Dark.png` 존재, `Contents.json`에 luminosity dark appearance 명시
- [ ] `Info.plist` — `UILaunchStoryboardName=LaunchScreen` 키 존재, 기존 `UILaunchScreen` dict 미존재
- [ ] `TravelCalculator/LaunchScreen.storyboard` 실재, root view backgroundColor=BrandSplashBG named ref, UIImageView image=SplashCenter named ref, scaleAspectFit + safe area centerY + width ≤ view.width × 0.8 + aspect 1:1
- [ ] `InfoPlistLaunchScreenTests.infoPlist_usesLaunchStoryboard` / `launchScreenStoryboard_existsAtExpectedPath` 통과
- [ ] 시뮬레이터(Light) 부팅 시 `#5BA8EC` 배경 + 중앙 SplashCenter 마크 가시 — sky blue 배경에서 tagline 가독성 확인 (마진하면 navy tagline 재export 요청)
- [ ] 시뮬레이터(Dark) 부팅 시 `#1E2A38` 배경 + Dark 변형 SplashCenter 마크 가시
- [ ] 백그라운드→포어그라운드 복귀 시 splash 미노출 확인 (iOS 스냅샷 사용 — 정상 동작이면 splash 안 보여야 함)
- [ ] Dynamic Island 디바이스(iPhone 15 Pro 시뮬레이터)에서 마크가 island와 충돌하지 않음 — safe area centerY anchor 검증
- [ ] Springboard 설치 후 tap-and-hold → "Edit appearance" → Light/Dark/Tinted 3 모드 모두에서 아이콘 가독 (Step 1 deferred 시각 검증)
- [ ] Spec-UI §6.4 / §6.5 신설, "검증 가능 항목" 블록 포함
- [ ] **영향 문서 섹션의 모든 추가/수정 항목이 spec에 실제로 반영됨**
- [ ] `Splash-Light-Full.png` / `Splash-Dark-Full.png` 가 앱 번들·Asset Catalog에 포함되지 않음 (가이드 §4d)

---

## 파일 구조 (생성/수정 예정)

```
TravelCalculator/
├── Assets.xcassets/
│   ├── AppIcon.appiconset/
│   │   ├── Contents.json                  ← 수정 (Mac 슬롯 제거 + filename 3종 부여)
│   │   ├── AppIcon-Dark-1024.png          ← 신규
│   │   ├── AppIcon-Light-1024.png         ← 신규
│   │   └── AppIcon-Tinted-1024.png        ← 신규
│   ├── BrandSplashBG.colorset/            ← 신규 디렉토리
│   │   └── Contents.json                  ← 신규 (Any/Dark sRGB)
│   └── SplashCenter.imageset/             ← 신규 디렉토리
│       ├── Contents.json                  ← 신규 (Any + luminosity:dark)
│       ├── SplashCenter-Light.png         ← 신규
│       └── SplashCenter-Dark.png          ← 신규
├── Info.plist                              ← 수정 (UILaunchStoryboardName=LaunchScreen)
└── LaunchScreen.storyboard                 ← 신규 (Option A pivot, UIImageView Aspect Fit + Auto Layout)

specs/
└── Spec-UI.md                              ← 수정 (§6.4 / §6.5 신설)

docs/
└── phase-g.md                              ← 신규 (이 파일)
```

---

## 결정 기록

- **V1+ TestFlight 전 게이트 — Tinted PNG grayscale 재export**: `AppIcon-Tinted-1024.png`는 8-bit RGB로 iOS 18 monochrome tint의 luminance 추출 시 의도된 색조와 어긋날 수 있음. Step 1에서는 brand pack 그대로 반입(merge gate 아님). V1+ TestFlight 진입 전 시각 검증 후 brand source에서 grayscale L* 채널 재export 필요 — Spec-Tasks §9 백로그(Phase G UX, High)에 등록됨.
- **Splash 방식 — Option B (Info.plist) 선택** *(2026-04-30 commit `ac9bac5`, 후속 pivot)*: 가이드 §4b/§4c 둘 다 제시. 본 프로젝트는 SwiftUI `App` 구조이고 `LaunchScreen.storyboard`가 없으며 기존 `Info.plist`에 빈 `UILaunchScreen` dict가 이미 있음. Option B가 자연스럽고 storyboard 빈 파일 추가가 불필요. **이 결정은 다음 항목으로 번복됨.**
- **Splash 방식 — Option A로 전환 (2026-04-30 storyboard pivot)**: Option B 적용 후 시뮬레이터 시각 검증에서 SplashCenter PNG 잘림 발견. 근본 원인은 `SplashCenter.imageset/Contents.json`에 `scale` 키 누락 → iOS가 1290×1290 PNG를 `@1x`로 해석 → `@3x` 디바이스에서 약 3배 stretch. Option B의 scale 키만 추가해도 해소 가능하나, 가이드가 "recommended for most apps"로 표시한 Option A(`LaunchScreen.storyboard` + UIImageView Aspect Fit + Auto Layout)로 전환 — UIImageView가 device scale을 자동 처리하므로 디바이스/scale 무관 정렬 보장. 결정 변경 이력 추적 위해 위 Option B 항목은 보존. 상세: `docs/plans/phase-g-app-icon-splash/task-20260430-1800-step2-storyboard-pivot.md`.
- **Aspect Fit + width ≤ view.width × 0.8 + safe area centerY**: storyboard에서 마크가 노치/Dynamic Island/홈 인디케이터를 피해 safe area 안에 80% 폭으로 정사각형 비례 보존. Step 3 Spec-UI §6.5에 명시.
- **Mac 슬롯 정리**: `AppIcon.appiconset/Contents.json`에 Mac idiom 13개 슬롯이 있으나 본 프로젝트는 iPhone portrait only(`Spec-Architecture`/Info.plist `UISupportedInterfaceOrientations~iphone`). 빌드 경고 회피 + Single Source of Truth 강화 차원에서 제거.
- **`BrandNavy` / `BrandSky` 제외**: 가이드 §2 표에는 informational로 등장하나 verification checklist §7과 launch screen 실제 사용처에는 없음. 즉시 사용처 없는 dead asset 회피.
- **App Store 미리보기 4종 제외**: 가이드 §5의 `previews/Preview-0*.png`는 App Store Connect 웹 콘솔 업로드 단계로 코드 변경 0건. 본 Phase는 앱 번들 통합 범위로 한정.
- **Figma node-id 미갱신**: 가이드는 PNG와 색 hex만 제공하고 Figma node 출처를 명시하지 않음. `docs/figma.md`는 디자인 시스템 내부 토큰용이므로 본 Phase에서는 변경 없음.

---

## 다음 Phase

V1+ 릴리스 준비 잔여 — App Store Connect 미리보기 업로드(가이드 §5), 스토어 메타데이터(이름/설명/키워드), 또는 V1 백로그 잔여(접근성: VoiceOver/Dynamic Type, Toast 스와이프 닫기).
