import SwiftUI
import Combine

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var current: Theme = .default

    private init() {}

    func apply(_ theme: Theme) {
        current = theme
    }

    var backgroundColor: Color { Color(hex: current.backgroundColor) }
    var textColor: Color        { Color(hex: current.textColor) }
    var borderColor: Color      { Color(hex: current.borderColor) }
    var errorColor: Color       { Color(hex: current.errorColor) }
}
