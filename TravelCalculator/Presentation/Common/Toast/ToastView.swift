import SwiftUI

struct ToastView: View {
    let payload: ToastPayload

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: payload.style.iconName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(.white.opacity(0.18), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(payload.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if !payload.message.isEmpty {
                    Text(payload.message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 640, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        payload.style.tintColor.opacity(0.98),
                        payload.style.tintColor.opacity(0.84)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: payload.style.tintColor.opacity(0.28), radius: 18, x: 0, y: 10)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}
