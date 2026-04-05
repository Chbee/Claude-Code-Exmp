import Foundation

enum Operator: String, CaseIterable, Sendable {
    case plus
    case minus
    case multiply
    case divide

    func apply(_ lhs: Decimal, _ rhs: Decimal) -> Decimal? {
        switch self {
        case .plus:
            let result: Decimal = lhs + rhs
            return result
        case .minus:
            let result: Decimal = lhs - rhs
            return result
        case .multiply:
            let result: Decimal = lhs * rhs
            return result
        case .divide:
            guard rhs != 0 else { return nil }
            let result: Decimal = lhs / rhs
            return result
        }
    }
}
