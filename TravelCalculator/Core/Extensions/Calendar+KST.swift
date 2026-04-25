import Foundation

extension TimeZone {
    nonisolated static let kst = TimeZone(identifier: "Asia/Seoul")!
}

extension Calendar {
    nonisolated static let kst: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .kst
        return cal
    }()
}

extension Date {
    nonisolated func yyyyMMddKST() -> String {
        let c = Calendar.kst.dateComponents([.year, .month, .day], from: self)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    nonisolated func yyyyMMddHHmmKST() -> String {
        let c = Calendar.kst.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return String(
            format: "%04d-%02d-%02d %02d:%02d KST",
            c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0
        )
    }

    nonisolated static func fromYYYYMMDDKST(_ string: String) -> Date? {
        guard string.count == 8,
              let year = Int(string.prefix(4)),
              let month = Int(string.dropFirst(4).prefix(2)),
              let day = Int(string.suffix(2)) else { return nil }
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return Calendar.kst.date(from: comps)
    }
}
