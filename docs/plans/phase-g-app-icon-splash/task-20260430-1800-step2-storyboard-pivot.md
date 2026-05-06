# Phase G — Step 2 재작성: Option B → Option A (LaunchScreen.storyboard)

> 최종 위치: `docs/plans/phase-g-app-icon-splash/task-20260430-1800-step2-storyboard-pivot.md`
> 브랜치: `phase/g-app-icon-splash`
> Phase 문서: `docs/phase-g.md` (Step 2 결정 변경 + Step 4 시각 검증 후속)

## Context

Step 2(`ac9bac5`)에서 가이드 §4c Option B(Info.plist `UILaunchScreen` dict)로 런치 스크린을 적용했으나, **시뮬레이터 시각 검증에서 렌더링 실패 발견**:
- 배경색은 정상(`#1E2A38` Dark)
- SplashCenter PNG가 화면 중앙 정렬 안 됨, 마크 상단 잘림, 워드마크 화면 폭 초과로 좌우 잘림, 태그라인 미표시

**근본 원인**: `SplashCenter.imageset/Contents.json`에 `scale` 키 누락. iOS는 1290×1290 PNG를 `@1x`로 해석 → 화면 폭(@3x 디바이스 기준 430pt)의 약 3배 크기로 stretch → 잘림. Step 1 plan의 Codex 자문에서도 이 부분은 가이드 §4a "Single Scale" 표현이 모호해서 놓침.

**결정 변경**: Option B(scale 명시 추가)로 패치하는 대신 가이드가 "recommended for most apps"로 표시한 **Option A(LaunchScreen.storyboard)** 채택. UIImageView + Aspect Fit + Auto Layout으로 디바이스/scale 무관 자동 정렬 → scale 문제 근본 해결.

## 작업 설명

1. `TravelCalculator/LaunchScreen.storyboard` 신규 — root view bg=`BrandSplashBG`, UIImageView image=`SplashCenter`, contentMode=`scaleAspectFit`, centerX/centerY constraint, width ≤ view.width × 0.8, aspect ratio 1:1.
2. `Info.plist` `UILaunchScreen` dict 제거 + `UILaunchStoryboardName=LaunchScreen` 키 추가.
3. `InfoPlistLaunchScreenTests` 명칭 유지, 내용을 storyboard 검증(파일 존재 + Info.plist 키)으로 교체. 기존 키 3종(UIColorName/UIImageName/UIImageRespectsSafeAreaInsets) 검증은 폐기.
4. `Spec-UI.md` §6.5 갱신 — Source of Truth 4번째 항목 + 합성 방식 + 검증 가능 항목을 storyboard 기준으로 재작성. "Option B" 표현 제거.
5. `docs/phase-g.md` 결정 기록 갱신 — Option B → A 전환 + 시각 깨짐 발견 사유.

## 인터뷰 결과

### Phase 1 탐색 결과 (누적)

- **fileSystemSynchronizedGroups 사용** — `TravelCalculator/LaunchScreen.storyboard` 디렉토리 dump만으로 빌드 픽업, pbxproj 수정 0건
- **현재 Info.plist 32-39행**에 `UILaunchScreen` dict 키 3개 존재 (`ac9bac5`로 적용됨)
- **build settings**: `GENERATE_INFOPLIST_FILE = NO`, `INFOPLIST_FILE = TravelCalculator/Info.plist` → Info.plist 직접 수정 방식. `INFOPLIST_KEY_*` 자동 생성 build setting은 무관
- **현재 storyboard 0개** — SwiftUI App 구조라 이번이 첫 storyboard 도입
- **`Assets.xcassets/BrandSplashBG.colorset` / `SplashCenter.imageset`** Step 1에서 등록됨. storyboard에서 named color/image 참조로 그대로 활용

### Phase 3 사용자 결정

1. **테스트 교체 방식**: `InfoPlistLaunchScreenTests` 명칭 유지, 내용을 (a) Info.plist `UILaunchStoryboardName==LaunchScreen` 검증, (b) `LaunchScreen.storyboard` 파일 실재 검증으로 교체. storyboard XML 구조 파싱은 fragile해서 스킵.
2. **Codex 자문**: 스킵 — Step 1/2 자문에서 Option A vs B 결정은 이미 검토됨. 현 시점은 가이드 §4b 그대로 적용하는 단계라 알고리즘 결정 0건.

## 구현 계획

### 수정·신규 파일 목록

| 경로 | 종류 | 내용 |
|------|------|------|
| `TravelCalculator/LaunchScreen.storyboard` | 신규 | UIKit launch screen, root view bg=BrandSplashBG, UIImageView SplashCenter Aspect Fit + Auto Layout |
| `TravelCalculator/Info.plist` | 수정 | `UILaunchScreen` dict 제거 + `UILaunchStoryboardName=LaunchScreen` 키 추가 |
| `TravelCalculatorTests/Assets/InfoPlistLaunchScreenTests.swift` | 수정 | 테스트 2건으로 교체 — UILaunchStoryboardName 검증 + storyboard 파일 존재 검증 |
| `specs/Spec-UI.md` | 수정 | §6.5 — Source of Truth 4번째 항목 / 합성 방식 / 검증 가능 항목을 storyboard 기준으로 재작성 |
| `docs/phase-g.md` | 수정 | 결정 기록에 Option B → A 전환 사유(시각 깨짐 발견) 추가, 완료 기준 검증 항목 갱신 |

### LaunchScreen.storyboard 내용

표준 Apple Xcode 템플릿 형식. 핵심 요소:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0"
          toolsVersion="..." targetRuntime="iOS.CocoaTouch"
          propertyAccessControl="none" useAutolayout="YES" launchScreen="YES"
          useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES"
          initialViewController="01J-lp-oVM">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="430" height="932"/>
                        <autoresizingMask key="autoresizingMask"
                                          widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView contentMode="scaleAspectFit"
                                       horizontalHuggingPriority="251"
                                       verticalHuggingPriority="251"
                                       image="SplashCenter"
                                       translatesAutoresizingMaskIntoConstraints="NO"
                                       id="SC0-im-001">
                                <constraints>
                                    <constraint firstAttribute="height"
                                                secondItem="SC0-im-001" secondAttribute="width"
                                                multiplier="1:1" id="ar-1"/>
                                </constraints>
                            </imageView>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
                        <color key="backgroundColor" name="BrandSplashBG"/>
                        <constraints>
                            <constraint firstItem="SC0-im-001" firstAttribute="centerX"
                                        secondItem="Ze5-6b-2t3" secondAttribute="centerX"
                                        id="cx-1"/>
                            <constraint firstItem="SC0-im-001" firstAttribute="centerY"
                                        secondItem="6Tk-OE-BBY" secondAttribute="centerY"
                                        id="cy-1"/>
                            <constraint firstItem="SC0-im-001" firstAttribute="width"
                                        secondItem="Ze5-6b-2t3" secondAttribute="width"
                                        multiplier="0.8" id="w-1"/>
                        </constraints>
                    </view>
                </viewController>
            </objects>
        </scene>
    </scenes>
    <resources>
        <image name="SplashCenter" width="1290" height="1290"/>
        <namedColor name="BrandSplashBG">
            <color red="0.357" green="0.659" blue="0.925" alpha="1"
                   colorSpace="custom" customColorSpace="sRGB"/>
        </namedColor>
    </resources>
</document>
```

핵심 결정:
- `useSafeAreas="YES"` + centerY=safeArea.centerY → 노치/Dynamic Island 자동 회피
- `contentMode="scaleAspectFit"` + aspect ratio 1:1 → SplashCenter 정사각형 비례 보존
- `width = view.width × 0.8` → 화면 폭의 80%만 차지, 좌우 마진 확보
- `image="SplashCenter"` 단일 참조 → Asset Catalog의 Light/Dark variant 자동 적용

### Info.plist 변경

**Before** (현재 32-39행):
```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>BrandSplashBG</string>
    <key>UIImageName</key>
    <string>SplashCenter</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <true/>
</dict>
```

**After**:
```xml
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

### 테스트 코드 (Red → Yellow → Green)

```swift
// TravelCalculatorTests/Assets/InfoPlistLaunchScreenTests.swift
import Testing
import Foundation
@testable import TravelCalculator

struct InfoPlistLaunchScreenTests {
    // Springboard가 부팅 시 UILaunchStoryboardName으로 storyboard를 찾아 합성한다.
    // Option B (UILaunchScreen dict)는 PNG scale 처리에서 잘림 — Option A (storyboard) 채택.
    @Test func infoPlist_usesLaunchStoryboard() throws {
        let infoPlistURL = Self.repoRoot.appendingPathComponent("TravelCalculator/Info.plist")
        let data = try Data(contentsOf: infoPlistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]

        #expect(plist?["UILaunchStoryboardName"] as? String == "LaunchScreen",
                "UILaunchStoryboardName must reference LaunchScreen storyboard")
        #expect(plist?["UILaunchScreen"] == nil,
                "Legacy UILaunchScreen dict must be removed (Option B → A pivot)")
    }

    @Test func launchScreenStoryboard_existsAtExpectedPath() {
        let storyboardURL = Self.repoRoot.appendingPathComponent("TravelCalculator/LaunchScreen.storyboard")
        #expect(FileManager.default.fileExists(atPath: storyboardURL.path),
                "LaunchScreen.storyboard must exist at TravelCalculator/")
    }

    private static var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
```

> Step 1 Simplify 리뷰에서 `Self.repoRoot` 인라인 권고가 있었으나, 이번 파일은 2개 함수에서 재사용 → static computed로 유지가 정답.

### 실행 순서

1. **Red**: 테스트 2건을 위 코드로 교체 → `xcodebuild test` → 둘 다 fail (LaunchStoryboardName 키 없음, storyboard 파일 없음)
2. **Yellow**:
   - `TravelCalculator/LaunchScreen.storyboard` 생성
   - `Info.plist` `UILaunchScreen` dict 제거 + `UILaunchStoryboardName` 키 추가
   - `xcodebuild test` → 2 pass
3. **Green**: 빌드 warning 0 확인. 시뮬레이터 부팅으로 시각 검증 (스크린샷에서 발견된 잘림 해소 확인) — Step 7 사용자 수동.

### Spec-UI §6.5 변경 요지

- Source of Truth 4번째 항목: `Info.plist UILaunchScreen dict` → `Info.plist UILaunchStoryboardName=LaunchScreen + TravelCalculator/LaunchScreen.storyboard`
- 합성 방식: "Option B (가이드 §4c)" → "Option A (가이드 §4b — Apple recommended)"
- 정책 결정: "UIImageRespectsSafeAreaInsets=true" 항목 제거(키 자체 없어짐), "정적 launch 채택" 유지, "-Full PNG 미반입" 유지. "Aspect Fit + width≤view.width×0.8 + safe area centerY" 항목 추가.
- 검증 가능 항목 재작성:
  - `LaunchScreen.storyboard` 파일 실재 + view backgroundColor=BrandSplashBG named ref + UIImageView image=SplashCenter named ref
  - `Info.plist`에 `UILaunchStoryboardName=LaunchScreen` 키, 기존 `UILaunchScreen` dict 미존재
  - `InfoPlistLaunchScreenTests.infoPlist_usesLaunchStoryboard` / `launchScreenStoryboard_existsAtExpectedPath` 통과

### phase-g.md 변경

- **결정 기록 추가**: "Splash 방식 — Option A로 전환(2026-04-30)" — Step 2 commit `ac9bac5`로 적용한 Option B에서 시각 검증 시 1290×1290 PNG의 scale factor 처리 실패 발견(워드마크/태그라인 잘림). 가이드 §4b가 "recommended for most apps"로 표시한 storyboard + Aspect Fit으로 전환하여 디바이스/scale 무관 정렬 보장.
- **완료 기준 갱신**: `Info.plist UILaunchScreen dict` 항목 → `Info.plist UILaunchStoryboardName + LaunchScreen.storyboard` 항목.
- **이전 "Option B 선택" 결정 기록은 삭제하지 않고 유지** — 결정 변경 이력 추적 가능.

### 검증 항목

- [ ] `xcodebuild build` warning 0, error 0
- [ ] `xcodebuild test -only-testing:TravelCalculatorTests/InfoPlistLaunchScreenTests` 2건 pass
- [ ] `LaunchScreen.storyboard` 빌드 산출물(`Base.lproj` 또는 root)에 컴파일됨 — actool/ibtool 출력 확인
- [ ] 시뮬레이터(Light/Dark) 부팅 시 스크린샷에서 발견된 잘림(워드마크 좌우/태그라인 하단)이 해소됨 — Step 7 시각 검증
- [ ] 기존 Phase G 테스트 4건(`AssetCatalogRuntimeTests` 2 + `AppIconContentsTests` 1 + 신규 InfoPlistLaunchScreenTests 2) **5건** 모두 pass
- [ ] `git diff TravelCalculator.xcodeproj/project.pbxproj` 빈 출력 (auto-discovery)

### 범위 외

- `SplashCenter.imageset/Contents.json` `scale` 키 추가 — Option A에서는 UIImageView가 scale 자동 처리하므로 불필요. 변경 없음.
- Spec-UI §6.4 (앱 아이콘) — 무관, 변경 없음.

## Codex Review

스킵 — 사용자 결정. Step 1/2 자문에서 Option A vs B 검토 완료. 본 task는 가이드 §4b 그대로 적용 단계.

### Anti Over-Engineering 체크리스트

- [x] 1회성 추상화 없음 — `Self.repoRoot` static computed는 2개 함수에서 재사용
- [x] 헬퍼 0건 추가 — 위와 동일
- [x] 요청 범위 밖 기능 없음 — Option A 전환에 필요한 변경만
- [x] MVI N/A — 런치 스크린 자체 Swift 진입 전 단계
- [x] @MainActor/Sendable N/A — 테스트 + storyboard
- [x] Decimal N/A — 금액 연산 없음

## TDD 사이클 로그

### Red (2026-05-06)
- `InfoPlistLaunchScreenTests.swift`를 storyboard 기준 2건(`infoPlist_usesLaunchStoryboard` / `launchScreenStoryboard_existsAtExpectedPath`)으로 교체
- `xcodebuild test -only-testing:TravelCalculatorTests/InfoPlistLaunchScreenTests` → 2건 fail 확인
  - `infoPlist_usesLaunchStoryboard`: 레거시 `UILaunchScreen` dict 잔존 + `UILaunchStoryboardName` 키 부재
  - `launchScreenStoryboard_existsAtExpectedPath`: `LaunchScreen.storyboard` 파일 부재

### Yellow (2026-05-06)
- `TravelCalculator/LaunchScreen.storyboard` 신규 (XML 표준 Apple 템플릿 형식): bg=`BrandSplashBG` named, UIImageView image=`SplashCenter` named, Aspect Fit + safe area centerY + width≤view.width×0.8 + 1:1 ratio
- `Info.plist` 32-39행 `UILaunchScreen` dict 제거 + `UILaunchStoryboardName=LaunchScreen` 키 추가
- `xcodebuild test` → InfoPlistLaunchScreenTests 2건 pass

### Green (2026-05-06)
- `xcodebuild build` warning 0, error 0 (`appintestmetadataprocessor` 메시지는 사전 잡음, 본 변경과 무관)
- Phase G 5건(`AssetCatalogRuntimeTests` 2 + `AppIconContentsTests` 1 + `InfoPlistLaunchScreenTests` 2) 전부 pass
- `git diff TravelCalculator.xcodeproj/project.pbxproj` 빈 출력 — `fileSystemSynchronizedGroups` 자동 인식
- 시각 검증(iPhone 16e iOS 26.2 시뮬레이터):
  - Light 시스템 외관 → sky bg + Light SplashCenter, 잘림 없음
  - Dark 시스템 외관 → navy bg + Dark SplashCenter, 잘림 없음
  - splash–first screen 연속성: 시스템 다크에서 navy splash → 다크 테마 메인 UI 매치 확인 (HIG 준수)

### 후속 결정 (Step 외 작업)
- AppIcon swap 폐기 (직관 매핑으로 전환) — 시각 검증 중 사용자 폰의 Icon Appearance 기본값(Light)으로 절대다수가 navy variant를 보게 됨이 문제로 드러나 swap 해제. 자세한 사유는 `docs/phase-g.md` 결정 기록.
- Splash 자동 전환 유지(옵션 D) — Multi-AI 토론(Gemini + Codex) 합의. icon–splash mismatch는 Apple iOS 18 Icon Appearance 분리 정책 영역으로 수용. 자세한 사유는 `docs/phase-g.md` 결정 기록.

## 팀 검증 반영

(Step 6 종료 후 채움 — `/audit` 실행 결과 반영 예정)
