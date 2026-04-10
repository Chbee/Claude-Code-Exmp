import SwiftUI

struct CalculatorView: View {
    @State private var calculatorStore: CalculatorStore
    @State private var showCurrencySelect = false

    private let toastManager: ToastManager
    private let currencyStore: AppCurrencyStore

    init(toastManager: ToastManager, currencyStore: AppCurrencyStore) {
        self.toastManager = toastManager
        self.currencyStore = currencyStore
        _calculatorStore = State(initialValue: CalculatorStore(
            toastManager: toastManager,
            currencyStore: currencyStore
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            CalculatorToolbar(
                currency: currencyStore.selectedCurrency,
                onCurrencyTap: { showCurrencySelect = true }
            )
            .padding(.top, 8)

            Spacer()

            CalculatorDisplay(
                displayModel: calculatorStore.displayModel,
                onToggleDirection: { calculatorStore.toggleDirection() },
                onRefresh: {}
            )

            CalculatorKeypad(
                onIntent: { calculatorStore.send($0) }
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $showCurrencySelect) {
            CurrencySelectView(
                store: CurrencySelectStore(
                    toastManager: toastManager,
                    currencyStore: currencyStore
                )
            )
        }
    }
}

#Preview {
    let toastManager = ToastManager()
    let currencyStore = AppCurrencyStore()
    CalculatorView(toastManager: toastManager, currencyStore: currencyStore)
        .previewWithColorSchemes()
}
