import SwiftUI

// MARK: - CalculatorKeypad

struct CalculatorKeypad: View {
    let onIntent: (CalculatorIntent) -> Void

    private let spacing: CGFloat = 12

    var body: some View {
        GeometryReader { geo in
            let totalHSpacing = spacing * 3
            let buttonWidth = (geo.size.width - totalHSpacing) / 4
            let buttonHeight = buttonWidth * 0.75

            VStack(spacing: spacing) {
                // Row 1: AC, C, ←, ÷  (4 buttons — Figma 기준 AC/C 분리)
                HStack(spacing: spacing) {
                    KeypadButton(label: "AC", style: .utility, width: buttonWidth, height: buttonHeight) {
                        onIntent(.allClearPressed)
                    }
                    KeypadButton(label: "C", style: .utility, width: buttonWidth, height: buttonHeight) {
                        onIntent(.clearPressed)
                    }
                    KeypadButton(label: "←", style: .utility, width: buttonWidth, height: buttonHeight) {
                        onIntent(.backspacePressed)
                    }
                    KeypadButton(label: "÷", style: .operator_, width: buttonWidth, height: buttonHeight) {
                        onIntent(.operatorPressed(.divide))
                    }
                }

                // Row 2: 7, 8, 9, ×
                HStack(spacing: spacing) {
                    KeypadButton(label: "7", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(7))
                    }
                    KeypadButton(label: "8", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(8))
                    }
                    KeypadButton(label: "9", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(9))
                    }
                    KeypadButton(label: "×", style: .operator_, width: buttonWidth, height: buttonHeight) {
                        onIntent(.operatorPressed(.multiply))
                    }
                }

                // Row 3: 4, 5, 6, -
                HStack(spacing: spacing) {
                    KeypadButton(label: "4", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(4))
                    }
                    KeypadButton(label: "5", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(5))
                    }
                    KeypadButton(label: "6", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(6))
                    }
                    KeypadButton(label: "-", style: .operator_, width: buttonWidth, height: buttonHeight) {
                        onIntent(.operatorPressed(.minus))
                    }
                }

                // Row 4: 1, 2, 3, +
                HStack(spacing: spacing) {
                    KeypadButton(label: "1", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(1))
                    }
                    KeypadButton(label: "2", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(2))
                    }
                    KeypadButton(label: "3", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(3))
                    }
                    KeypadButton(label: "+", style: .operator_, width: buttonWidth, height: buttonHeight) {
                        onIntent(.operatorPressed(.plus))
                    }
                }

                // Row 5: 0, ., = (Figma 기준 3등분)
                HStack(spacing: spacing) {
                    KeypadButton(label: "0", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.numberPressed(0))
                    }
                    KeypadButton(label: ".", style: .number, width: buttonWidth, height: buttonHeight) {
                        onIntent(.decimalPressed)
                    }
                    KeypadButton(label: "=", style: .equals, width: buttonWidth, height: buttonHeight) {
                        onIntent(.equalsPressed)
                    }
                    // 4열 맞춤용 빈 공간
                    Spacer()
                        .frame(width: buttonWidth)
                }
            }
        }
    }
}

// MARK: - KeypadButton

private enum ButtonStyle {
    case number
    case operator_
    case utility
    case equals

    var background: Color {
        switch self {
        case .number:    return .appCard
        case .operator_: return .appPrimary
        case .utility:   return Color.appAccent.opacity(0.8)
        case .equals:    return .appPrimary
        }
    }

    var foreground: Color {
        switch self {
        case .number:    return .appTextPrimary
        case .operator_: return .white
        case .utility:   return .appTextPrimary
        case .equals:    return .white
        }
    }
}

private struct KeypadButton: View {
    let label: String
    let style: ButtonStyle
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2.weight(.semibold))
                .foregroundStyle(style.foreground)
                .frame(width: width, height: height)
                .background(style.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Light") {
    CalculatorKeypad { _ in }
        .padding()
        .background(Color.appBackground)
}

#Preview("Dark") {
    CalculatorKeypad { _ in }
        .padding()
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
