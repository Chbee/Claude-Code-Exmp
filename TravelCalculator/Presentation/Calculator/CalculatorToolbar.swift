import SwiftUI

// MARK: - CalculatorToolbar

struct CalculatorToolbar: View {
    let currency: Currency
    let networkState: NetworkState
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

            // 중간: 네트워크 상태 인디케이터
            networkIndicator
                .padding(.leading, 10)

            Spacer()

            // 우측: 카메라 + 설정 아이콘 (V1 숨김 — 레이아웃 유지)
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
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var networkIndicator: some View {
        switch networkState {
        case .online:
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.appSuccess)
                    .frame(width: 6, height: 6)
                Text("온라인")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextSub)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("온라인")
        case .offline:
            HStack(spacing: 4) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.appWarning)
                Text("오프라인")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appWarning)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("오프라인")
        case .unknown:
            // 레이아웃 자리 유지를 위한 placeholder (동일 높이)
            Color.clear
                .frame(height: 12)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    CalculatorToolbar(currency: .USD, networkState: .online, onCurrencyTap: {})
        .background(Color.appBackground)
}

#Preview("Dark") {
    CalculatorToolbar(currency: .TWD, networkState: .offline, onCurrencyTap: {})
        .background(Color.appBackground)
        .preferredColorScheme(.dark)
}
