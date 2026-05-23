struct DropdownFieldModel: Decodable, Identifiable {
    let id: String
    let order: Int
    let label: String
    let required: Bool
    let allowMultiple: Bool
    let options: [DropdownOption]
    let defaultValues: [String]
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case id, order, label, required, options
        case allowMultiple = "allow_multiple"
        case defaultValues = "default_values"
        case errorMessage = "error_message"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        order = try c.decode(Int.self, forKey: .order)
        label = try c.decode(String.self, forKey: .label)
        required = try c.decodeIfPresent(Bool.self, forKey: .required) ?? false
        allowMultiple = try c.decodeIfPresent(Bool.self, forKey: .allowMultiple) ?? false
        options = try c.decodeIfPresent([DropdownOption].self, forKey: .options) ?? []
        defaultValues = try c.decodeIfPresent([String].self, forKey: .defaultValues) ?? []
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}
