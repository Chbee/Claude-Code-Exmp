import SwiftUI

struct OfflineBanner: View {
    let isOffline: Bool
    let cachedAt: Date?

    @State private var isVisible = false

    var body: some View {
        Group {
            if isVisible {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appWarning)
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.appCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.appWarning, lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityElement(children: .combine)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: isVisible)
        .task(id: isOffline) {
            guard isOffline else {
                isVisible = false
                return
            }
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                return  // cancelled — do not flip visibility
            }
            isVisible = true
        }
    }

    private var message: String {
        guard let cachedAt else {
            return "오프라인 — 캐시 없음"
        }
        return "오프라인 — \(Self.formatKST(cachedAt)) 기준 데이터"
    }

    private static func formatKST(_ date: Date) -> String {
        let c = Calendar.kst.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return String(
            format: "%04d-%02d-%02d %02d:%02d KST",
            c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0
        )
    }
}

#Preview("Offline with cache") {
    OfflineBanner(isOffline: true, cachedAt: Date(timeIntervalSince1970: 1_745_572_800))
        .background(Color.appBackground)
}

#Preview("Offline no cache") {
    OfflineBanner(isOffline: true, cachedAt: nil)
        .background(Color.appBackground)
}
