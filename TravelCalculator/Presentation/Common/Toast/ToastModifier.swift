import SwiftUI

struct ToastModifier: ViewModifier {
    let manager: ToastManager

    @State private var dragOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let payload = manager.currentToast {
                    ToastView(payload: payload)
                        .id(payload.id)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .offset(y: dragOffset)
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    dragOffset = min(0, value.translation.height)
                                }
                                .onEnded { value in
                                    let shouldDismiss = ToastDismissDecision.shouldDismiss(
                                        translation: value.translation,
                                        predictedEnd: value.predictedEndTranslation
                                    )
                                    if shouldDismiss {
                                        manager.dismiss()
                                        dragOffset = 0
                                    } else {
                                        withAnimation(ToastManager.springAnimation) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                        .accessibilityAction(named: Text("닫기")) {
                            manager.dismiss()
                        }
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                        )
                        .zIndex(1)
                }
            }
            .animation(ToastManager.springAnimation, value: manager.currentToast?.id)
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        modifier(ToastModifier(manager: manager))
    }
}
