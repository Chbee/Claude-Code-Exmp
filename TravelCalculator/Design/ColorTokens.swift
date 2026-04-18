import SwiftUI

// MARK: - ColorPair

struct ColorPair: Sendable {
    let light: UInt32
    let dark: UInt32

    var adaptive: Color {
        Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hex: self.dark) : UIColor(hex: self.light) })
    }
}

// MARK: - Raw Palette
// Figma 원본값 — 업데이트 시 이 파일의 hex 값만 교체
// 출처: https://www.figma.com/design/RHAP7WVgoX220lRhWseaWE/여행가계부 (node-id=99-875)

extension Color {

    enum Main {
        static let c100 = ColorPair(light: 0xD0EFFC, dark: 0x133476)
        static let c200 = ColorPair(light: 0xA2DBFA, dark: 0x1F4B8E)
        static let c300 = ColorPair(light: 0x71BEF1, dark: 0x326AB1)
        static let c400 = ColorPair(light: 0x4DA0E3, dark: 0x498ED3)
        static let c500 = ColorPair(light: 0x1976D2, dark: 0x64B5F6)
        static let c600 = ColorPair(light: 0x125BB4, dark: 0x8ACEF9)
        static let c700 = ColorPair(light: 0x0C4497, dark: 0xA2DEFC)
        static let c800 = ColorPair(light: 0x073079, dark: 0xC1EDFE)
        static let c900 = ColorPair(light: 0x042164, dark: 0xE0F7FE)
    }

    enum System {
        static let blue500   = ColorPair(light: 0x2578FC, dark: 0x1E88E5)
        static let green500  = ColorPair(light: 0x4EC427, dark: 0x89C413)
        static let yellow500 = ColorPair(light: 0xFFAA00, dark: 0xFFD70F)
        static let red500    = ColorPair(light: 0xFF4130, dark: 0xFF5735)
    }

    enum Side {
        static let background = ColorPair(light: 0xF5F7FA, dark: 0x121A26)
        static let card       = ColorPair(light: 0xFFFFFF, dark: 0x1E2A38)
        static let baseText   = ColorPair(light: 0x0D1B2A, dark: 0xE3EAF2)
        static let subText    = ColorPair(light: 0x475A78, dark: 0xA0AEC0)
        static let accent     = ColorPair(light: 0xFFC107, dark: 0xFFCA28)
        static let check      = ColorPair(light: 0x10B981, dark: 0x34D399)
    }

    enum Toast {
        static let successTint = ColorPair(light: 0x10B981, dark: 0x34D399)
        static let errorTint   = ColorPair(light: 0xEF4444, dark: 0xF87171)
        static let warningTint = ColorPair(light: 0xF59E0B, dark: 0xFBBF24)
        static let infoTint    = ColorPair(light: 0x475569, dark: 0x475569)
        static let background  = ColorPair(light: 0xF2F2F7, dark: 0x1C1C1E)
        static let messageText = ColorPair(light: 0x1E293B, dark: 0xFFFFFF)
    }

    enum Gray {
        static let c050 = ColorPair(light: 0xF5F5F5, dark: 0x1A1A1A)
        static let c100 = ColorPair(light: 0xDDDDDD, dark: 0x202020)
        static let c200 = ColorPair(light: 0xC5C5C5, dark: 0x363636)
        static let c300 = ColorPair(light: 0xADADAD, dark: 0x5F5F5F)
        static let c400 = ColorPair(light: 0x959595, dark: 0x767676)
        static let c500 = ColorPair(light: 0x7D7D7D, dark: 0x8E8E8E)
        static let c600 = ColorPair(light: 0x656565, dark: 0xA4A4A4)
        static let c700 = ColorPair(light: 0x404040, dark: 0xBDBDBD)
        static let c800 = ColorPair(light: 0x2E2E2E, dark: 0xC7C7C7)
        static let c900 = ColorPair(light: 0x202020, dark: 0xDEDEDE)
    }
}

// MARK: - Hex Initializer

private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8)  & 0xFF) / 255
        let b = CGFloat(hex         & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
