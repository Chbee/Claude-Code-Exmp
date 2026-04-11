import Foundation

struct CalculatorState {
    var display: String = "0"
    var pendingOperator: Operator?
    var isEnteringNewNumber: Bool = true
    var previousValue: Decimal?
    var lastOperand: Decimal?
    var lastOperator: Operator?
    var pendingToast: ToastPayload?

    // AC/C 토글: display="0"이고 pendingOperator=nil일 때 AC 표시
    var showAllClear: Bool {
        display == "0" && pendingOperator == nil
    }
}
