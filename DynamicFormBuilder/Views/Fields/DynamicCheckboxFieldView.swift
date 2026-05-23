import SwiftUI

struct DynamicCheckboxFieldView: View {
    let model: CheckboxFieldModel
    @ObservedObject var viewModel: FormViewModel

    @EnvironmentObject private var themeManager: ThemeManager

    private var isCheckedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.boolValue(for: model.id) },
            set: { viewModel.update(bool: $0, for: model.id) }
        )
    }

    private var result: ValidationResult {
        viewModel.validationResult(for: model.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                checkboxButton
                richLabel
            }

            if let msg = result.errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(themeManager.errorColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: result.errorMessage)
    }

    // MARK: - Subviews

    private var checkboxButton: some View {
        Button { isCheckedBinding.wrappedValue.toggle() } label: {
            Image(systemName: isCheckedBinding.wrappedValue ? "checkmark.square.fill" : "square")
                .font(.title3)
                .foregroundStyle(
                    isCheckedBinding.wrappedValue
                        ? Color.blue
                        : (result.isValid ? themeManager.borderColor : themeManager.errorColor)
                )
        }
        .buttonStyle(.plain)
    }

    private var richLabel: some View {
        Text(buildAttributedString())
            .font(.subheadline)
            .foregroundStyle(themeManager.textColor)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture { isCheckedBinding.wrappedValue.toggle() }
    }

    // MARK: - AttributedString

    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(model.label)
        let clickColor: Color = model.clickableTextColor.map { Color(hex: $0) } ?? .blue

        guard let metadata = model.metadata else { return attributed }

        for (text, urlString) in metadata {
            guard
                let range = attributed.range(of: text),
                let url = URL(string: urlString)
            else { continue }

            attributed[range].foregroundColor = clickColor
            attributed[range].link = url
            attributed[range].underlineStyle = .single
        }

        return attributed
    }
}
