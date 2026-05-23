enum TextSubtype: String, Decodable {
    case plain = "PLAIN"
    case multiline = "MULTILINE"
    case number = "NUMBER"
    case uri = "URI"
    case secure = "SECURE"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = TextSubtype(rawValue: raw) ?? .plain
    }
}
