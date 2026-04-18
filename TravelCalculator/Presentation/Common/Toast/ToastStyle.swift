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
        case .success: .toastSuccessTint
        case .info:    .toastInfoTint
        case .warning: .toastWarningTint
        case .error:   .toastErrorTint
        }
    }

    var iconAssetName: String {
        switch self {
        case .success: "ToastSuccess"
        case .info:    "ToastInfo"
        case .warning: "ToastWarning"
        case .error:   "ToastError"
        }
    }
}
