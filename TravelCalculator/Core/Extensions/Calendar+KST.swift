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
