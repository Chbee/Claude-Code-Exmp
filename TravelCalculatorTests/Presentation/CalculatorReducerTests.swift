import Testing
import Foundation
@testable import TravelCalculator

@MainActor
private func makeThreePlusFiveEquals() -> CalculatorState {
    var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
    s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
    s = CalculatorReducer.reduce(s, intent: .numberPressed(5))
    s = CalculatorReducer.reduce(s, intent: .equalsPressed)
    return s
}

// MARK: - numberPressed

@MainActor
struct CalculatorReducerNumberTests {
    @Test func numberPressed_replacesZero_whenInitialState() {
        let s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(7))
        #expect(s.display == "7")
        #expect(s.isEnteringNewNumber == false)
    }

    @Test func numberPressed_ignoresZero_whenDisplayIsZero() {
        let s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(0))
        #expect(s.display == "0")
    }

    @Test func numberPressed_appendsDigit_whenEnteringNumber() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(1))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(2))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(3))
        #expect(s.display == "123")
    }

    @Test func numberPressed_blocksDigit_whenFractionDigitsAt2() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(1))
        s = CalculatorReducer.reduce(s, intent: .decimalPressed)
        s = CalculatorReducer.reduce(s, intent: .numberPressed(2))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(3))
        #expect(s.display == "1.23")
        let next = CalculatorReducer.reduce(s, intent: .numberPressed(4))
        #expect(next.display == "1.23")
    }
}

// MARK: - operatorPressed + equalsPressed (basic)

@MainActor
struct CalculatorReducerOperatorTests {
    @Test func operatorPressed_storesPreviousValue_onFirstOperator() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        #expect(s.previousValue == Decimal(3))
        #expect(s.pendingOperator == .plus)
        #expect(s.isEnteringNewNumber == true)
        #expect(s.display == "3")
    }

    @Test func operatorPressed_replacesOperator_whenConsecutive() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.multiply))
        #expect(s.pendingOperator == .multiply)
        #expect(s.previousValue == Decimal(3))
    }

    @Test func operatorPressed_executesIntermediate_whenSecondOperand() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        #expect(s.display == "8")
        #expect(s.previousValue == Decimal(8))
        #expect(s.pendingOperator == .plus)
    }

    @Test func equalsPressed_computesResult_whenOperandComplete() {
        let s = makeThreePlusFiveEquals()
        #expect(s.display == "8")
        #expect(s.pendingOperator == nil)
        #expect(s.lastOperator == .plus)
        #expect(s.lastOperand == Decimal(5))
    }

    @Test func operatorPressed_clearsLastOperator_afterEquals() {
        var s = makeThreePlusFiveEquals()
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.multiply))
        #expect(s.lastOperator == nil)
        #expect(s.lastOperand == nil)
    }
}

// MARK: - decimalPressed

@MainActor
struct CalculatorReducerDecimalTests {
    @Test func decimalPressed_appendsDot_whenEnteringNumber() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .decimalPressed)
        #expect(s.display == "5.")
    }

    @Test func decimalPressed_completesZeroDot_whenNewNumber() {
        let s = CalculatorReducer.reduce(CalculatorState(), intent: .decimalPressed)
        #expect(s.display == "0.")
    }

    @Test func decimalPressed_ignored_whenAlreadyHasDot() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .decimalPressed)
        s = CalculatorReducer.reduce(s, intent: .decimalPressed)
        #expect(s.display == "5.")
    }
}

// MARK: - clearPressed / allClearPressed / backspacePressed

@MainActor
struct CalculatorReducerClearTests {
    @Test func clearPressed_resetsDisplayOnly_keepsPending() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .clearPressed)
        #expect(s.display == "0")
        #expect(s.pendingOperator == .plus)
        #expect(s.previousValue == Decimal(3))
    }

    @Test func clearPressed_returnsToAC_whenPendingNil() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .clearPressed)
        #expect(s.showAllClear == true)
    }

    @Test func clearPressed_preservesContext_continuesCalculation() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .clearPressed)
        s = CalculatorReducer.reduce(s, intent: .numberPressed(7))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "10")
    }

    @Test func allClearPressed_resetsAllState() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .allClearPressed)
        #expect(s.display == "0")
        #expect(s.pendingOperator == nil)
        #expect(s.previousValue == nil)
        #expect(s.lastOperator == nil)
        #expect(s.lastOperand == nil)
    }

    @Test func backspacePressed_dropsLastDigit_whenEnteringNumber() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(1))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(2))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .backspacePressed)
        #expect(s.display == "12")
    }

    @Test func backspacePressed_collapsesZeroDot_toZero() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .decimalPressed)
        #expect(s.display == "0.")
        s = CalculatorReducer.reduce(s, intent: .backspacePressed)
        #expect(s.display == "0")
    }

    @Test func backspacePressed_ignored_whenZero() {
        let s = CalculatorReducer.reduce(CalculatorState(), intent: .backspacePressed)
        #expect(s.display == "0")
    }

    @Test func backspacePressed_returnsZero_whenLastDigitRemoved() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .backspacePressed)
        #expect(s.display == "0")
    }

    @Test func backspacePressed_dropsLastDigit_afterEquals() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(1))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(2))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(1))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "25")
        s = CalculatorReducer.reduce(s, intent: .backspacePressed)
        #expect(s.display == "2")
    }
}

// MARK: - 엣지 케이스

@MainActor
struct CalculatorReducerEdgeTests {
    @Test func divideByZero_setsToast_keepsState() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.divide))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(0))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.pendingToast != nil)
        #expect(s.previousValue == Decimal(5))
        #expect(s.pendingOperator == .divide)
    }

    @Test func divideByZero_recoversWith_newOperandAndEquals() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.divide))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(0))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        s = CalculatorReducer.reduce(s, intent: .numberPressed(2))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "2.5")
        #expect(s.pendingToast == nil)
    }

    @Test func equalsRepeated_reusesLastOperand() {
        var s = makeThreePlusFiveEquals()
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "13")
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "18")
    }

    @Test func equalsRepeat_isBroken_afterBackspace() {
        var s = makeThreePlusFiveEquals()
        s = CalculatorReducer.reduce(s, intent: .backspacePressed)
        #expect(s.display == "0")
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "0")
    }

    @Test func equalsAfterEquals_thenOperator_continuesFromResult() {
        var s = makeThreePlusFiveEquals()
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.multiply))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(2))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "16")
    }

    @Test func operatorThenEquals_usesDisplayAsRhs() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "10")
    }

    @Test func equalsAlone_isIgnored_whenNoState() {
        let s = CalculatorReducer.reduce(CalculatorState(), intent: .equalsPressed)
        #expect(s.display == "0")
        #expect(s.pendingOperator == nil)
        #expect(s.lastOperator == nil)
    }

    @Test func numberPressed_startsFresh_afterEquals() {
        var s = makeThreePlusFiveEquals()
        s = CalculatorReducer.reduce(s, intent: .numberPressed(7))
        #expect(s.display == "7")
        #expect(s.previousValue == nil)
        #expect(s.pendingOperator == nil)
    }

    @Test func equalsPressed_allowsNegativeResult_whenSubtraction() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.minus))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.display == "-2")
    }
}

// MARK: - 자릿수 제한

@MainActor
struct CalculatorReducerLimitTests {
    private static func tenDigits() -> CalculatorState {
        var s = CalculatorState()
        for d in [1,2,3,4,5,6,7,8,9,0] {
            s = CalculatorReducer.reduce(s, intent: .numberPressed(d))
        }
        return s
    }

    @Test func numberPressed_blocked_whenIntegerDigitsAt10() {
        let s = Self.tenDigits()
        #expect(s.display == "1234567890")
        let next = CalculatorReducer.reduce(s, intent: .numberPressed(5))
        #expect(next.display == "1234567890")
        #expect(next.pendingToast != nil)
    }

    @Test func decimalPressed_blocked_whenIntegerDigitsAt10() {
        let s = Self.tenDigits()
        let next = CalculatorReducer.reduce(s, intent: .decimalPressed)
        #expect(next.display == "1234567890")
        #expect(next.pendingToast != nil)
    }

    @Test func operatorAndBackspace_workEvenAtLimit() {
        let s = Self.tenDigits()
        let afterOp = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        #expect(afterOp.pendingOperator == .plus)
        #expect(afterOp.previousValue == Decimal(string: "1234567890"))

        let afterBack = CalculatorReducer.reduce(s, intent: .backspacePressed)
        #expect(afterBack.display == "123456789")
    }

    @Test func equalsResult_setsToast_andKeepsDisplay_when15DigitOverflow() {
        var s = CalculatorState()
        for d in [9,9,9,9,9,9,9,9,9,9] {
            s = CalculatorReducer.reduce(s, intent: .numberPressed(d))
        }
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.multiply))
        for d in [9,9,9,9,9,9,9,9,9,9] {
            s = CalculatorReducer.reduce(s, intent: .numberPressed(d))
        }
        let before = s.display
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.pendingToast != nil)
        #expect(s.display == before)
    }
}
