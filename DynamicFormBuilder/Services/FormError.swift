import Foundation

enum FormError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):   return "JSON file '\(name)' not found in bundle."
        case .decodingFailed(let msg):  return "Decoding failed: \(msg)"
        case .invalidData:              return "The JSON data was invalid or empty."
        }
    }
}

extension DecodingError {
    var formattedDescription: String {
        switch self {
        case .typeMismatch(let type, let ctx):
            return "Type mismatch for \(type): \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            return "Value not found for \(type): \(ctx.debugDescription)"
        case .keyNotFound(let key, let ctx):
            return "Key '\(key.stringValue)' not found: \(ctx.debugDescription)"
        case .dataCorrupted(let ctx):
            return "Data corrupted: \(ctx.debugDescription)"
        @unknown default:
            return localizedDescription
        }
    }
}
