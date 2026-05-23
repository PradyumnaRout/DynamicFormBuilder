import SwiftUI

struct DynamicToggleFieldView: View {
    let model: ToggleFieldModel
    @ObservedObject var viewModel: FormViewModel

    @EnvironmentObject private var themeManager: ThemeManager

    private var isOnBinding: Binding<Bool> {
        Binding(
            get: { viewModel.boolValue(for: model.id) },
            set: { viewModel.update(bool: $0, for: model.id) }
        )
    }

    var body: some View {
        Toggle(isOn: isOnBinding) {
            Text(model.label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(themeManager.textColor)
        }
        .tint(.blue)
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
