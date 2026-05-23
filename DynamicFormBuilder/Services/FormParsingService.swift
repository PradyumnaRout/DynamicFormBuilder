final class FormParsingService {
    static let shared = FormParsingService()
    private init() {}

    func loadFormConfig(from fileName: String = "form_config") async throws -> FormConfig {
        #if DEBUG
        print("[FormParsingService] Loading '\(fileName).json'")
        #endif

        let config = try await JSONLoader.shared.load(FormConfig.self, from: fileName)

        #if DEBUG
        let known = config.fields.filter(\.isKnown).count
        let unknown = config.fields.count - known
        print("[FormParsingService] Parsed \(known) known fields, \(unknown) unknown/ignored.")
        #endif

        return config
    }
}
