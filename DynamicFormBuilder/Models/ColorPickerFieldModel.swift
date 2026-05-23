struct ColorPickerFieldModel: Decodable, Identifiable {
    let id: String
    let order: Int
    let label: String
    let required: Bool
    let defaultValue: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id, order, label, required
        case defaultValue = "default_value"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        order = try c.decode(Int.self, forKey: .order)
        label = try c.decode(String.self, forKey: .label)
        required = try c.decodeIfPresent(Bool.self, forKey: .required) ?? false
        defaultValue = try c.decodeIfPresent(String.self, forKey: .defaultValue)
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}
