# Phase G Step 2 — Info.plist UILaunchScreen dict 적용

> 최종 위치: `docs/plans/phase-g-app-icon-splash/task-20260430-1620-step2-info-plist.md` (Plan Mode 종료 후 이동)
> 브랜치: `phase/g-app-icon-splash`
> Phase 문서: `docs/phase-g.md` (Step 2.1)

## Context

Phase G Step 1에서 `BrandSplashBG.colorset` / `SplashCenter.imageset`을 Asset Catalog에 등록 완료(`commit 63f073c`). 이번 Step 2는 그 자산을 `Info.plist`의 `UILaunchScreen` dict로 연결해 시스템 부팅 시 실제 런치 스크린이 렌더되도록 한다.

현재 `TravelCalculator/Info.plist:32-36`의 `UILaunchScreen` dict는 **빈 중첩 dict** 상태(`<key>UILaunchScreen</key><dict/>` 무의미 nesting). 이번 task에서 키 3종(`UIColorName=BrandSplashBG`, `UIImageName=SplashCenter`, `UIImageRespectsSafeAreaInsets=true`)으로 교체하면 시스템(Springboard)이 부팅 시 직접 합성하는 launch frame이 활성화된다.

가이드 §4c (Option B) 채택은 Step 1의 Codex 자문에서 이미 검증 완료 — SwiftUI `App` 구조 + `LaunchScreen.storyboard` 미존재 환경에서 자연스러운 선택.

## 작업 설명

`TravelCalculator/Info.plist` 32-36행 교체:

**Before**:
```xml
<key>UILaunchScreen</key>
<dict>
    <key>UILaunchScreen</key>
    <dict/>
</dict>
```

**After**:
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

3 keys, 3 values. 그 외 plist 변경 0건.

## 인터뷰 결과

### Phase 1 탐색 결과 (Step 1에서 누적)

- `Info.plist:32-36` — 기존 빈 중첩 dict 위치 확인 완료
- `BrandSplashBG.colorset` / `SplashCenter.imageset` — Step 1 commit `63f073c`로 등록 완료
- `INFOPLIST_FILE = TravelCalculator/Info.plist` (build setting 확인 완료)
- 프로젝트는 `LaunchScreen.storyboard` 없음 → Option B(Info.plist) 외 다른 경로 없음
- TravelCalculatorTests는 application host 모드 — `Bundle.main`이 호스트 앱

### Phase 3 사용자 결정

1. **TDD 방식**: Source-layout 테스트 1건 — `TravelCalculator/Info.plist`를 `PropertyListSerialization`으로 직접 파싱해 `UILaunchScreen` dict의 키 3종 + 빈 중첩 dict 제거 검증. Step 1의 `AppIconContentsTests` 패턴과 정합.
2. **Codex 자문**: 스킵 — Step 1에서 §4c Option B 적정성과 `UIImageRespectsSafeAreaInsets=true` 권장이 이미 검증됨. Step 2는 그 결정을 코드로 옮기는 단계라 알고리즘 결정 0건.

## 구현 계획

### 수정·신규 파일 목록

| 경로 | 종류 | 내용 |
|------|------|------|
| `TravelCalculator/Info.plist` | 수정 | 32-36행 `UILaunchScreen` dict 내용 교체 (키 3종 삽입, 빈 중첩 dict 제거) |
| `TravelCalculatorTests/Assets/InfoPlistLaunchScreenTests.swift` | 신규 | Source-layout 테스트 1건 (Step 1의 `AppIconContentsTests` 패턴) |

> 테스트 파일을 `TravelCalculatorTests/Assets/`에 두는 이유: AppIcon/SplashCenter와 동일하게 "앱 부트 시 시스템이 직접 소비하는 자원" 영역. 새 디렉토리(`Boot/` 등) 신설 회피로 폴더 폭발 방지. Step 1 Convention 리뷰에서 `Assets/` 위치 정합 확인됨.

### 테스트 코드 (Red → Yellow → Green)

```swift
// TravelCalculatorTests/Assets/InfoPlistLaunchScreenTests.swift
import Testing
import Foundation
@testable import TravelCalculator

struct InfoPlistLaunchScreenTests {

    // 빌드 산출물이 아닌 source Info.plist를 직접 파싱해 키 변경 회귀를 source-of-truth에서 검증.
    @Test func infoPlist_uiLaunchScreen_hasExpectedKeys() throws {
        let infoPlistURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TravelCalculator/Info.plist")

        let data = try Data(contentsOf: infoPlistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        let launchScreen = try #require(plist?["UILaunchScreen"] as? [String: Any])

        #expect(launchScreen["UIColorName"] as? String == "BrandSplashBG",
                "UIColorName must reference BrandSplashBG colorset")
        #expect(launchScreen["UIImageName"] as? String == "SplashCenter",
                "UIImageName must reference SplashCenter imageset")
        #expect(launchScreen["UIImageRespectsSafeAreaInsets"] as? Bool == true,
                "UIImageRespectsSafeAreaInsets must be true (notch/Dynamic Island avoidance)")

        #expect(launchScreen["UILaunchScreen"] == nil,
                "Empty nested UILaunchScreen dict (legacy placeholder) must be removed")
    }
}
```

### 실행 순서

1. **Red**: `InfoPlistLaunchScreenTests.swift` 작성 → `xcodebuild test` 실행 → 1 fail 확인 (현재 Info.plist는 빈 중첩 dict라 4개 assertion 모두 fail 또는 첫 `try #require` 단계에서 throw)
2. **Yellow**: `Info.plist:32-36` 교체 → `xcodebuild test` → 1 pass
3. **Green**: 빌드 warning 0 확인. 테스트 코드 추가 정리 불필요(이미 단순).

### 검증 항목

- [ ] `xcodebuild ... build` warning 0, error 0
- [ ] `xcodebuild test -only-testing:TravelCalculatorTests/InfoPlistLaunchScreenTests` 1건 pass
- [ ] `Info.plist`에 `UIColorName=BrandSplashBG`, `UIImageName=SplashCenter`, `UIImageRespectsSafeAreaInsets=true` 키 3개 존재
- [ ] `Info.plist`의 빈 중첩 `UILaunchScreen` dict 제거됨
- [ ] 시뮬레이터 부팅 시 `BrandSplashBG` 색 배경 + `SplashCenter` 마크 가시 (Light/Dark 모두) — Step 7 시각 검증
- [ ] Step 1 deferred 시각 검증 (Springboard에 설치된 아이콘 Light/Dark/Tinted 가독성)도 본 Step 후 함께 수행 가능

### 범위 외 (Step 3로 이월)

- Spec-UI §6.4 / §6.5 신설
- Phase G 역링크
- spec-auditor Fail 3건 자동 해소

## Codex Review

스킵 — Step 1 자문(`docs/plans/phase-g-app-icon-splash/task-20260430-1530-step1-assets.md` § Codex Review)에서 §4c Option B 적정성 검증 완료. 본 Step은 그 결정을 코드로 옮기는 단계로 알고리즘 결정 0건.

### Anti Over-Engineering 체크리스트

- [x] 1회성 추상화 없음 — 테스트 함수 본문에 URL 계산 인라인 (Step 1 `AppIconContentsTests`와 동일 패턴)
- [x] 헬퍼 0건 — 테스트 1개 함수 단독
- [x] 요청 범위 밖 기능 없음 — Spec-UI는 Step 3 분리
- [x] MVI 패턴 N/A — `Info.plist` 변경
- [x] @MainActor/Sendable N/A — Swift Testing 기본
- [x] Decimal N/A — 금액 연산 없음

## TDD 사이클 로그

### Red — 2026-04-30 16:23

`TravelCalculatorTests/Assets/InfoPlistLaunchScreenTests.swift` 작성. `try #require(plist?["UILaunchScreen"] as? [String: Any])`은 통과(현재 dict 자체는 존재) — 그러나 4개 `#expect`가 모두 fail (`UIColorName`/`UIImageName`/`UIImageRespectsSafeAreaInsets` 부재 + 빈 중첩 `UILaunchScreen` 잔존). 테스트 1건 fail.

### Yellow — 2026-04-30 16:24

`TravelCalculator/Info.plist:32-36` 교체:
- 빈 중첩 `<key>UILaunchScreen</key><dict/>` 제거
- `UIColorName=BrandSplashBG` / `UIImageName=SplashCenter` / `UIImageRespectsSafeAreaInsets=true` 삽입

테스트 1건 pass.

### Green — 2026-04-30 16:25

- `xcodebuild build` — `BUILD SUCCEEDED`. 무관 경고 1건(`appintentsmetadataprocessor`)만.
- Phase G 통합 회귀: `AssetCatalogRuntimeTests` 2 + `AppIconContentsTests` 1 + `InfoPlistLaunchScreenTests` 1 = **4건 모두 pass**.
- 테스트 코드 추가 정리 불필요(이미 단순).

## 팀 검증 반영

> 사용자 결정 2026-04-30: "지금 전부 반영, LOW까지 + V2는 분리".

### MEDIUM

- **M1 (Simplify S1 + Convention C1, 동일 라인)**: `launchScreen["UILaunchScreen"] == nil` 검증 → `launchScreen.count == 3` 교체. 단순 삭제 대신 키 추가 유입 회귀 안전망까지 확보.
- **M2 (UX)**: Step 7 검증 시나리오에 "Light 모드 sky blue 배경에서 SplashCenter tagline 가독성 시각 확인 — 마진하면 Light 변형 PNG에 navy tagline 재요청" 항목 추가.
- **M3 (UX)**: Step 3 (Spec-UI §6.5) 작성 시 "`UIImageRespectsSafeAreaInsets=true`는 lock decision — full-bleed 브랜드 모먼트 요청은 V2 분류" 명시 메모. Step 3 plan에서 직접 반영.

### LOW

- **L1 (Convention C2)**: 테스트 코멘트 2줄 → 1줄 압축 (sibling AppIconContentsTests parity).
- **L2 (Convention C4)**: `struct ... {` 직후 빈 줄 제거 (sibling parity).
- **L3 (UX LOW)**: Step 7 시각 체크리스트에 (a) Light 콜드 스타트 / (b) Dark 콜드 스타트 / (c) 백그라운드→포어그라운드 시 splash 미노출 확인 / (d) Dynamic Island 디바이스 / (e) Step 1 deferred 아이콘 3 모드(tap-and-hold → Edit appearance) 추가.

검증: M1+L1+L2 적용 후 `xcodebuild test -only-testing:.../InfoPlistLaunchScreenTests` → 1건 pass, 회귀 없음.

### V2 백로그 분리 (Spec-Tasks §9 추가)

- **V2-4**: Post-launch SwiftUI "welcome shimmer" (200ms cross-fade) — TestFlight 피드백 후 검토.
- **V2-5**: 로컬라이제이션 `SplashCenter` 변형 — i18n 마일스톤 시 자산 duplication.

### 무시 항목

(없음 — 모두 반영)
