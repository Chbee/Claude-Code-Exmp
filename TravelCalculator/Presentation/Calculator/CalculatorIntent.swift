import Foundation

enum CalculatorIntent {
    case numberPressed(Int)
    case operatorPressed(Operator)
    case equalsPressed
    case decimalPressed
    case clearPressed
    case allClearPressed
    case backspacePressed
    case resetInputLimitFlag
    case resetForCurrencyChange
}
