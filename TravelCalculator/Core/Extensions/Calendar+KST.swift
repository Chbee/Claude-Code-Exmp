import Foundation

extension TimeZone {
    static let kst = TimeZone(identifier: "Asia/Seoul")!
}

extension Calendar {
    static let kst: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .kst
        return cal
    }()
}

extension Date {
    func yyyyMMddKST() -> String {
        Self.kstFormatter.string(from: self)
    }

    static func fromYYYYMMDDKST(_ string: String) -> Date? {
        kstFormatter.date(from: string)
    }

    private static let kstFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = .kst
        f.calendar = .kst
        return f
    }()
}
