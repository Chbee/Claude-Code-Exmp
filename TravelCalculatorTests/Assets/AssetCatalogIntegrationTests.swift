import Testing
import Foundation
import UIKit
@testable import TravelCalculator

struct AssetCatalogRuntimeTests {

    @Test func brandSplashBG_loadsFromHostAppBundle() {
        #expect(
            UIColor(named: "BrandSplashBG", in: .main, compatibleWith: nil) != nil,
            "BrandSplashBG colorset must be registered in Assets.xcassets"
        )
    }

    @Test func splashCenter_loadsFromHostAppBundle() {
        #expect(
            UIImage(named: "SplashCenter", in: .main, compatibleWith: nil) != nil,
            "SplashCenter imageset must be registered in Assets.xcassets"
        )
    }
}

struct AppIconContentsTests {

    // 테스트 번들 경로가 아닌 source root에서 Asset Catalog Contents.json을 직접 파싱.
    // actool이 일부 metadata를 elide할 수 있어 source-of-truth는 원본 JSON.
    @Test func appIconContents_hasExactlyThreeIOSEntries() throws {
        let appiconset = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("TravelCalculator/Assets.xcassets/AppIcon.appiconset")
        let contentsURL = appiconset.appendingPathComponent("Contents.json")

        let data = try Data(contentsOf: contentsURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let images = json?["images"] as? [[String: Any]] ?? []

        #expect(images.count == 3, "AppIcon must have exactly 3 iOS variants (Mac slots must stay removed)")

        for entry in images {
            #expect(entry["idiom"] as? String == "universal")
            #expect(entry["platform"] as? String == "ios")
            let filename = try #require(entry["filename"] as? String, "Each entry must have filename")
            let pngURL = appiconset.appendingPathComponent(filename)
            #expect(FileManager.default.fileExists(atPath: pngURL.path),
                    "PNG \(filename) must exist in AppIcon.appiconset/")
        }

        let appearances = images.compactMap { entry in
            (entry["appearances"] as? [[String: String]])?.first?["value"]
        }
        #expect(appearances.sorted() == ["dark", "tinted"],
                "AppIcon must have one Any (no appearances) + one Dark + one Tinted variant")
    }
}
