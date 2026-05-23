import Foundation

enum FieldValue: Equatable {
    case string(String)
    case bool(Bool)
    case strings([String])
    case empty

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }

    var stringsValue: [String]? {
        if case .strings(let v) = self { return v }
        return nil
    }

    var isEmpty: Bool {
        switch self {
        case .empty:            return true
        case .string(let v):    return v.trimmingCharacters(in: .whitespaces).isEmpty
        case .strings(let v):   return v.isEmpty
        case .bool:             return false
        }
    }
}
