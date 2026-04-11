import SwiftUI

// MARK: - Semantic Color Tokens
// View에서 Color.appPrimary 등으로 사용
// 팔레트 값이 바뀌면 ColorTokens.swift만 수정하면 됨

extension Color {

    // MARK: Brand
    static let appPrimary     = Main.c500.adaptive
    static let appPrimaryMild = Main.c100.adaptive

    // MARK: Surface
    static let appBackground = Side.background.adaptive
    static let appCard       = Side.card.adaptive

    // MARK: Text
    static let appTextPrimary = Side.baseText.adaptive
    static let appTextSub     = Side.subText.adaptive

    // MARK: Accent
    static let appAccent = Side.accent.adaptive

    // MARK: Utility
    static let appUtility = Gray.c200.adaptive

    // MARK: Status
    static let appSuccess = System.green500.adaptive
    static let appWarning = System.yellow500.adaptive
    static let appError   = System.red500.adaptive
    static let appInfo    = System.blue500.adaptive
}
