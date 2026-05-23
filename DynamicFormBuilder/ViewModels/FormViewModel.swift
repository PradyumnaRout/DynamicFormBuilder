import Foundation
import Combine

@MainActor
final class FormViewModel: ObservableObject {
    @Published private(set) var formConfig: FormConfig?
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: FormError?
    @Published var fieldValues: [String: FieldValue] = [:]
    @Published private(set) var validationResults: [String: ValidationResult] = [:]
    @Published private(set) var isSubmitted = false

    private let parsingService: FormParsingService
    private let validationService: ValidationService

    init(
        parsingService: FormParsingService = .shared,
        validationService: ValidationService = .shared
    ) {
        self.parsingService = parsingService
        self.validationService = validationService
    }

    // MARK: - Loading

    func loadForm() async {
        isLoading = true
        loadError = nil
        do {
            let config = try await parsingService.loadFormConfig()
            formConfig = config
            initializeDefaults(from: config)
            ThemeManager.shared.apply(config.theme)
        } catch let error as FormError {
            loadError = error
        } catch {
            loadError = .decodingFailed(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Value Accessors

    func stringValue(for id: String) -> String {
        fieldValues[id]?.stringValue ?? ""
    }

    func boolValue(for id: String) -> Bool {
        fieldValues[id]?.boolValue ?? false
    }

    func stringsValue(for id: String) -> [String] {
        fieldValues[id]?.stringsValue ?? []
    }

    // MARK: - Value Mutators

    func update(string value: String, for id: String) {
        fieldValues[id] = value.isEmpty ? .empty : .string(value)
        validateField(id: id)
    }

    func update(bool value: Bool, for id: String) {
        fieldValues[id] = .bool(value)
        validateField(id: id)
    }

    func toggleSelection(for id: String, optionId: String, allowMultiple: Bool) {
        var current = stringsValue(for: id)
        if let idx = current.firstIndex(of: optionId) {
            current.remove(at: idx)
        } else {
            if !allowMultiple { current = [] }
            current.append(optionId)
        }
        fieldValues[id] = current.isEmpty ? .empty : .strings(current)
        validateField(id: id)
    }

    // MARK: - Validation

    func validateField(id: String) {
        guard let field = formConfig?.fields.first(where: { $0.fieldId == id }) else { return }
        validationResults[id] = validationService.validate(field: field, value: fieldValues[id] ?? .empty)
    }

    @discardableResult
    func validateAllFields() -> Bool {
        guard let config = formConfig else { return false }
        validationResults = validationService.validateAll(
            fields: config.sortedKnownFields,
            values: fieldValues
        )
        return validationResults.values.allSatisfy(\.isValid)
    }

    func validationResult(for id: String) -> ValidationResult {
        validationResults[id] ?? .valid
    }

    // MARK: - Submission

    func submitForm() -> [String: Any]? {
        guard validateAllFields() else { return nil }
        let payload: [String: Any] = fieldValues.reduce(into: [:]) { dict, pair in
            switch pair.value {
            case .string(let v):    dict[pair.key] = v
            case .bool(let v):      dict[pair.key] = v
            case .strings(let v):   dict[pair.key] = v
            case .empty:            dict[pair.key] = NSNull()
            }
        }
        isSubmitted = true
        return payload
    }

    // MARK: - Focus Management

    /// Ordered IDs of every TEXT field in the form — the focus chain.
    var focusableFieldIds: [String] {
        formConfig?.sortedKnownFields.compactMap { field -> String? in
            guard case .text = field else { return nil }
            return field.fieldId
        } ?? []
    }

    func nextFocusableId(after id: String) -> String? {
        let ids = focusableFieldIds
        guard let idx = ids.firstIndex(of: id), ids.indices.contains(idx + 1) else { return nil }
        return ids[idx + 1]
    }

    func previousFocusableId(before id: String) -> String? {
        let ids = focusableFieldIds
        guard let idx = ids.firstIndex(of: id), idx > 0 else { return nil }
        return ids[idx - 1]
    }

    func isLastFocusable(id: String) -> Bool {
        focusableFieldIds.last == id
    }

    // MARK: - Submit State

    /// True when every required field has a non-empty / checked value.
    var isSubmitEnabled: Bool {
        guard let config = formConfig else { return false }
        return config.sortedKnownFields
            .filter(\.isRequired)
            .allSatisfy { field in
                let value = fieldValues[field.fieldId] ?? .empty
                if case .checkbox = field { return value.boolValue == true }
                return !value.isEmpty
            }
    }

    // MARK: - Private

    private func initializeDefaults(from config: FormConfig) {
        for field in config.sortedKnownFields {
            switch field {
            case .text(let m):
                if let def = m.defaultValue, !def.isEmpty {
                    fieldValues[m.id] = .string(def)
                }
            case .dropdown(let m):
                if !m.defaultValues.isEmpty {
                    fieldValues[m.id] = .strings(m.defaultValues)
                }
            case .toggle(let m):
                fieldValues[m.id] = .bool(m.defaultValue)
            case .checkbox, .unknown:
                break
            }
        }
    }
}
