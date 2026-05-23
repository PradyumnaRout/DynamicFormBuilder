enum ComponentType: String, Decodable {
    case text = "TEXT"
    case dropdown = "DROPDOWN"
    case toggle = "TOGGLE"
    case checkbox = "CHECKBOX"
    case colorPicker = "COLOR_PICKER"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = ComponentType(rawValue: raw) ?? .unknown
    }
}
