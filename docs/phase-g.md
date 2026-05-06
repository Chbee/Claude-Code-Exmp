# Phase G — App Icon + Launch Screen (앱 아이콘 + 스플래시)

> 브랜치: `phase/g-app-icon-splash`
> 목표: V1+ 릴리스 준비(Phase F §다음 Phase) — Tripy 브랜드 자산 가이드 [`/Users/SONJIYONG/tripy-appstore/dist/appstore/INTEGRATION_GUIDE.md`](../../../tripy-appstore/dist/appstore/INTEGRATION_GUIDE.md)에 따라 iOS 18 AppIcon 3 variants(Default/Dark/Tinted)와 런치 스크린(브랜드 색 배경 + 중앙 transparent 마크)을 적용.

---

## 영향 문서 (Impact)

이 Phase가 spec에 미치는 영향. 작업 진행 중 추가/수정 발견 시 누적 갱신.

- **추가/수정한 spec 섹션**:
  - [Spec-UI §6.1 컬러 팔레트](../specs/Spec-UI.md#61-컬러-팔레트) — Step 3에서 본문 끝에 `BrandSplashBG` 예외 cross-link 1줄 추가. "뷰는 시맨틱만 참조" 규칙과 §6.5 "Color.app* 미추가"의 충돌이 grep 검증 위반으로 오판되지 않도록 명시.
  - [Spec-UI §6.4 앱 아이콘](../specs/Spec-UI.md#64-앱-아이콘) — 신설. iOS 18 3-variant 정책(Any/Dark/Tinted), 1024×1024 단일 슬롯, 가이드 출처(Tripy brand pack), HIG 준수, 자산 교체 5스텝 절차, V1+ Tinted 게이트. **2026-05-06 갱신**: swap 규칙 폐기 → 직관 매핑(파일명=슬롯), Icon Appearance 분리 정책 인지 한 단락 추가.
  - [Spec-UI §6.5 런치 스크린](../specs/Spec-UI.md#65-런치-스크린) — 신설. **2026-05-06 갱신**: Option B(Info.plist dict) → Option A(LaunchScreen.storyboard) 전환. Source of Truth 4번째 항목 storyboard 기준으로 재작성, 합성 방식 "Aspect Fit + safe area centerY + width≤×0.8"로 갱신, 정책 결정에 "시스템 외관 자동 전환 유지(D 채택)" 추가, 검증 가능 항목에 storyboard 파일/UILaunchStoryboardName/splash–first screen 연속성 추가.
  - [Spec-Tasks §9 개선 백로그](../specs/Spec-Tasks.md#9-개선-백로그) — Phase G UX 백로그 2건 추가: Tinted grayscale 재export (V1+ TestFlight 전 게이트, High) + 런치 스크린 접근성(Reduce Transparency / Increase Contrast).
- **참조만 (변경 없음)**:
  - [Spec-UI §6.2 아이콘](../specs/Spec-UI.md#62-아이콘) — UI 아이콘(Asset Catalog `MapPin`/`Toast*`, SF Symbols)과 분리. 표 변경 없음.

---

## 구현 목표

1. `AppIcon.appiconset` — iOS 18 3-variant(Any/Dark/Tinted) 1024×1024 PNG 등록 + Mac 슬롯 정리(iPhone-only 프로젝트)
2. `BrandSplashBG.colorset` — Light `#5BA8EC` / Dark `#1E2A38` 신규 (런치 스크린 전용)
3. `SplashCenter.imageset` — 1290×1290 transparent PNG Any/Dark 변형 신규
4. `LaunchScreen.storyboard` 신규 + `Info.plist` `UILaunchStoryboardName=LaunchScreen` 적용 (Option A — Aspect Fit + safe area)
5. Spec-UI에 §6.4(앱 아이콘) / §6.5(런치 스크린) 신설 — 자산 출처·검증 가능 항목 명시
6. 시뮬레이터 빌드 후 Light/Dark 모드에서 아이콘·런치 스크린 가시 확인

---

## 자산 매핑 (가이드 §8 기준)

| 원본 파일 (`/Users/SONJIYONG/tripy-appstore/dist/appstore/`) | 목적지 |
|---|---|
| `AppIcon-Light-1024.png` | `Assets.xcassets/AppIcon.appiconset/` → **Any (universal, Default)** |
| `AppIcon-Dark-1024.png` | `Assets.xcassets/AppIcon.appiconset/` → **Dark** |
| `AppIcon-Tinted-1024.png` | `Assets.xcassets/AppIcon.appiconset/` → **Tinted** |
| `launch-screen/SplashCenter-Light.png` | `Assets.xcassets/SplashCenter.imageset/` → **Any** |
| `launch-screen/SplashCenter-Dark.png` | `Assets.xcassets/SplashCenter.imageset/` → **Dark** |
| `launch-screen/Splash-*-Full.png` | (반입 금지 — 디자인 QA 참조용) |
| `previews/Preview-0*.png` | **본 Phase 범위 외** — App Store Connect 업로드 단계는 코드 변경 0건 |

> **매핑 정책**: 파일명과 슬롯 이름을 그대로 매칭(직관 매핑). iOS 18+ Icon Appearance 기본값이 Light라 절대다수 사용자가 sky variant를 보게 됨. swap 폐기 사유는 결정 기록 참조.

---

## 태스크 목록

### Step 1: Asset Catalog 정비

| # | 파일 | 태스크 | 가이드/Spec 참조 |
|---|------|--------|------------------|
| 1.1 | `TravelCalculator/Assets.xcassets/AppIcon.appiconset/` | 가이드 §1의 PNG 3종(`AppIcon-Dark-1024.png` / `AppIcon-Light-1024.png` / `AppIcon-Tinted-1024.png`)을 복사. `Contents.json`을 가이드 §3b 형식으로 교체 — iOS universal 1024 Any/Dark/Tinted 3엔트리, Mac 슬롯 13개 전부 제거(프로젝트는 iPhone portrait only). | INTEGRATION_GUIDE §3 |
| 1.2 | `TravelCalculator/Assets.xcassets/BrandSplashBG.colorset/Contents.json` (신규) | Color Set 신규. `Any` = sRGB `#5BA8EC` (R 0.357 G 0.659 B 0.925), `Dark` = sRGB `#1E2A38` (R 0.118 G 0.165 B 0.220). 부동소수 8자리 표기로 통일. | INTEGRATION_GUIDE §2 |
| 1.3 | `TravelCalculator/Assets.xcassets/SplashCenter.imageset/` (신규) | `SplashCenter-Light.png` → Any, `SplashCenter-Dark.png` → Dark. `Contents.json`에 `appearances: luminosity=dark` 키 부여. `properties` 미설정(가이드 §4a "Single Scale, Preserve Vector off"). | INTEGRATION_GUIDE §4a |

### Step 2: Info.plist 런치 스크린

| # | 파일 | 태스크 | 가이드/Spec 참조 |
|---|------|--------|------------------|
| 2.1 | `TravelCalculator/Info.plist` + `LaunchScreen.storyboard` | `Info.plist`에 `UILaunchStoryboardName=LaunchScreen` 키 추가, 레거시 `UILaunchScreen` dict 제거. `TravelCalculator/LaunchScreen.storyboard` 신규 — view bg=`BrandSplashBG`(named), UIImageView image=`SplashCenter`(named), Aspect Fit + safe area centerY + width≤view.width×0.8 + 1:1 ratio. | INTEGRATION_GUIDE §4b (Option A) — Option B에서 시각 검증 후 pivot, 결정 기록 참조 |

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

- [x] `xcodebuild` 빌드 성공 (warning 0, error 0)
- [x] `Assets.xcassets/AppIcon.appiconset/Contents.json` — iOS universal 1024 Any/Dark/Tinted 3엔트리만 존재 (Mac 슬롯 0건), 직관 매핑 (Any=Light PNG / Dark=Dark PNG / Tinted=Tinted PNG)
- [x] `AppIcon-Dark-1024.png` / `AppIcon-Light-1024.png` / `AppIcon-Tinted-1024.png` 3개 PNG가 `AppIcon.appiconset/` 안에 존재 (1024×1024)
- [x] `Assets.xcassets/BrandSplashBG.colorset/Contents.json` 존재, Any/Dark hex가 가이드와 일치
- [x] `Assets.xcassets/SplashCenter.imageset/` 안에 `SplashCenter-Light.png` / `SplashCenter-Dark.png` 존재, `Contents.json`에 luminosity dark appearance 명시
- [x] `Info.plist` — `UILaunchStoryboardName=LaunchScreen` 키 존재, 레거시 `UILaunchScreen` dict 미존재
- [x] `TravelCalculator/LaunchScreen.storyboard` 실재 — bg=`BrandSplashBG` named, UIImageView image=`SplashCenter` named, Aspect Fit + safe area centerY + width≤view.width×0.8 + 1:1
- [x] 시뮬레이터(Light) 부팅 시 `#5BA8EC` 배경 + 중앙 SplashCenter Light variant 가시 — 잘림 없음 (Option A pivot으로 해소)
- [x] 시뮬레이터(Dark) 부팅 시 `#1E2A38` 배경 + Dark 변형 SplashCenter 가시 — 잘림 없음
- [x] **splash–first screen 연속성**: 시스템 다크 모드일 때 navy splash → 다크 테마 메인 UI 매치 (HIG 준수)
- [ ] 백그라운드→포어그라운드 복귀 시 splash 미노출 확인 (iOS 스냅샷 사용 — 정상 동작이면 splash 안 보여야 함)
- [ ] Dynamic Island 디바이스(iPhone 15 Pro 시뮬레이터)에서 마크가 island와 충돌하지 않음 — safe area centerY 제약 검증
- [ ] Springboard 설치 후 tap-and-hold → "Edit appearance" → Light/Dark/Tinted 3 모드 모두에서 아이콘 가독 (Step 1 deferred 시각 검증)
- [x] Spec-UI §6.4 / §6.5 신설, "검증 가능 항목" 블록 포함
- [x] **영향 문서 섹션의 모든 추가/수정 항목이 spec에 실제로 반영됨**
- [x] `Splash-Light-Full.png` / `Splash-Dark-Full.png` 가 앱 번들·Asset Catalog에 포함되지 않음 (가이드 §4d)

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
├── LaunchScreen.storyboard                ← 신규 (Option A pivot — Aspect Fit + safe area)
└── Info.plist                              ← 수정 (UILaunchStoryboardName=LaunchScreen, 레거시 dict 제거)

specs/
└── Spec-UI.md                              ← 수정 (§6.4 / §6.5 신설)

docs/
└── phase-g.md                              ← 신규 (이 파일)
```

---

## 결정 기록

- **V1+ TestFlight 전 게이트 — Tinted PNG grayscale 재export**: `AppIcon-Tinted-1024.png`는 8-bit RGB로 iOS 18 monochrome tint의 luminance 추출 시 의도된 색조와 어긋날 수 있음. Step 1에서는 brand pack 그대로 반입(merge gate 아님). V1+ TestFlight 진입 전 시각 검증 후 brand source에서 grayscale L* 채널 재export 필요 — Spec-Tasks §9 백로그(Phase G UX, High)에 등록됨.
- **Splash 방식 — Option B (Info.plist) 선택 → Option A로 전환(2026-05-06)**: 초기엔 `Info.plist UILaunchScreen` dict 방식(Option B)으로 진행(`ac9bac5`). 시각 검증에서 1290×1290 PNG가 `@1x`로 해석되어 화면 폭 ~3배로 stretch → 워드마크/태그라인 잘림 발견. 가이드 §4b가 "recommended for most apps"로 표시한 storyboard + Aspect Fit으로 전환하여 디바이스/scale 무관 정렬 보장. (이전 "Option B 선택" 결정 기록은 이력 추적 차원에서 유지)
- **`UIImageRespectsSafeAreaInsets=true` → Aspect Fit + safe area centerY 제약**: Option A 전환에 따라 키 자체 폐기. 마크는 storyboard의 `centerY=safeArea.centerY` + `width≤view.width×0.8` + 1:1 ratio 제약으로 노치/Dynamic Island/홈 인디케이터 회피. Step 3 Spec-UI §6.5에 명시.
- **AppIcon swap 폐기 (2026-05-06)**: 초기엔 가이드 §3a에 따라 `AppIcon-Dark-1024.png`(navy) → Any 슬롯, `AppIcon-Light-1024.png`(sky) → Dark 슬롯으로 swap 매핑(`63f073c`). 시각 검증 결과, 사용자 폰의 iOS 18+ Icon Appearance 기본값이 "Light"라 절대다수 사용자가 navy variant를 보게 됨 — 가이드 §3a의 "Light 모드 홈에서 navy 가독" 가정과 충돌(가이드는 "Auto" 옵트인 사용자만 고려). 직관 매핑(파일명 = 슬롯)으로 전환하여 기본값 사용자에게 sky variant 노출. swap 규칙은 spec-UI에서 폐기, 향후 자산 교체 시 같은 직관 매핑 유지.
- **Splash 시스템 외관 자동 전환 유지 (D 채택, 2026-05-06)**: AppIcon swap 폐기 후 "splash auto-switch + icon 정적(Light)" 조합으로 시스템 다크 모드일 때 navy splash → sky icon mismatch가 발생함을 사용자가 지적. Multi-AI 토론(Gemini + Codex) 결과 양측 모두 옵션 D(splash 자동 전환 유지) 합의. 핵심 논거: Apple HIG는 splash–first screen 매치를 요구하지만 splash–icon 매치는 요구하지 않음. 본 앱 메인 UI가 시스템 다크에서 다크 테마로 전환되므로 navy splash → 다크 main UI 연속성 충족(HIG 준수). icon–splash mismatch는 Apple이 iOS 18에서 Icon Appearance를 시스템 외관과 의도적으로 분리한 정책 영역으로 수용. 추가 코드 변경 0건.
- **Mac 슬롯 정리**: `AppIcon.appiconset/Contents.json`에 Mac idiom 13개 슬롯이 있으나 본 프로젝트는 iPhone portrait only(`Spec-Architecture`/Info.plist `UISupportedInterfaceOrientations~iphone`). 빌드 경고 회피 + Single Source of Truth 강화 차원에서 제거.
- **`BrandNavy` / `BrandSky` 제외**: 가이드 §2 표에는 informational로 등장하나 verification checklist §7과 launch screen 실제 사용처에는 없음. 즉시 사용처 없는 dead asset 회피.
- **App Store 미리보기 4종 제외**: 가이드 §5의 `previews/Preview-0*.png`는 App Store Connect 웹 콘솔 업로드 단계로 코드 변경 0건. 본 Phase는 앱 번들 통합 범위로 한정.
- **Figma node-id 미갱신**: 가이드는 PNG와 색 hex만 제공하고 Figma node 출처를 명시하지 않음. `docs/figma.md`는 디자인 시스템 내부 토큰용이므로 본 Phase에서는 변경 없음.

---

## 다음 Phase

V1+ 릴리스 준비 잔여 — App Store Connect 미리보기 업로드(가이드 §5), 스토어 메타데이터(이름/설명/키워드), 또는 V1 백로그 잔여(접근성: VoiceOver/Dynamic Type, Toast 스와이프 닫기).
