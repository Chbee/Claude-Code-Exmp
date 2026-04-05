import Foundation
import SwiftUI

enum ToastStyle: Sendable, CaseIterable {
    case success
    case info
    case warning
    case error

    var duration: TimeInterval {
        switch self {
        case .success: 1.5
        case .info:    2.0
        case .warning: 2.5
        case .error:   3.0
        }
    }

    var tintColor: Color {
        switch self {
        case .success: .appSuccess
        case .info:    .appInfo
        case .warning: .appWarning
        case .error:   .appError
        }
    }

    var iconName: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .info:    "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error:   "xmark.octagon.fill"
        }
    }
}
