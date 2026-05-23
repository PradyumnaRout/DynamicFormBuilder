struct TextFieldModel: Decodable, Identifiable {
    let id: String
    let order: Int
    let label: String
    let required: Bool
    let subtype: TextSubtype
    let placeholder: String?
    let maxLength: Int?
    let regex: String?
    let defaultValue: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id, order, label, required, subtype, placeholder, regex
        case maxLength = "max_length"
        case defaultValue = "default_value"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        order = try c.decode(Int.self, forKey: .order)
        label = try c.decode(String.self, forKey: .label)
        required = try c.decodeIfPresent(Bool.self, forKey: .required) ?? false
        subtype = try c.decodeIfPresent(TextSubtype.self, forKey: .subtype) ?? .plain
        placeholder = try c.decodeIfPresent(String.self, forKey: .placeholder)
        maxLength = try c.decodeIfPresent(Int.self, forKey: .maxLength)
        regex = try c.decodeIfPresent(String.self, forKey: .regex)
        defaultValue = try c.decodeIfPresent(String.self, forKey: .defaultValue)
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}
