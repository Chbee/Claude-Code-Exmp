# Phase G Step 1 — Asset Catalog 정비

> 최종 위치: `docs/plans/phase-g-app-icon-splash/task-20260430-1530-step1-assets.md` (Plan Mode 종료 후 이동)
> 브랜치: `phase/g-app-icon-splash`
> Phase 문서: `docs/phase-g.md`

## Context

Phase F까지 V1 기능은 완성. Phase F `## 다음 Phase`에 명시된 V1+ 릴리스 준비의 첫 단계 — Tripy 브랜드 자산을 적용해 앱 아이콘과 런치 스크린을 배포 가능 상태로 만든다.

현재 `AppIcon.appiconset/`은 placeholder(PNG 0건, Mac 슬롯 13개 + iOS 1024 3 슬롯)이고 `Info.plist` `UILaunchScreen` dict는 비어 있어 부팅 시 시스템 기본 흰/검 화면이 보인다. `/Users/SONJIYONG/tripy-appstore/dist/appstore/INTEGRATION_GUIDE.md`가 바인딩 절차를 단일 출처로 명시하고 있고, 본 task는 §2~§4a (Asset Catalog 부분)만 처리한다. Info.plist는 Step 2에서, Spec-UI 반영은 Step 3에서.

> **Deployment target 정정** (Codex 자문 발견): CLAUDE.md/Spec-Architecture는 "iOS 17+"로 적혀있으나 실제 `IPHONEOS_DEPLOYMENT_TARGET=18.0` (`project.pbxproj:398`). 이번 plan은 iOS 18 기준으로 작성. AppIcon Tinted variant는 iOS 18 도입 키이므로 호환성 이슈 없음. CLAUDE.md/Spec 표기 정정은 Phase G 범위 외(별도 task로 분리).

## 작업 설명

Phase G Step 1 — Asset Catalog 3종 정비:
1. `AppIcon.appiconset` — Mac 슬롯 제거 + Tripy 3 variants (Default/Dark/Tinted) 1024 PNG 등록 (가이드 §3a swap 규칙 준수)
2. `BrandSplashBG.colorset` 신규 — Light `#5BA8EC` / Dark `#1E2A38`, sRGB
3. `SplashCenter.imageset` 신규 — 1290×1290 transparent PNG 2종(Light/Dark), single scale

원본 PNG는 `/Users/SONJIYONG/tripy-appstore/dist/appstore/`에서 사본 복사 (원본 보존).

## 인터뷰 결과

### Phase 1 탐색 결과

**Xcode 프로젝트 구조**:
- objectVersion 77 (Xcode 16.3) — `fileSystemSynchronizedGroups` 사용 → Asset Catalog 자동 디스커버리
- `pbxproj`는 개별 `.imageset`/`.colorset`/PNG 파일 미참조. `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`만 명시
- `INFOPLIST_FILE = TravelCalculator/Info.plist` (lines 400, 435)
- **결론**: 새 colorset/imageset 디렉토리 추가 시 `pbxproj` 수정 0건 — 디렉토리 dump만으로 빌드 픽업

**원본 자산 검증 (`file` 명령)**:
- AppIcon-{Dark,Light,Tinted}-1024.png — 1024×1024, 8-bit RGB, non-interlaced (알파 없음 — HIG OK)
- SplashCenter-{Light,Dark}.png — 1290×1290, 8-bit RGBA (transparent center group)

**기존 패턴**:
- `MapPin.imageset/Contents.json`은 `idiom: universal` + `template-rendering-intent: template` 단일 SVG. 단순 raster PNG는 `properties` 블록 불필요 (가이드 §4a "Single Scale, Preserve Vector off")
- `AccentColor.colorset/Contents.json`은 universal 빈 well — 신규 colorset 작성 시 sRGB 컴포넌트 명시 필요

### Phase 3 사용자 결정

1. **TDD 방식**: Bundle Resource 테스트 — `TravelCalculatorTests`에 `UIColor(named: "BrandSplashBG", in: .main, ...)` / `UIImage(named: "SplashCenter", in: .main, ...)` non-nil + AppIcon variants 등록 검증 추가. asset 이름 오타·미등록 회귀 안전망 확보.
2. **Codex 검증**: `codex:rescue` 스킬로 한 번 자문 — iOS 18 3-variant 정책 + `UIImage(named:)` Bundle Resource 테스트 패턴의 적정성 확인.
3. **Splash 색 처리**: `Color.app*` 시맨틱 별칭 추가 X. `BrandSplashBG.colorset`은 런치 스크린(`Info.plist`) 전용. Swift 코드 진입점 없음.
4. **Mac 슬롯**: 13개 모두 제거 (iPhone-only 프로젝트).
5. **PNG 복사**: `cp` 사본 — 원본 디렉토리는 git 외부, 프로젝트 안으로 사본만 들어옴.

## 구현 계획

### 수정·신규 파일 목록

| 경로 | 종류 | 내용 |
|------|------|------|
| `TravelCalculator/Assets.xcassets/AppIcon.appiconset/Contents.json` | 수정 | iOS universal 1024 Any/Dark/Tinted 3엔트리. Mac 슬롯 13개 전부 제거. 각 엔트리에 `filename` 부여. |
| `TravelCalculator/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark-1024.png` | 신규 (cp) | 가이드 §3a swap — `Any` 슬롯 |
| `TravelCalculator/Assets.xcassets/AppIcon.appiconset/AppIcon-Light-1024.png` | 신규 (cp) | `Dark` 슬롯 |
| `TravelCalculator/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted-1024.png` | 신규 (cp) | `Tinted` 슬롯 |
| `TravelCalculator/Assets.xcassets/BrandSplashBG.colorset/Contents.json` | 신규 | Light/Dark sRGB 컴포넌트 |
| `TravelCalculator/Assets.xcassets/SplashCenter.imageset/Contents.json` | 신규 | Any + luminosity:dark, filename 2종 |
| `TravelCalculator/Assets.xcassets/SplashCenter.imageset/SplashCenter-Light.png` | 신규 (cp) | Any |
| `TravelCalculator/Assets.xcassets/SplashCenter.imageset/SplashCenter-Dark.png` | 신규 (cp) | Dark |
| `TravelCalculatorTests/Assets/AssetCatalogIntegrationTests.swift` | 신규 | Bundle Resource 테스트 (Red→Yellow→Green) |

### Asset Catalog 파일 내용

#### `AppIcon.appiconset/Contents.json` (수정 후)

```json
{
  "images" : [
    { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024",
      "filename" : "AppIcon-Dark-1024.png" },
    { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024",
      "filename" : "AppIcon-Light-1024.png",
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ] },
    { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024",
      "filename" : "AppIcon-Tinted-1024.png",
      "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ] }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

#### `BrandSplashBG.colorset/Contents.json` (신규)

```json
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "0.357", "green" : "0.659", "blue" : "0.925", "alpha" : "1.000" }
      }
    },
    {
      "idiom" : "universal",
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "color" : {
        "color-space" : "srgb",
        "components" : { "red" : "0.118", "green" : "0.165", "blue" : "0.220", "alpha" : "1.000" }
      }
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

#### `SplashCenter.imageset/Contents.json` (신규)

```json
{
  "images" : [
    { "idiom" : "universal", "filename" : "SplashCenter-Light.png" },
    { "idiom" : "universal", "filename" : "SplashCenter-Dark.png",
      "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ] }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

### 테스트 (Red → Yellow → Green) — Codex 권고 반영 후

> Codex 권고로 `bundle` computed property 삭제(`.let`은 Swift 표준 아님 — 컴파일 위험), `UIImage(named: "AppIcon")` 런타임 검증 삭제, AppIcon은 source-layout 테스트로 교체. 테스트 3건 = (1) BrandSplashBG runtime + (2) SplashCenter runtime + (3) AppIcon source-layout.

#### Red 단계 (수정 후)

```swift
// TravelCalculatorTests/Assets/AssetCatalogIntegrationTests.swift
import XCTest
import UIKit
@testable import TravelCalculator

final class AssetCatalogIntegrationTests: XCTestCase {

    // Runtime — colorset 등록/이름 회귀
    func test_brandSplashBG_loadsFromHostAppBundle() {
        XCTAssertNotNil(
            UIColor(named: "BrandSplashBG", in: Bundle.main, compatibleWith: nil),
            "BrandSplashBG colorset must be registered in Assets.xcassets"
        )
    }

    // Runtime — imageset 등록/이름 회귀
    func test_splashCenter_loadsFromHostAppBundle() {
        XCTAssertNotNil(
            UIImage(named: "SplashCenter", in: Bundle.main, compatibleWith: nil),
            "SplashCenter imageset must be registered in Assets.xcassets"
        )
    }

    // Source-layout — AppIcon Contents.json 구조 회귀 (Mac 슬롯 재유입 방지)
    func test_appIconContents_hasExactlyThreeIOSEntries() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // Assets/
            .deletingLastPathComponent()  // TravelCalculatorTests/
            .deletingLastPathComponent()  // repo root
        let appiconset = projectRoot
            .appendingPathComponent("TravelCalculator/Assets.xcassets/AppIcon.appiconset")
        let contentsURL = appiconset.appendingPathComponent("Contents.json")
        let data = try Data(contentsOf: contentsURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let images = json?["images"] as? [[String: Any]] ?? []

        XCTAssertEqual(images.count, 3, "AppIcon must have exactly 3 iOS variants (Any/Dark/Tinted)")

        // 모든 엔트리가 idiom=universal + platform=ios + filename 부여
        for entry in images {
            XCTAssertEqual(entry["idiom"] as? String, "universal")
            XCTAssertEqual(entry["platform"] as? String, "ios")
            XCTAssertNotNil(entry["filename"] as? String, "Each entry must have filename")
        }

        // appearance 분기 — Any 1, Dark 1, Tinted 1
        let appearances: [String?] = images.map { entry in
            (entry["appearances"] as? [[String: String]])?.first?["value"]
        }
        XCTAssertEqual(Set(appearances), Set([nil, "dark", "tinted"]),
                       "AppIcon must have exactly Any/Dark/Tinted appearances")

        // 파일명에 해당하는 PNG 실제 존재
        for entry in images {
            let filename = entry["filename"] as! String
            let pngURL = appiconset.appendingPathComponent(filename)
            XCTAssertTrue(FileManager.default.fileExists(atPath: pngURL.path),
                          "PNG \(filename) must exist in AppIcon.appiconset/")
        }
    }
}
```

**Red 검증**: 테스트 작성 시점에 Asset Catalog는 변경 전 → 3건 모두 fail 기대.
- `BrandSplashBG` colorset 미존재 → `UIColor(named:)` nil → fail
- `SplashCenter` imageset 미존재 → `UIImage(named:)` nil → fail
- `AppIcon.appiconset/Contents.json`은 현재 Mac 슬롯 13 + iOS 슬롯 3 = 16엔트리(filename 0건) → `images.count == 3` assertion fail

#### Yellow 단계

위 §"Asset Catalog 파일 내용" 3개 Contents.json + 5개 PNG cp 적용. 테스트 3건 pass 기대.

#### Green 단계

- 테스트 메시지 다듬기, 변수명 정리
- 빌드 warning 0 확인
- (Codex 권고) Red 섹션의 build-product/CFBundleIcons 추정 코멘트가 본문에 남아있지 않은지 점검

### 실행 순서

1. **Red**: `AssetCatalogIntegrationTests.swift` 작성 → `xcodebuild test` 실행 → 3 fail 확인
2. **Yellow**:
   - `cp /Users/SONJIYONG/tripy-appstore/dist/appstore/AppIcon-{Dark,Light,Tinted}-1024.png TravelCalculator/Assets.xcassets/AppIcon.appiconset/`
   - `mkdir -p TravelCalculator/Assets.xcassets/{BrandSplashBG.colorset,SplashCenter.imageset}`
   - `cp .../launch-screen/SplashCenter-{Light,Dark}.png TravelCalculator/Assets.xcassets/SplashCenter.imageset/`
   - 3 Contents.json 작성·교체
   - `xcodebuild test` → 3 pass
3. **Green**: 테스트 코드 정리, 빌드 warning 0 확인

### 검증 항목 (Step 4 빌드 검증과 분리)

- [ ] `xcodebuild ... build` warning 0, error 0
- [ ] `xcodebuild ... test -only-testing:TravelCalculatorTests/AssetCatalogIntegrationTests` 3건 pass
- [ ] `Assets.xcassets/AppIcon.appiconset/` 안에 PNG 3개 + 수정된 Contents.json 존재
- [ ] `Assets.xcassets/BrandSplashBG.colorset/Contents.json` 존재 (Mac 슬롯 0건 확인용)
- [ ] `Assets.xcassets/SplashCenter.imageset/` 안에 PNG 2개 + Contents.json 존재
- [ ] `git diff TravelCalculator.xcodeproj/project.pbxproj` 가 빈 출력 (auto-discovery 검증)

### Codex 권고로 Step 4(빌드 검증)에 이월된 시각 확인 항목

- (Step 4) Springboard에 설치된 아이콘이 **Light / Dark / Tinted** 3 모드에서 가독·정합 — Apple HIG 권고와 비교해 sky gradient 불투명 배경의 Dark 모드 적합성을 의도적 브랜드 예외로 수용
- (Step 4) `AppIcon-Tinted-1024.png` 원본이 monochrome/grayscale 처리되어 시스템 tint 적용에 적합한지 시각 확인

### Mac Catalyst 향후 고려 (Codex 권고)

향후 Mac Catalyst 또는 macOS target을 도입할 경우 해당 시점에 platform-specific AppIcon 구성을 별도로 재생성한다. 현재는 Mac idiom 슬롯 13개 모두 제거.

### 범위 외 (Step 2/3로 이월)

- `Info.plist` `UILaunchScreen` 키 변경 — Step 2
- Spec-UI §6.4/§6.5 신설 — Step 3
- 시뮬레이터 부팅 시각 확인 — Step 4 (Step 2 완료 후 의미 있음)

## Codex Review

> 실행: `codex exec` 직접 호출 (codex-cli 0.118.0, model gpt-5.4, reasoning effort high), 2026-04-30 15:35.
> Session: `019ddd1b-f567-7450-8948-cf4dd075b964`

### 항목별 평가

| # | 항목 | 평가 | 반영 |
|---|------|------|------|
| 1 | iOS 17 호환성 | 수정 권고 | 반영 — plan/Phase 문서의 "iOS 17+" 전제는 부정확. 실제 `IPHONEOS_DEPLOYMENT_TARGET=18.0` (`project.pbxproj:398`). Tinted variant는 iOS 18 target이라 호환성 이슈 자체 없음. CLAUDE.md/Spec 정정은 Phase G 범위 외(별도 task) — 본 plan에는 정정 1줄만 추가 |
| 2 | §3a swap 규칙 | 수정 권고 | 반영 — Apple HIG는 dark icon에 시스템 배경 노출/과한 밝기 자제 권장. sky gradient 불투명 배경은 "브랜드 우선 의도적 예외"로 간주. Step 4 시각 검증에 (a) Default/Dark/Tinted 모드 시각 확인, (b) Tinted 원본 grayscale 여부 확인 항목 추가 |
| 3 | Bundle Resource 테스트 | 수정 권고 | 반영 — `bundle` computed 삭제. `Bundle.main` 직접 사용. plan 코드의 `.let`은 Swift 표준 아님(컴파일 리스크) → 제거 |
| 4 | AppIcon UIImage 테스트 | 수정 권고 (강함) | 반영 (균형안) — `test_appIcon_hasNonEmptyVariants` 삭제. 대신 source-layout 테스트(`AppIcon.appiconset/Contents.json` 직접 파싱: images 3엔트리, Any/Dark/Tinted appearance, filename별 PNG 실재) 신규. Mac 슬롯 회귀까지 동시 안전망 |
| 5 | Mac 슬롯 13개 제거 | OK | 반영 — `SUPPORTED_PLATFORMS=iphoneos*`, `SUPPORTS_MACCATALYST=NO`, `TARGETED_DEVICE_FAMILY=1` 확인. plan §결정 기록에 "Mac Catalyst/macOS target 도입 시점에 platform-specific AppIcon 구성 재생성" 1줄 추가 |
| 6 | Anti Over-Engineering | 수정 권고 | 반영 — `bundle` helper 삭제, `CFBundleIcons`/`derivedIcon` 추정 코멘트 삭제, 테스트 3건(runtime 2 + source-layout 1) 균형안 채택 |

### 수정 이전과 이후 핵심 변화

| 항목 | 이전 | 이후 |
|------|------|------|
| 테스트 헬퍼 | `bundle` computed (`.let` 비표준) | 삭제, `Bundle.main` 직접 |
| AppIcon 검증 | `UIImage(named: "AppIcon")` 런타임 | Contents.json 파싱 + PNG 파일 존재 검증 |
| 문서 전제 | iOS 17+ | iOS 18 (실제 build setting) |
| swap 명시 | "더 가독" 정도 | "브랜드 의도적 예외" + 시각 검증 의무 |

### 참고 소스 (Codex 인용)

- Apple Xcode docs, "Configuring your app icon using an asset catalog" — https://developer.apple.com/documentation/xcode/configuring-your-app-icon
- Apple HIG, "App icons" — https://developer.apple.com/design/human-interface-guidelines/app-icons
- `CFBundleIcons` / `CFBundlePrimaryIcon` — https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleicons
- `UIImage(named:)` — https://developer.apple.com/documentation/uikit/uiimage/init(named:)

### Phase G 범위 외 발견 (별도 task 후보)

- **CLAUDE.md / Spec-Architecture의 "iOS 17+" 표기 부정확** — 실제 `IPHONEOS_DEPLOYMENT_TARGET=18.0`. 단순 문서 정정이라 Phase G 종료 후 별도로 처리.

### Anti Over-Engineering 체크리스트 (Codex 검증 후)

- [x] 1회성 추상화 제거 — `bundle` computed 삭제
- [x] 헬퍼 인라인 — `Bundle.main` 직접 사용
- [x] 요청 범위 밖 기능 없음 — Step 2(Info.plist) / Step 3(Spec-UI) 분리 유지
- [x] MVI 패턴 충돌 N/A — Asset Catalog 작업
- [x] @MainActor/Sendable N/A — XCTest 기본
- [x] Decimal N/A — 금액 연산 없음

## TDD 사이클 로그

### Red — 2026-04-30 15:51

`TravelCalculatorTests/Assets/AssetCatalogIntegrationTests.swift` 작성 (Swift Testing 프레임워크 — 프로젝트가 XCTest 0건, 100% Swift Testing 사용 중. plan의 XCTest 코드를 `@Test` / `#expect`로 변환).

테스트 3건 모두 fail 확인:
- `brandSplashBG_loadsFromHostAppBundle()` — colorset 미존재
- `splashCenter_loadsFromHostAppBundle()` — imageset 미존재
- `appIconContents_hasExactlyThreeIOSEntries()` — Mac 슬롯 13 + iOS 3 = 16 entries (3과 불일치)

부수 발견: 빌드 출력에서 `--minimum-deployment-target 18.0` 확인 — Codex의 iOS 18 발견 재검증.

### Yellow — 2026-04-30 15:53

PNG 5장 cp + Contents.json 3개 작성:
- `AppIcon.appiconset/` ← `AppIcon-{Dark,Light,Tinted}-1024.png` + Mac 슬롯 13개 제거된 신규 Contents.json
- `BrandSplashBG.colorset/Contents.json` (신규)
- `SplashCenter.imageset/` ← `SplashCenter-{Light,Dark}.png` + Contents.json (신규)

테스트 3건 모두 pass.

### Green — 2026-04-30 15:54

- `xcodebuild build` — `BUILD SUCCEEDED`. 무관 경고 1건(`appintentsmetadataprocessor: No AppIntents.framework dependency found` — 항상 출력)
- `git diff TravelCalculator.xcodeproj/project.pbxproj` 출력 없음 — fileSystemSynchronizedGroups auto-discovery 정상 작동
- 테스트 코드 추가 정리 불필요 — Codex 권고대로 단순화된 상태로 작성됨

## 팀 검증 반영

> 사용자 결정 2026-04-30: "MEDIUM 전부 + V2 백로그 분리". HIGH H1은 V1+ TestFlight 전 게이트로 별도 관리.

### 적용 — MEDIUM 4건 (테스트 파일 리팩터)

- **M1 (Simplify)**: `Self.repoRoot` static computed 1회 사용 → `appIconContents_hasExactlyThreeIOSEntries` 본문에 인라인.
- **M2 (Simplify)**: `Set<String?>` 비교 → `compactMap`으로 dark/tinted 추출 후 `sorted() == ["dark", "tinted"]` 비교. Mac 슬롯 회귀 의도(엔트리 정확히 3개) 유지.
- **M3 (Convention)**: 단일 struct에 분류축 MARK 2개 → `AssetCatalogRuntimeTests` / `AppIconContentsTests` 2 struct로 분리. `ExchangeRateConversionTests.swift` / `AppCurrencyStoreTests.swift`의 멀티-struct 패턴 정합.
- **M4 (Convention C2 + Simplify L4)**: `guard let filename ... continue` silent skip 제거 → `try #require(entry["filename"] as? String)` 사용 + 첫 loop와 통합(1회 패스).
- **M5 (UX)**: Step 4 검증에 Dark 모드 시각 항목은 Codex 권고로 plan §"Codex 권고로 Step 4(빌드 검증)에 이월된 시각 확인 항목"에 이미 추가됨 — 재확인 완료.

검증: 리팩터 후 `xcodebuild test -only-testing:.../AssetCatalogRuntimeTests -only-testing:.../AppIconContentsTests` → 3건 모두 pass, 회귀 없음.

### V2 백로그 분리 (Spec-Tasks §9 추가)

- **Phase G UX / High** — AppIcon Tinted variant grayscale L* 재export (V1+ TestFlight 전)
- **Phase G UX / Low (조건부)** — `BrandNavy` / `BrandSky` 색 토큰 — in-app UI가 launch screen 외 브랜드 색 채택 시 활성
- **Phase G UX / Low** — 런치 스크린 접근성 (Reduce Transparency / Increase Contrast)

### HIGH H1 메모

`AppIcon-Tinted-1024.png` RGB → grayscale 재export는 V1+ TestFlight **진입 전** 게이트.
- `docs/phase-g.md` §결정 기록에 1줄 명시
- `specs/Spec-Tasks.md §9` Phase G UX / High 항목으로 등록

### LOW 무시 사유

- Simplify L1 (MARK 위치): 현재 멀티-struct 분리로 자연스럽게 해소.
- Simplify L2 (sRGB 4자리 정밀도): 1/255 이내라 hex-exact과 차이 없음. 가이드 표 그대로 3자리 유지.
- Convention LOW (인라인 주석 WHY로 다듬기): 리팩터된 `appIconContents_hasExactlyThreeIOSEntries` 본문에 WHY 주석 1줄 추가하여 부분 반영.
