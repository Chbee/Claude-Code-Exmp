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

            searchBar
                .padding(.horizontal, 16)

            if store.state.filteredCurrencies.isEmpty {
                emptyState
            } else {
                currencyList
                    .padding(.horizontal, 16)
            }

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
                let items = store.state.filteredCurrencies
                ForEach(items, id: \.self) { currency in
                    CurrencyRowView(
                        currency: currency,
                        isSelected: currency == store.state.selectedCurrency
                    ) {
                        store.send(.selectCurrency(currency))
                    }

                    if currency != items.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private var searchBar: some View {
        let binding = Binding<String>(
            get: { store.state.searchQuery },
            set: { store.send(.setSearchQuery($0)) }
        )
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.appTextSub)

                TextField("국가 또는 통화 검색", text: binding)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityLabel("통화 검색")

                if !store.state.searchQuery.isEmpty {
                    Button {
                        store.send(.setSearchQuery(""))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.appTextSub)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("검색어 지우기")
                }
            }
            .frame(height: 48)

            Divider()
        }
    }

    private var emptyState: some View {
        VStack {
            Text("검색 결과가 없습니다")
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSub)
                .padding(.top, 40)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
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
