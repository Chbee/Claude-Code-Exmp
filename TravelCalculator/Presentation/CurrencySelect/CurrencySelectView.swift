import SwiftUI

struct CurrencySelectView: View {
    @Environment(\.dismiss) private var dismiss
    @State var store: CurrencySelectStore

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                ZStack {
                    Text(store.state.isOnboarding ? "여행지 통화를 선택해주세요" : "여행 통화 설정")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity)

                    if !store.state.isOnboarding {
                        HStack {
                            Spacer()
                            Button {
                                store.send(.dismiss)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .padding(8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 8)

                // Subtitle
                Text("통화 설정을 위해 국가 선택")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSub)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Location button
                Button {
                    store.send(.requestLocation)
                } label: {
                    HStack(spacing: 6) {
                        if store.state.isRequestingLocation {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(store.state.isRequestingLocation ? "위치 확인 중…" : "📍 현재 위치로 자동 설정")
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.appTextSub)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                }
                .disabled(store.state.isRequestingLocation)
                .padding(.bottom, 16)

                // Currency list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.state.currencies, id: \.self) { currency in
                            CurrencyRowView(
                                currency: currency,
                                isSelected: currency == store.state.selectedCurrency
                            ) {
                                store.send(.selectCurrency(currency))
                            }

                            if currency != store.state.currencies.last {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                }
            }
        }
        .interactiveDismissDisabled(store.state.isOnboarding)
        .onChange(of: store.state.shouldDismiss) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
}

private struct CurrencyRowView: View {
    let currency: Currency
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(currency.flag)
                    .font(.title2)
                    .frame(width: 36)

                Text(currency.countryName)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.appPrimary : Color.appTextPrimary)

                Spacer()

                Text(currency.currencyUnit)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSub)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CurrencySelectView(
        store: CurrencySelectStore(
            toastManager: ToastManager(),
            currencyStore: AppCurrencyStore()
        )
    )
}
