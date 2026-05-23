import Foundation

struct URLValidator: FieldValidator {
    let errorMessage: String

    init(errorMessage: String = "Please enter a valid URL starting with http:// or https://") {
        self.errorMessage = errorMessage
    }

    func validate(_ value: FieldValue) -> ValidationResult {
        guard let text = value.stringValue, !text.isEmpty else { return .valid }

        guard
            let url = URL(string: text),
            let scheme = url.scheme,
            ["http", "https"].contains(scheme.lowercased()),
            let host = url.host,
            !host.isEmpty
        else {
            return .invalid(errorMessage)
        }

        return .valid
    }
}
