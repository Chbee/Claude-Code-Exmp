import SwiftUI

struct ExchangeRateErrorView: View {
    let error: ExchangeRateError
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.appError)
                Text(error.errorDescription ?? "알 수 없는 오류")
                    .font(.body)
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)
                Button("다시 시도", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.appPrimary)
            }
            .padding(32)
        }
    }
}

#Preview("네트워크 오류") {
    ExchangeRateErrorView(error: .networkError, onRetry: {})
}

#Preview("캐시 없음 — Dark") {
    ExchangeRateErrorView(error: .noCacheAvailable, onRetry: {})
        .preferredColorScheme(.dark)
}
