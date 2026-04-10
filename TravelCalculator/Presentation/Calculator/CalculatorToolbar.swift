import SwiftUI

// MARK: - CalculatorToolbar

struct CalculatorToolbar: View {
    let currency: Currency
    let onCurrencyTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // 좌측: 통화 선택 pill
            Button(action: onCurrencyTap) {
                HStack(spacing: 6) {
                    Text(currency.flag)
                        .font(.system(size: 18))
                    Text(currency.currencyUnit)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appTextSub)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.appCard)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // 중간: 온라인 상태
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.appSuccess)
                    .frame(width: 6, height: 6)
                Text("온라인")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextSub)
            }
            .padding(.leading, 10)

            Spacer()

            // 우측: 카메라 + 설정 아이콘
            HStack(spacing: 4) {
                Button(action: {}) {
                    Image(systemName: "camera")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.appTextSub)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.appTextSub)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("Light") {
    CalculatorToolbar(currency: .USD, onCurrencyTap: {})
        .background(Color.appBackground)
}

#Preview("Dark") {
    CalculatorToolbar(currency: .TWD, onCurrencyTap: {})
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
