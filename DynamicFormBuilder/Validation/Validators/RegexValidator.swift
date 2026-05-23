import Foundation

struct RegexValidator: FieldValidator {
    let pattern: String
    let errorMessage: String

    init(pattern: String, errorMessage: String = "Invalid format.") {
        self.pattern = pattern
        self.errorMessage = errorMessage
    }

    func validate(_ value: FieldValue) -> ValidationResult {
        guard let text = value.stringValue, !text.isEmpty else { return .valid }
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return .valid }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, range: range) != nil ? .valid : .invalid(errorMessage)
    }
}
