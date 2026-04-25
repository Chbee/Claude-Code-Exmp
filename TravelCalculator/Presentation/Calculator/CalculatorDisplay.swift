import SwiftUI

// MARK: - CalculatorDisplay

struct CalculatorDisplay: View {
    let displayModel: CalculatorDisplayModel
    let onToggleDirection: () -> Void
    let onRefresh: () -> Void
    let daysSinceSearchDate: Int?
    let isRefreshEnabled: Bool
    let isLoading: Bool
    let isOffline: Bool
    let cachedAt: Date?

    var body: some View {
        VStack(spacing: 0) {
            rateRow
            Spacer().frame(height: 20)
            inputRow
            toggleButton
            resultRow
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Rate Row

    private var rateRow: some View {
        HStack(spacing: 6) {
            Text(displayModel.rateDisplay)
                .font(.footnote)
                .foregroundStyle(Color.appTextSub)
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(Color.appTextSub)
            } else if isOffline, let cachedAt {
                Text("·")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSub)
                Text("\(cachedAt.yyyyMMddHHmmKST()) 기준")
                    .font(.footnote)
                    .foregroundStyle(Color.appWarning)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else if let days = daysSinceSearchDate {
                Text("·")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSub)
                Text(Self.dateLabel(for: days))
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSub)
            }
            Spacer()
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(isRefreshEnabled ? Color.appPrimary : Color.appTextSub)
            }
            .disabled(isLoading)
            .buttonStyle(.plain)
        }
    }

    private static func dateLabel(for days: Int) -> String {
        days == 0 ? "최신" : "\(days)일 전"
    }

    // MARK: - Input Row

    private var inputRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(displayModel.inputDisplay.currencyCode)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.appTextSub)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
            Spacer()
            Text(displayModel.inputDisplay.formattedAmount)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.appTextPrimary)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
        }
        .frame(height: 56)
    }

    // MARK: - Toggle Button

    private var toggleButton: some View {
        HStack {
            Spacer()
            Button(action: onToggleDirection) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.appPrimary)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.vertical, 12)
    }

    // MARK: - Result Row

    private var resultRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(displayModel.resultDisplay.currencyCode)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.appTextSub)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
            Spacer()
            Text(displayModel.resultDisplay.formattedAmount)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.appTextSub)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
        }
        .frame(height: 56)
    }
}

// MARK: - Preview

#Preview("오늘 환율") {
    let state = CalculatorState()
    let model = CalculatorDisplayModel.make(
        state: state,
        inputCurrency: .USD,
        outputCurrency: .KRW,
        selectedCurrency: .USD,
        exchangeRate: 1350,
        isInputKRW: false
    )
    CalculatorDisplay(
        displayModel: model,
        onToggleDirection: {},
        onRefresh: {},
        daysSinceSearchDate: 0,
        isRefreshEnabled: false,
        isLoading: false,
        isOffline: false,
        cachedAt: nil
    )
    .background(Color.appBackground)
}

#Preview("2일 전 기준 (새로고침 활성)") {
    let state = CalculatorState()
    let model = CalculatorDisplayModel.make(
        state: state,
        inputCurrency: .USD,
        outputCurrency: .KRW,
        selectedCurrency: .USD,
        exchangeRate: 1350,
        isInputKRW: false
    )
    CalculatorDisplay(
        displayModel: model,
        onToggleDirection: {},
        onRefresh: {},
        daysSinceSearchDate: 2,
        isRefreshEnabled: true,
        isLoading: false,
        isOffline: false,
        cachedAt: nil
    )
    .background(Color.appBackground)
}

#Preview("로딩 중") {
    let state = CalculatorState()
    let model = CalculatorDisplayModel.make(
        state: state,
        inputCurrency: .USD,
        outputCurrency: .KRW,
        selectedCurrency: .USD,
        exchangeRate: 0,
        isInputKRW: false
    )
    CalculatorDisplay(
        displayModel: model,
        onToggleDirection: {},
        onRefresh: {},
        daysSinceSearchDate: nil,
        isRefreshEnabled: false,
        isLoading: true,
        isOffline: false,
        cachedAt: nil
    )
    .background(Color.appBackground)
}

#Preview("오프라인 (캐시 시각 표시)") {
    let state = CalculatorState()
    let model = CalculatorDisplayModel.make(
        state: state,
        inputCurrency: .USD,
        outputCurrency: .KRW,
        selectedCurrency: .USD,
        exchangeRate: 1350,
        isInputKRW: false
    )
    CalculatorDisplay(
        displayModel: model,
        onToggleDirection: {},
        onRefresh: {},
        daysSinceSearchDate: 0,
        isRefreshEnabled: false,
        isLoading: false,
        isOffline: true,
        cachedAt: Date(timeIntervalSince1970: 1_745_572_800)
    )
    .background(Color.appBackground)
}

#Preview("Dark — 2일 전 기준") {
    let state = CalculatorState()
    let model = CalculatorDisplayModel.make(
        state: state,
        inputCurrency: .KRW,
        outputCurrency: .USD,
        selectedCurrency: .USD,
        exchangeRate: 1350,
        isInputKRW: true
    )
    CalculatorDisplay(
        displayModel: model,
        onToggleDirection: {},
        onRefresh: {},
        daysSinceSearchDate: 2,
        isRefreshEnabled: true,
        isLoading: false,
        isOffline: false,
        cachedAt: nil
    )
    .background(Color.appBackground)
    .preferredColorScheme(.dark)
}
