import SwiftUI

struct ToastModifier: ViewModifier {
    let manager: ToastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let payload = manager.currentToast {
                    ToastView(payload: payload)
                        .id(payload.id)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                        )
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: manager.currentToast?.id)
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        modifier(ToastModifier(manager: manager))
    }
}
