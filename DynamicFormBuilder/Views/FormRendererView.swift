import SwiftUI

struct FormRendererView: View {
    @StateObject private var viewModel = FormViewModel()
    @EnvironmentObject private var themeManager: ThemeManager

    @FocusState private var focusedFieldId: String?
    @State private var showSuccessAlert = false

    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.loadError {
                    errorView(error)
                } else if let config = viewModel.formConfig {
                    formScrollView(config)
                }
            }
        }
        .task { await viewModel.loadForm() }
        .alert("Submitted", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your form was submitted successfully.")
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(themeManager.textColor)
            Text("Loading form…")
                .font(.subheadline)
                .foregroundStyle(themeManager.textColor.opacity(0.6))
        }
    }

    // MARK: - Error

    private func errorView(_ error: FormError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(themeManager.errorColor)
            Text("Failed to Load Form")
                .font(.headline)
                .foregroundStyle(themeManager.textColor)
            Text(error.localizedDescription)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(themeManager.textColor.opacity(0.6))
            Button("Retry") { Task { await viewModel.loadForm() } }
                .buttonStyle(.bordered)
                .tint(themeManager.textColor)
        }
        .padding(32)
    }

    // MARK: - Form

    private func formScrollView(_ config: FormConfig) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(config.formTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(themeManager.textColor)
                        .padding(.bottom, 4)

                    ForEach(config.sortedKnownFields, id: \.fieldId) { field in
                        DynamicFieldView(
                            field: field,
                            viewModel: viewModel,
                            focusedFieldId: $focusedFieldId
                        )
                        .id(field.fieldId)
                    }

                    submitButton
                        .id("__submit__")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { keyboardToolbar } }
            .onChangeCompat(of: focusedFieldId) { newId in
                guard let newId else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newId, anchor: .center)
                }
            }
        }
    }

    // MARK: - Keyboard Toolbar

    @ViewBuilder
    private var keyboardToolbar: some View {
        let hasPrev = focusedFieldId.flatMap { viewModel.previousFocusableId(before: $0) } != nil
        let hasNext = focusedFieldId.flatMap { viewModel.nextFocusableId(after: $0) } != nil

        Button {
            guard let id = focusedFieldId else { return }
            focusedFieldId = viewModel.previousFocusableId(before: id)
        } label: {
            Image(systemName: "chevron.up")
        }
        .disabled(!hasPrev)

        Button {
            guard let id = focusedFieldId else { return }
            focusedFieldId = viewModel.nextFocusableId(after: id)
        } label: {
            Image(systemName: "chevron.down")
        }
        .disabled(!hasNext)

        Spacer()

        Button("Done") { focusedFieldId = nil }
            .fontWeight(.semibold)
    }

    // MARK: - Submit

    private var submitButton: some View {
        let enabled = viewModel.isSubmitEnabled
        return Button(action: handleSubmit) {
            Text("Submit")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(enabled ? Color.blue : themeManager.borderColor.opacity(0.5))
        .foregroundStyle(enabled ? .white : themeManager.textColor.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
        .padding(.top, 8)
    }

    private func handleSubmit() {
        focusedFieldId = nil
        if let payload = viewModel.submitForm() {
            showSuccessAlert = true
            #if DEBUG
            print("[FormRendererView] Payload: \(payload)")
            #endif
        }
    }
}
