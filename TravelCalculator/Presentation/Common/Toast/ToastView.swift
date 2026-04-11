import SwiftUI

struct ToastView: View {
    let payload: ToastPayload

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 컬러 원형 배경 + 흰색 아이콘
            Image(systemName: payload.style.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(payload.style.tintColor, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(payload.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(payload.style.tintColor)
                    .lineLimit(2)

                if !payload.message.isEmpty {
                    Text(payload.message)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSub)
                        .lineLimit(3)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 640, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appCard)
        )
        .overlay(alignment: .leading) {
            // 좌측 컬러 보더 스트립
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(payload.style.tintColor)
            .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}
