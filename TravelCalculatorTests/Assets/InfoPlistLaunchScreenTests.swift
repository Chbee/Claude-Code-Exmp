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
