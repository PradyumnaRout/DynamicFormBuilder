import SwiftUI

struct DynamicFieldView: View {
    let field: FormField
    @ObservedObject var viewModel: FormViewModel
    var focusedFieldId: FocusState<String?>.Binding

    var body: some View {
        switch field {
        case .text(let model):
            DynamicTextFieldView(model: model, viewModel: viewModel, focusedFieldId: focusedFieldId)
        case .dropdown(let model):
            DynamicDropdownFieldView(model: model, viewModel: viewModel)
        case .toggle(let model):
            DynamicToggleFieldView(model: model, viewModel: viewModel)
        case .checkbox(let model):
            DynamicCheckboxFieldView(model: model, viewModel: viewModel)
        case .unknown:
            EmptyView()
        }
    }
}
