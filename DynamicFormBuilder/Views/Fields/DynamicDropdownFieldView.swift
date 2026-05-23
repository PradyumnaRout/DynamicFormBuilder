import SwiftUI

struct DynamicDropdownFieldView: View {
    let model: DropdownFieldModel
    @ObservedObject var viewModel: FormViewModel

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isSheetPresented = false

    private var selectedIds: [String] { viewModel.stringsValue(for: model.id) }

    private var displayText: String {
        let labels = model.options.filter { selectedIds.contains($0.id) }.map(\.label)
        return labels.isEmpty ? "Select…" : labels.joined(separator: ", ")
    }

    private var borderColor: Color {
        viewModel.validationResult(for: model.id).isValid
            ? themeManager.borderColor
            : themeManager.errorColor
    }

    var body: some View {
        ValidatedFieldContainer(
            label: model.label,
            isRequired: model.required,
            validationResult: viewModel.validationResult(for: model.id)
        ) {
            Button { isSheetPresented = true } label: {
                HStack {
                    Text(displayText)
                        .foregroundStyle(
                            selectedIds.isEmpty
                                ? themeManager.textColor.opacity(0.35)
                                : themeManager.textColor
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(themeManager.textColor.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
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
        .sheet(isPresented: $isSheetPresented) {
            DropdownPickerSheet(
                model: model,
                selectedIds: selectedIds,
                onToggle: { optionId in
                    viewModel.toggleSelection(
                        for: model.id,
                        optionId: optionId,
                        allowMultiple: model.allowMultiple
                    )
                    if !model.allowMultiple { isSheetPresented = false }
                }
            )
            .environmentObject(themeManager)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Picker Sheet

private struct DropdownPickerSheet: View {
    let model: DropdownFieldModel
    let selectedIds: [String]
    let onToggle: (String) -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if model.options.isEmpty {
                    emptyState
                } else {
                    optionsList
                }
            }
            .navigationTitle(model.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
        }
    }

    private var optionsList: some View {
        List(model.options) { option in
            Button { onToggle(option.id) } label: {
                HStack {
                    Text(option.label)
                        .foregroundStyle(themeManager.textColor)
                    Spacer()
                    if selectedIds.contains(option.id) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                    }
                }
            }
            .listRowBackground(themeManager.backgroundColor)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(themeManager.textColor.opacity(0.35))
            Text("No options available")
                .font(.subheadline)
                .foregroundStyle(themeManager.textColor.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
