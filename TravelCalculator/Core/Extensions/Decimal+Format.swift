import Foundation

extension Decimal {
    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.decimalSeparator = "."
        f.groupingSeparator = ","
        f.usesGroupingSeparator = true
        return f
    }()

    func formatDecimal(maxFractionDigits: Int, minimumFractionDigits: Int = 0) -> String {
        let formatter = Self.decimalFormatter.copy() as! NumberFormatter
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        return formatter.string(from: self as NSDecimalNumber)
            ?? (self as NSDecimalNumber).stringValue
    }
}
