protocol FieldValidator {
    func validate(_ value: FieldValue) -> ValidationResult
}
