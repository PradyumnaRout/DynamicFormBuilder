import SwiftUI

struct ValidatedFieldContainer<Content: View>: View {
    let label: String
    let isRequired: Bool
    let validationResult: ValidationResult
    @ViewBuilder let content: () -> Content

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(themeManager.textColor)
                if isRequired {
                    Text("*")
                        .font(.subheadline)
                        .foregroundStyle(themeManager.errorColor)
                }
            }

            content()

            if let msg = validationResult.errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(themeManager.errorColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: validationResult.errorMessage)
    }
}
