import SwiftUI

struct ExchangeRateErrorBanner: View {
    let error: ExchangeRateError
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(Color.appError)
            Text(error.errorDescription ?? "알 수 없는 오류")
                .font(.footnote)
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button("재시도", action: onRetry)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.appError.opacity(0.12))
    }
}

#Preview("네트워크 오류") {
    ExchangeRateErrorBanner(error: .networkError, onRetry: {})
}

#Preview("API 키 없음 — Dark") {
    ExchangeRateErrorBanner(error: .missingAPIKey, onRetry: {})
        .preferredColorScheme(.dark)
}
