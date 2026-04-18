import SwiftUI

struct CurrencySelectView: View {
    @Environment(\.dismiss) private var dismiss
    @State var store: CurrencySelectStore

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 20)

            locationButton
                .padding(.bottom, 24)

            currencyList
                .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .interactiveDismissDisabled(store.state.isOnboarding)
        .onChange(of: store.state.shouldDismiss) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 8) {
                Text(store.state.isOnboarding ? "여행지 통화를 선택해주세요" : "여행 통화 설정")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("통화 설정을 위해 국가 선택")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextSub)
            }
            .frame(maxWidth: .infinity)

            if !store.state.isOnboarding {
                HStack {
                    Spacer()
                    Button {
                        store.send(.dismiss)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .frame(width: 34, height: 34)
                            .background(Color.appBackground.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private var locationButton: some View {
        Button {
            store.send(.requestLocation)
        } label: {
            HStack(spacing: 8) {
                if store.state.isRequestingLocation {
                    ProgressView()
                        .controlSize(.small)
                    Text("위치 확인 중…")
                        .font(.system(size: 15, weight: .semibold))
                } else {
                    Image("MapPin")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 20, height: 20)
                    Text("현재 위치로 자동 설정")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(Color.appTextSub)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appTextSub, lineWidth: 1.5)
            )
        }
        .disabled(store.state.isRequestingLocation)
    }

    private var currencyList: some View {
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
                            .padding(.leading, 60)
                    }
                }
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
            HStack(spacing: 16) {
                Text(currency.flag)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.countryName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.appTextPrimary)
                    Text(currency.currencyUnit)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSub)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appCheck)
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
