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
        let fullRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: fullRange) else {
            return .invalid(errorMessage)
        }
        // The match must span the entire string — partial matches are rejected.
        return match.range == fullRange ? .valid : .invalid(errorMessage)
    }
}
