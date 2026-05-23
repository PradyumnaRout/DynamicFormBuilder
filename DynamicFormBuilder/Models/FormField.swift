enum FormField: Decodable {
    case text(TextFieldModel)
    case dropdown(DropdownFieldModel)
    case toggle(ToggleFieldModel)
    case checkbox(CheckboxFieldModel)
    case colorPicker(ColorPickerFieldModel)
    case unknown

    private enum CodingKeys: String, CodingKey { case type }

    // MARK: - Polymorphic Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let componentType = try container.decode(ComponentType.self, forKey: .type)
        switch componentType {
        case .text:         self = .text(try TextFieldModel(from: decoder))
        case .dropdown:     self = .dropdown(try DropdownFieldModel(from: decoder))
        case .toggle:       self = .toggle(try ToggleFieldModel(from: decoder))
        case .checkbox:     self = .checkbox(try CheckboxFieldModel(from: decoder))
        case .colorPicker:  self = .colorPicker(try ColorPickerFieldModel(from: decoder))
        case .unknown:      self = .unknown
        }
    }
}

extension FormField {
    var fieldId: String {
        switch self {
        case .text(let m):          return m.id
        case .dropdown(let m):      return m.id
        case .toggle(let m):        return m.id
        case .checkbox(let m):      return m.id
        case .colorPicker(let m):   return m.id
        case .unknown:              return "__unknown__"
        }
    }

    var order: Int {
        switch self {
        case .text(let m):          return m.order
        case .dropdown(let m):      return m.order
        case .toggle(let m):        return m.order
        case .checkbox(let m):      return m.order
        case .colorPicker(let m):   return m.order
        case .unknown:              return Int.max
        }
    }

    var isRequired: Bool {
        switch self {
        case .text(let m):          return m.required
        case .dropdown(let m):      return m.required
        case .toggle(let m):        return m.required
        case .checkbox(let m):      return m.required
        case .colorPicker(let m):   return m.required
        case .unknown:              return false
        }
    }

    var errorMessage: String? {
        switch self {
        case .text(let m):          return m.errorMessage
        case .dropdown(let m):      return m.errorMessage
        case .toggle(let m):        return m.errorMessage
        case .checkbox(let m):      return m.errorMessage
        case .colorPicker(let m):   return m.errorMessage
        case .unknown:              return nil
        }
    }

    var isKnown: Bool {
        if case .unknown = self { return false }
        return true
    }
}
