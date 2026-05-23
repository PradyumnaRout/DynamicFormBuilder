struct CheckboxFieldModel: Decodable, Identifiable {
    let id: String
    let order: Int
    let label: String
    let required: Bool
    let metadata: [String: String]?
    let clickableTextColor: String?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id, order, label, required, metadata
        case clickableTextColor = "clickable_text_color"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        order = try c.decode(Int.self, forKey: .order)
        label = try c.decode(String.self, forKey: .label)
        required = try c.decodeIfPresent(Bool.self, forKey: .required) ?? false
        metadata = try c.decodeIfPresent([String: String].self, forKey: .metadata)
        clickableTextColor = try c.decodeIfPresent(String.self, forKey: .clickableTextColor)
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}
