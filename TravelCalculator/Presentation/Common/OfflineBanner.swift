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
            // 비대칭 grace: offline 진입은 1s 흡수(짧은 단절은 무시),
            // online 복귀는 1.5s sticky-hide(flapping 시 깜빡임 방지).
            do {
                try await Task.sleep(for: isOffline ? .seconds(1) : .milliseconds(1500))
            } catch {
                return
            }
            guard isVisible != isOffline else { return }
            isVisible = isOffline
            AccessibilityNotification.Announcement(
                isOffline
                    ? "오프라인 모드, 캐시 데이터 사용 중"
                    : "온라인 복귀"
            ).post()
        }
    }

    private var message: String {
        guard let cachedAt else {
            return "오프라인 — 캐시 없음"
        }
        return "오프라인 — \(cachedAt.yyyyMMddHHmmKST()) 기준 데이터"
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
