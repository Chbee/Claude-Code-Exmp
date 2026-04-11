import Foundation

struct CurrencyAmountDisplayModel {
    let currencyCode: String
    let symbol: String
    let flag: String
    let formattedAmount: String
    let rawAmount: String
}

struct CalculatorDisplayModel {
    let inputDisplay: CurrencyAmountDisplayModel
    let resultDisplay: CurrencyAmountDisplayModel
    let rateDisplay: String
}

// MARK: - Factory

extension CalculatorDisplayModel {
    /// 현재 계산기 상태와 환율 정보로 DisplayModel 생성
    static func make(
        state: CalculatorState,
        inputCurrency: Currency,
        outputCurrency: Currency,
        selectedCurrency: Currency,
        exchangeRate: Decimal,
        isInputKRW: Bool = false
    ) -> CalculatorDisplayModel {
        let inputAmount = formatAmount(state.display, currency: inputCurrency)
        let convertedAmount = computeConvertedAmount(
            display: state.display,
            exchangeRate: exchangeRate,
            outputCurrency: outputCurrency,
            isInputKRW: isInputKRW
        )
        let outputAmount = formatAmount(convertedAmount, currency: outputCurrency)

        let rateDisplay = formatRateDisplay(
            selectedCurrency: selectedCurrency,
            exchangeRate: exchangeRate
        )

        return CalculatorDisplayModel(
            inputDisplay: CurrencyAmountDisplayModel(
                currencyCode: inputCurrency.currencyUnit,
                symbol: inputCurrency.symbol,
                flag: inputCurrency.flag,
                formattedAmount: inputAmount,
                rawAmount: state.display
            ),
            resultDisplay: CurrencyAmountDisplayModel(
                currencyCode: outputCurrency.currencyUnit,
                symbol: outputCurrency.symbol,
                flag: outputCurrency.flag,
                formattedAmount: outputAmount,
                rawAmount: convertedAmount
            ),
            rateDisplay: rateDisplay
        )
    }

    private static func formatRateDisplay(
        selectedCurrency: Currency,
        exchangeRate: Decimal
    ) -> String {
        var value = exchangeRate
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        let formatted = rounded.formatDecimal(maxFractionDigits: 2)
        return "1 \(selectedCurrency.currencyUnit) = \(formatted) KRW"
    }

    private static func computeConvertedAmount(
        display: String,
        exchangeRate: Decimal,
        outputCurrency: Currency,
        isInputKRW: Bool
    ) -> String {
        guard let inputDecimal = Decimal(string: display), inputDecimal >= 0 else {
            return "0"
        }
        if isInputKRW {
            guard exchangeRate != 0 else { return "0" }
            let converted = inputDecimal / exchangeRate
            if converted < 0 { return "0" }
            return "\(converted)"
        } else {
            let converted = inputDecimal * exchangeRate
            // 음수 결과는 0 처리
            if converted < 0 { return "0" }
            return "\(converted)"
        }
    }

    private static func formatAmount(_ raw: String, currency: Currency) -> String {
        guard let decimal = Decimal(string: raw) else {
            return raw
        }
        return decimal.formatDecimal(
            maxFractionDigits: currency.fractionDigits,
            minimumFractionDigits: currency.fractionDigits
        )
    }
}
