import SwiftUI

extension View {
    func previewWithColorSchemes() -> some View {
        ForEach(ColorScheme.allCases, id: \.self) { scheme in
            self
                .preferredColorScheme(scheme)
                .previewDisplayName(scheme == .light ? "Light" : "Dark")
        }
    }
}
