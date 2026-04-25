import Testing
import Foundation
@testable import TravelCalculator

@MainActor
private func makeUSDtoKRW(display: String, rate: Decimal = 1350) -> CalculatorDisplayModel {
    var s = CalculatorState()
    s.display = display
    return CalculatorDisplayModel.make(
        state: s,
        inputCurrency: .USD, outputCurrency: .KRW, selectedCurrency: .USD,
        exchangeRate: rate, isInputKRW: false
    )
}

@MainActor
private func makeKRWtoUSD(display: String, rate: Decimal = 1350) -> CalculatorDisplayModel {
    var s = CalculatorState()
    s.display = display
    return CalculatorDisplayModel.make(
        state: s,
        inputCurrency: .KRW, outputCurrency: .USD, selectedCurrency: .USD,
        exchangeRate: rate, isInputKRW: true
    )
}

// MARK: - 변환

@MainActor
struct ExchangeRateConversionTests {
    @Test func conversion_USDtoKRW_appliesRate() {
        let model = makeUSDtoKRW(display: "100")
        #expect(model.resultDisplay.rawAmount == "135000")
        #expect(model.resultDisplay.formattedAmount == "135,000")
    }

    @Test func conversion_KRWtoUSD_dividesByRate() {
        let model = makeKRWtoUSD(display: "135000")
        #expect(model.resultDisplay.rawAmount == "100")
        #expect(model.resultDisplay.formattedAmount == "100.00")
    }

    @Test func conversion_TWD_appliesRate() {
        var s = CalculatorState()
        s.display = "1000"
        let model = CalculatorDisplayModel.make(
            state: s,
            inputCurrency: .TWD, outputCurrency: .KRW, selectedCurrency: .TWD,
            exchangeRate: Decimal(string: "42.5")!, isInputKRW: false
        )
        #expect(model.resultDisplay.rawAmount == "42500")
    }

    @Test func conversion_zeroDisplay_USDtoKRW_showsBothZeros() {
        let model = makeUSDtoKRW(display: "0")
        #expect(model.inputDisplay.formattedAmount == "0.00")
        #expect(model.resultDisplay.formattedAmount == "0")
    }

    @Test func conversion_zeroDisplay_KRWtoUSD_showsBothZeros() {
        let model = makeKRWtoUSD(display: "0")
        #expect(model.inputDisplay.formattedAmount == "0")
        #expect(model.resultDisplay.formattedAmount == "0.00")
    }

    @Test func conversion_KRWtoTWD_appliesTWDFractionDigits() {
        var s = CalculatorState()
        s.display = "100"
        let model = CalculatorDisplayModel.make(
            state: s,
            inputCurrency: .KRW, outputCurrency: .TWD, selectedCurrency: .TWD,
            exchangeRate: Decimal(string: "42.5")!, isInputKRW: true
        )
        #expect(model.resultDisplay.formattedAmount == "2.35")
    }

    @Test func conversion_decimalInput_preservesPrecision() {
        let model = makeUSDtoKRW(display: "1.5")
        #expect(model.resultDisplay.rawAmount == "2025")
    }

    @Test func conversion_KRWoutput_dropsFractionDigits() {
        let model = makeUSDtoKRW(display: "1.7")
        #expect(model.resultDisplay.formattedAmount == "2,295")
    }

    @Test func conversion_USDoutput_keepsTwoFractionDigits() {
        let model = makeKRWtoUSD(display: "100")
        #expect(model.resultDisplay.formattedAmount == "0.07")
    }

    @Test func conversion_negativeInput_returnsZero() {
        let model = makeUSDtoKRW(display: "-2")
        #expect(model.resultDisplay.rawAmount == "0")
        #expect(model.resultDisplay.formattedAmount == "0")
    }

    @Test func conversion_zeroExchangeRate_returnsZero_forKRWInput() {
        let model = makeKRWtoUSD(display: "100", rate: 0)
        #expect(model.resultDisplay.rawAmount == "0")
    }

    @Test func rateDisplay_formatsRate_withCurrencyUnit() {
        let model = makeUSDtoKRW(display: "0", rate: Decimal(string: "1350.45")!)
        #expect(model.rateDisplay == "1 USD = 1,350.45 KRW")
    }
}

// MARK: - 방향 전환 Reducer

@MainActor
struct DirectionTogglePressedTests {
    @Test func directionToggle_movesValueIntoDisplay() {
        let s = CalculatorReducer.reduce(CalculatorState(), intent: .directionTogglePressed("135000"))
        #expect(s.display == "135000")
    }

    @Test func directionToggle_resetsCalculationContext() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        s = CalculatorReducer.reduce(s, intent: .directionTogglePressed("8"))
        #expect(s.previousValue == nil)
        #expect(s.pendingOperator == nil)
        #expect(s.lastOperator == nil)
        #expect(s.lastOperand == nil)
        #expect(s.isEnteringNewNumber == true)
    }

    @Test func directionToggle_acceptsValueOver10Digits() {
        let s = CalculatorReducer.reduce(CalculatorState(), intent: .directionTogglePressed("12345678901"))
        #expect(s.display == "12345678901")
    }
}

// MARK: - 통화 변경 리셋 Reducer

@MainActor
struct ResetForCurrencyChangeTests {
    @Test func resetForCurrencyChange_clearsAllState() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(3))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.plus))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        s = CalculatorReducer.reduce(s, intent: .resetForCurrencyChange)
        #expect(s.display == "0")
        #expect(s.previousValue == nil)
        #expect(s.pendingOperator == nil)
        #expect(s.lastOperator == nil)
        #expect(s.lastOperand == nil)
        #expect(s.isEnteringNewNumber == true)
    }

    @Test func resetForCurrencyChange_clearsPendingToast() {
        var s = CalculatorReducer.reduce(CalculatorState(), intent: .numberPressed(5))
        s = CalculatorReducer.reduce(s, intent: .operatorPressed(.divide))
        s = CalculatorReducer.reduce(s, intent: .numberPressed(0))
        s = CalculatorReducer.reduce(s, intent: .equalsPressed)
        #expect(s.pendingToast != nil)
        s = CalculatorReducer.reduce(s, intent: .resetForCurrencyChange)
        #expect(s.pendingToast == nil)
    }
}
