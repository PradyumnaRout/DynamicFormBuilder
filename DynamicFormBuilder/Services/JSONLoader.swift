import Foundation

final class JSONLoader {
    static let shared = JSONLoader()
    private init() {}

    func load<T: Decodable>(_ type: T.Type, from fileName: String, bundle: Bundle = .main) async throws -> T {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw FormError.fileNotFound(fileName)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw FormError.invalidData
        }

        guard !data.isEmpty else {
            throw FormError.invalidData
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch let error as DecodingError {
            throw FormError.decodingFailed(error.formattedDescription)
        }
    }
}
