struct FormConfig: Decodable {
    let theme: Theme
    let formTitle: String
    let fields: [FormField]

    enum CodingKeys: String, CodingKey {
        case theme
        case formTitle = "form_title"
        case fields
    }

    var sortedKnownFields: [FormField] {
        fields.filter(\.isKnown).sorted { $0.order < $1.order }
    }
}
