import Foundation

enum CalculatorReducer {

    // 정수부 최대 자릿수
    private static let maxIntegerDigits = 10
    // 소수점 최대 자릿수
    private static let maxFractionDigits = 2
    // = 결과 정수부 한계
    private static let maxResultIntegerDigits = 15

    static func reduce(_ state: CalculatorState, intent: CalculatorIntent) -> CalculatorState {
        var s = state
        s.pendingToast = nil

        switch intent {

        case .numberPressed(let digit):
            s = handleNumber(s, digit: digit)

        case .decimalPressed:
            s = handleDecimal(s)

        case .operatorPressed(let op):
            s = handleOperator(s, op: op)

        case .equalsPressed:
            s = handleEquals(s)

        case .clearPressed:
            s.display = "0"
            s.isEnteringNewNumber = true
            s.lastOperator = nil
            s.lastOperand = nil
            s.isInputLimitExceeded = false

        case .allClearPressed:
            s = .init()

        case .backspacePressed:
            s = handleBackspace(s)

        case .resetInputLimitFlag:
            s.isInputLimitExceeded = false

        case .resetForCurrencyChange:
            s = .init()
        }

        return s
    }

    // MARK: - Number

    private static func handleNumber(_ s: CalculatorState, digit: Int) -> CalculatorState {
        var s = s

        if s.isEnteringNewNumber {
            // 새 숫자 시작
            let newDisplay = digit == 0 ? "0" : "\(digit)"
            s.display = newDisplay
            s.isEnteringNewNumber = false
            s.lastOperator = nil
            s.lastOperand = nil
            if s.pendingOperator == nil {
                s.previousValue = nil
            }
            s.isInputLimitExceeded = false
            return s
        }

        // 이미 입력 중인 경우 — 10자리 초과 체크
        let integerPart = s.display.components(separatedBy: ".").first ?? s.display
        let integerDigits = integerPart.filter { $0.isNumber }.count

        // 소수점 이하 입력 중이면 소수점 자릿수 체크
        if s.display.contains(".") {
            let fractionPart = s.display.components(separatedBy: ".").last ?? ""
            if fractionPart.count >= maxFractionDigits {
                return s // 소수점 이하 2자리 이미 꽉 참 — 무시
            }
        } else {
            // 정수부 자릿수 초과 체크
            if integerDigits >= maxIntegerDigits {
                if !s.isInputLimitExceeded {
                    s.isInputLimitExceeded = true
                    s.pendingToast = ToastPayload(
                        style: .warning,
                        title: "입력 한도 초과",
                        message: "최대 \(maxIntegerDigits)자리까지 입력할 수 있습니다"
                    )
                }
                return s
            }
        }

        // "0" 상태에서 0 추가 → 무시
        if s.display == "0" && digit == 0 {
            return s
        }
        // "0" 상태에서 다른 숫자 → 교체
        if s.display == "0" && digit != 0 {
            s.display = "\(digit)"
            return s
        }

        s.display += "\(digit)"
        return s
    }

    // MARK: - Decimal

    private static func handleDecimal(_ s: CalculatorState) -> CalculatorState {
        var s = s

        if s.isEnteringNewNumber {
            s.display = "0."
            s.isEnteringNewNumber = false
            s.lastOperator = nil
            s.lastOperand = nil
            if s.pendingOperator == nil {
                s.previousValue = nil
            }
            s.isInputLimitExceeded = false
            return s
        }

        // 이미 소수점 있으면 무시
        if s.display.contains(".") {
            return s
        }

        // 정수부 10자리 초과면 소수점 추가 불가
        let integerDigits = s.display.filter { $0.isNumber }.count
        if integerDigits >= maxIntegerDigits {
            if !s.isInputLimitExceeded {
                s.isInputLimitExceeded = true
                s.pendingToast = ToastPayload(
                    style: .warning,
                    title: "입력 한도 초과",
                    message: "최대 \(maxIntegerDigits)자리까지 입력할 수 있습니다"
                )
            }
            return s
        }

        s.display += "."
        return s
    }

    // MARK: - Operator

    private static func handleOperator(_ s: CalculatorState, op: Operator) -> CalculatorState {
        var s = s

        guard let currentDecimal = Decimal(string: s.display) else {
            return s
        }

        if s.pendingOperator == nil {
            // 첫 번째 연산자
            s.previousValue = currentDecimal
            s.pendingOperator = op
            s.isEnteringNewNumber = true
            s.lastOperator = nil
            s.lastOperand = nil

        } else if s.isEnteringNewNumber {
            // 연산자 연속 입력 → 마지막 연산자로 교체
            s.pendingOperator = op
            s.lastOperator = nil
            s.lastOperand = nil

        } else {
            // pendingOperator 있고 새 숫자 입력 후 → 중간 계산
            guard let lhs = s.previousValue else {
                s.pendingOperator = op
                s.isEnteringNewNumber = true
                return s
            }
            let rhs = currentDecimal

            if let result = s.pendingOperator?.apply(lhs, rhs) {
                s.display = formatResult(result)
                s.previousValue = result
                s.pendingOperator = op
                s.isEnteringNewNumber = true
                s.lastOperator = nil
                s.lastOperand = nil
            } else {
                // 0 나누기 — 연산자만 교체, 상태 유지
                s.pendingToast = ToastPayload(
                    style: .warning,
                    title: "계산 오류",
                    message: "0으로 나눌 수 없습니다"
                )
                s.pendingOperator = op
            }
        }

        return s
    }

    // MARK: - Equals

    private static func handleEquals(_ s: CalculatorState) -> CalculatorState {
        var s = s

        if let pendingOp = s.pendingOperator {
            // 대기 중인 연산 실행
            guard let lhs = s.previousValue else {
                return s
            }
            // 연산자 후 바로 = 누르면 display 값을 rhs로 사용 (5 + = → 10)
            guard let rhs = Decimal(string: s.display) else {
                return s
            }

            if pendingOp == .divide && rhs == 0 {
                s.pendingToast = ToastPayload(
                    style: .warning,
                    title: "계산 오류",
                    message: "0으로 나눌 수 없습니다"
                )
                return s
            }

            guard let result = pendingOp.apply(lhs, rhs) else {
                s.pendingToast = ToastPayload(
                    style: .warning,
                    title: "계산 오류",
                    message: "0으로 나눌 수 없습니다"
                )
                return s
            }

            // 결과 정수부 15자리 초과 체크
            if exceedsResultLimit(result) {
                s.pendingToast = ToastPayload(
                    style: .error,
                    title: "계산 결과 초과",
                    message: "계산 결과가 너무 큽니다"
                )
                // display 유지, 상태 유지
                return s
            }

            s.display = formatResult(result)
            s.previousValue = result
            s.lastOperator = pendingOp
            s.lastOperand = rhs
            s.pendingOperator = nil
            s.isEnteringNewNumber = true

        } else if let lastOp = s.lastOperator, let lastRhs = s.lastOperand {
            // 반복 = — lastOperator + lastOperand 재사용
            guard let lhs = Decimal(string: s.display) else {
                return s
            }

            if lastOp == .divide && lastRhs == 0 {
                s.pendingToast = ToastPayload(
                    style: .warning,
                    title: "계산 오류",
                    message: "0으로 나눌 수 없습니다"
                )
                return s
            }

            guard let result = lastOp.apply(lhs, lastRhs) else {
                s.pendingToast = ToastPayload(
                    style: .warning,
                    title: "계산 오류",
                    message: "0으로 나눌 수 없습니다"
                )
                return s
            }

            if exceedsResultLimit(result) {
                s.pendingToast = ToastPayload(
                    style: .error,
                    title: "계산 결과 초과",
                    message: "계산 결과가 너무 큽니다"
                )
                return s
            }

            s.display = formatResult(result)
            s.previousValue = result
            s.isEnteringNewNumber = true
            // lastOperator/lastOperand는 유지 (계속 반복 가능)

        }
        // pendingOperator=nil, lastOperator=nil → 무시

        return s
    }

    // MARK: - Backspace

    private static func handleBackspace(_ s: CalculatorState) -> CalculatorState {
        var s = s

        // "0" 상태 → 무시
        if s.display == "0" {
            return s
        }

        var newDisplay: String
        if s.display == "0." {
            newDisplay = "0"
        } else {
            newDisplay = String(s.display.dropLast())
            if newDisplay.isEmpty || newDisplay == "-" {
                newDisplay = "0"
            }
        }

        s.display = newDisplay
        s.isEnteringNewNumber = false
        s.lastOperator = nil
        s.lastOperand = nil

        if newDisplay == "0" {
            s.isInputLimitExceeded = false
        }

        return s
    }

    // MARK: - Helpers

    private static func formatResult(_ value: Decimal) -> String {
        // 소수점 이하 불필요한 0 제거, 최대 maxFractionDigits 자리
        var result = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, maxFractionDigits, .plain)

        // 정수면 정수 형태로
        if rounded == rounded.rounded(scale: 0) {
            let nsDecimal = rounded as NSDecimalNumber
            return nsDecimal.stringValue
        }

        // 소수점 있는 경우
        let nsDecimal = rounded as NSDecimalNumber
        return nsDecimal.stringValue
    }

    private static func exceedsResultLimit(_ value: Decimal) -> Bool {
        let absValue = value < 0 ? -value : value
        let str = (absValue as NSDecimalNumber).stringValue
        let intStr = str.components(separatedBy: ".").first ?? "0"
        return intStr.count > maxResultIntegerDigits
    }
}

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}
