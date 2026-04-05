import Foundation

struct ToastPayload: Identifiable, Equatable, Sendable {
    let id: UUID
    let style: ToastStyle
    let title: String
    let message: String
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        style: ToastStyle,
        title: String,
        message: String = "",
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.style = style
        self.title = title
        self.message = message
        self.duration = duration ?? style.duration
    }
}
