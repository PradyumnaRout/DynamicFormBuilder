import SwiftUI

extension View {
    /// `onChange` that compiles on iOS 16 and uses the two-parameter closure on iOS 17+.
    @ViewBuilder
    func onChangeCompat<V: Equatable>(
        of value: V,
        perform action: @escaping (_ newValue: V) -> Void
    ) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in action(newValue) }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}
