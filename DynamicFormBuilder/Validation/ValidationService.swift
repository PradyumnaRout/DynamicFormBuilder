final class ValidationService {
    static let shared = ValidationService()
    private init() {}

    func validate(field: FormField, value: FieldValue) -> ValidationResult {
        switch field {
        case .text(let m):      return validateText(model: m, value: value)
        case .dropdown(let m):  return validateDropdown(model: m, value: value)
        case .toggle:           return .valid
        case .checkbox(let m):  return validateCheckbox(model: m, value: value)
        case .unknown:          return .valid
        }
    }

    func validateAll(fields: [FormField], values: [String: FieldValue]) -> [String: ValidationResult] {
        fields.filter(\.isKnown).reduce(into: [:]) { results, field in
            results[field.fieldId] = validate(field: field, value: values[field.fieldId] ?? .empty)
        }
    }

    // MARK: - Private

    private func validateText(model: TextFieldModel, value: FieldValue) -> ValidationResult {
        var validators: [FieldValidator] = []
        if model.required {
            validators.append(RequiredValidator(errorMessage: model.errorMessage ?? "This field is required."))
        }
        if let max = model.maxLength {
            validators.append(MaxLengthValidator(maxLength: max, errorMessage: model.errorMessage))
        }
        if let pattern = model.regex {
            validators.append(RegexValidator(pattern: pattern, errorMessage: model.errorMessage ?? "Invalid format."))
        }
        return run(validators, on: value)
    }

    private func validateDropdown(model: DropdownFieldModel, value: FieldValue) -> ValidationResult {
        guard model.required else { return .valid }
        return RequiredValidator(errorMessage: model.errorMessage ?? "Please select an option.").validate(value)
    }

    private func validateCheckbox(model: CheckboxFieldModel, value: FieldValue) -> ValidationResult {
        guard model.required else { return .valid }
        if case .bool(let checked) = value {
            return checked ? .valid : .invalid(model.errorMessage ?? "This checkbox is required.")
        }
        return .invalid(model.errorMessage ?? "This checkbox is required.")
    }

    private func run(_ validators: [FieldValidator], on value: FieldValue) -> ValidationResult {
        for validator in validators {
            let result = validator.validate(value)
            if !result.isValid { return result }
        }
        return .valid
    }
}
