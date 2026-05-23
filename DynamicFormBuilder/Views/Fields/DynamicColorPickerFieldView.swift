import SwiftUI

struct DynamicColorPickerFieldView: View {
    let model: ColorPickerFieldModel
    @ObservedObject var viewModel: FormViewModel

    @EnvironmentObject private var themeManager: ThemeManager

    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                let hex = viewModel.stringValue(for: model.id)
                return Color(hex: hex.isEmpty ? (model.defaultValue ?? "#FFFFFF") : hex)
            },
            set: { viewModel.update(string: $0.toHex(), for: model.id) }
        )
    }

    private var displayHex: String {
        let hex = viewModel.stringValue(for: model.id)
        return hex.isEmpty ? (model.defaultValue ?? "#FFFFFF").uppercased() : hex.uppercased()
    }

    var body: some View {
        ValidatedFieldContainer(
            label: model.label,
            isRequired: model.required,
            validationResult: viewModel.validationResult(for: model.id)
        ) {
            HStack(spacing: 12) {
                colorSwatch
                hexLabel
                Spacer()
                colorPickerControl
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(themeManager.borderColor, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.backgroundColor.opacity(0.6))
                    )
            )
        }
    }

    // MARK: - Subviews

    private var colorSwatch: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(colorBinding.wrappedValue)
            .frame(width: 40, height: 32)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(themeManager.borderColor, lineWidth: 1)
            )
    }

    private var hexLabel: some View {
        Text(displayHex)
            .font(.system(.subheadline, design: .monospaced))
            .foregroundStyle(themeManager.textColor)
    }

    private var colorPickerControl: some View {
        ColorPicker("", selection: colorBinding, supportsOpacity: false)
            .labelsHidden()
            .frame(width: 32, height: 32)
    }
}
