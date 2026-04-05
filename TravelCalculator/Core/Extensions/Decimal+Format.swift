import Foundation

extension Decimal {
    func formatDecimal(maxFractionDigits: Int, minimumFractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        let number = self as NSDecimalNumber
        return formatter.string(from: number) ?? number.stringValue
    }
}
