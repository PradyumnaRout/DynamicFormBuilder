import SwiftUI

struct DynamicTextFieldView: View {
    let model: TextFieldModel
    @ObservedObject var viewModel: FormViewModel
    var focusedFieldId: FocusState<String?>.Binding

    @EnvironmentObject private var themeManager: ThemeManager

    private var textBinding: Binding<String> {
        Binding(
            get: { viewModel.stringValue(for: model.id) },
            set: { viewModel.update(string: $0, for: model.id) }
        )
    }

    private var borderColor: Color {
        viewModel.validationResult(for: model.id).isValid
            ? themeManager.borderColor
            : themeManager.errorColor
    }

    // Return key label: multiline has no submit action so always .next/.done for others
    private var submitLabel: SubmitLabel {
        viewModel.isLastFocusable(id: model.id) ? .done : .next
    }

    var body: some View {
        ValidatedFieldContainer(
            label: model.label,
            isRequired: model.required,
            validationResult: viewModel.validationResult(for: model.id)
        ) {
            inputView
                .padding(.horizontal, 12)
                .padding(.vertical, model.subtype == .multiline ? 8 : 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(borderColor, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.backgroundColor.opacity(0.6))
                        )
                )
        }
    }

    @ViewBuilder
    private var inputView: some View {
        switch model.subtype {
        case .plain:
            TextField(model.placeholder ?? "", text: textBinding)
                .focused(focusedFieldId, equals: model.id)
                .submitLabel(submitLabel)
                .onSubmit(advanceFocus)
                .foregroundStyle(themeManager.textColor)
                .tint(themeManager.textColor)
                .autocorrectionDisabled()

        case .multiline:
            // TextEditor has no submitLabel/onSubmit — keyboard toolbar handles navigation
            ZStack(alignment: .topLeading) {
                if textBinding.wrappedValue.isEmpty, let placeholder = model.placeholder {
                    Text(placeholder)
                        .foregroundStyle(themeManager.textColor.opacity(0.35))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: textBinding)
                    .focused(focusedFieldId, equals: model.id)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(themeManager.textColor)
                    .tint(themeManager.textColor)
            }

        case .number:
            TextField(model.placeholder ?? "", text: textBinding)
                .focused(focusedFieldId, equals: model.id)
                .submitLabel(submitLabel)
                .onSubmit(advanceFocus)
                .keyboardType(.decimalPad)
                .foregroundStyle(themeManager.textColor)
                .tint(themeManager.textColor)

        case .uri:
            TextField(model.placeholder ?? "https://", text: textBinding)
                .focused(focusedFieldId, equals: model.id)
                .submitLabel(submitLabel)
                .onSubmit(advanceFocus)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(themeManager.textColor)
                .tint(themeManager.textColor)

        case .secure:
            SecureField(model.placeholder ?? "", text: textBinding)
                .focused(focusedFieldId, equals: model.id)
                .submitLabel(submitLabel)
                .onSubmit(advanceFocus)
                .foregroundStyle(themeManager.textColor)
                .tint(themeManager.textColor)
        }
    }

    // MARK: - Focus Advancement

    private func advanceFocus() {
        if viewModel.isLastFocusable(id: model.id) {
            focusedFieldId.wrappedValue = nil
        } else {
            focusedFieldId.wrappedValue = viewModel.nextFocusableId(after: model.id)
        }
    }
}
