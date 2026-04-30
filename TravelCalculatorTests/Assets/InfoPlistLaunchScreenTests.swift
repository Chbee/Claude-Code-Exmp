import Testing
import Foundation
@testable import TravelCalculator

struct InfoPlistLaunchScreenTests {
    // 빌드 산출물이 아닌 source Info.plist를 직접 파싱 — Springboard가 부팅 시 직접 소비하므로 source가 곧 계약.
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

        #expect(launchScreen.count == 3,
                "UILaunchScreen must contain only the 3 expected keys (regression guard for unexpected key additions)")
    }
}
