struct Theme: Decodable {
    let backgroundColor: String
    let textColor: String
    let borderColor: String
    let errorColor: String

    enum CodingKeys: String, CodingKey {
        case backgroundColor = "background_color"
        case textColor = "text_color"
        case borderColor = "border_color"
        case errorColor = "error_color"
    }

    static let `default` = Theme(
        backgroundColor: "#121212",
        textColor: "#E0E0E0",
        borderColor: "#333333",
        errorColor: "#CF6679"
    )
}
