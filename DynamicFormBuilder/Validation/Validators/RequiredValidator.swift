struct RequiredValidator: FieldValidator {
    let errorMessage: String

    init(errorMessage: String = "This field is required.") {
        self.errorMessage = errorMessage
    }

    func validate(_ value: FieldValue) -> ValidationResult {
        value.isEmpty ? .invalid(errorMessage) : .valid
    }
}
