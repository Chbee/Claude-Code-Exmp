import SwiftUI

struct ToastView: View {
    let payload: ToastPayload

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(payload.style.iconAssetName)
                .resizable()
                .frame(width: 36, height: 36)
                .offset(x: 12, y: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(payload.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(payload.style.tintColor)
                    .lineLimit(1)

                if !payload.message.isEmpty {
                    Text(payload.message)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.toastMessageText)
                        .lineLimit(1)
                }
            }
            .offset(x: 60, y: 16)
        }
        .frame(width: 358, height: 72, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.toastBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(payload.style.tintColor, lineWidth: 2)
        )
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}
