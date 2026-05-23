struct MaxLengthValidator: FieldValidator {
    let maxLength: Int
    let errorMessage: String

    init(maxLength: Int, errorMessage: String? = nil) {
        self.maxLength = maxLength
        self.errorMessage = errorMessage ?? "Maximum \(maxLength) characters allowed."
    }

    func validate(_ value: FieldValue) -> ValidationResult {
        guard let text = value.stringValue else { return .valid }
        return text.count <= maxLength ? .valid : .invalid(errorMessage)
    }
}
