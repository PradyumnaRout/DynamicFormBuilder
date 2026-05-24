import XCTest
@testable import DynamicFormBuilder

// MARK: - NOTE
// Add a Unit Test target in Xcode: File → New → Target → Unit Testing Bundle
// name it "DynamicFormBuilderTests", then add this file to that target.

final class FormFieldPolymorphicParsingTests: XCTestCase {

    private var decoder: JSONDecoder!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        decoder = JSONDecoder()
    }

    override func tearDownWithError() throws {
        decoder = nil
        try super.tearDownWithError()
    }

    // Convenience: turn a string literal into Data
    private func json(_ string: String) -> Data { Data(string.utf8) }

    // -------------------------------------------------------------------------
    // MARK: - TEXT (all subtypes)
    // -------------------------------------------------------------------------

    func test_text_plain_parsesCorrectly() throws {
        let data = json("""
        {
          "id": "campaign_name", "order": 1, "type": "TEXT", "subtype": "PLAIN",
          "label": "Campaign Name", "required": true,
          "max_length": 20, "default_value": "Summer Sale",
          "error_message": "Name required."
        }
        """)

        let field = try decoder.decode(FormField.self, from: data)

        guard case .text(let model) = field else {
            return XCTFail("Expected .text, got \(field)")
        }
        XCTAssertEqual(model.id,           "campaign_name")
        XCTAssertEqual(model.order,        1)
        XCTAssertEqual(model.subtype,      .plain)
        XCTAssertTrue(model.required)
        XCTAssertEqual(model.maxLength,    20)
        XCTAssertEqual(model.defaultValue, "Summer Sale")
        XCTAssertEqual(model.errorMessage, "Name required.")
    }

    func test_text_multiline_parsesCorrectly() throws {
        let data = json("""
        { "id": "desc", "order": 2, "type": "TEXT", "subtype": "MULTILINE",
          "label": "Description", "required": false, "max_length": 500 }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .text(let model) = field else { return XCTFail("Expected .text") }
        XCTAssertEqual(model.subtype,   .multiline)
        XCTAssertEqual(model.maxLength, 500)
        XCTAssertFalse(model.required)
    }

    func test_text_number_parsesCorrectly() throws {
        let data = json("""
        { "id": "budget", "order": 3, "type": "TEXT", "subtype": "NUMBER",
          "label": "Budget", "required": true, "placeholder": "0.00" }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .text(let model) = field else { return XCTFail("Expected .text") }
        XCTAssertEqual(model.subtype,     .number)
        XCTAssertEqual(model.placeholder, "0.00")
    }

    func test_text_uri_parsesCorrectly() throws {
        let data = json("""
        { "id": "url", "order": 4, "type": "TEXT", "subtype": "URI",
          "label": "URL", "required": true, "placeholder": "https://" }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .text(let model) = field else { return XCTFail("Expected .text") }
        XCTAssertEqual(model.subtype, .uri)
    }

    func test_text_secure_parsesCorrectly() throws {
        let data = json("""
        { "id": "pwd", "order": 5, "type": "TEXT", "subtype": "SECURE",
          "label": "Password", "required": true }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .text(let model) = field else { return XCTFail("Expected .text") }
        XCTAssertEqual(model.subtype, .secure)
    }

    func test_text_missingSubtype_defaultsToPlain() throws {
        // subtype key absent → must fall back to .plain, not throw
        let data = json("""
        { "id": "x", "order": 1, "type": "TEXT", "label": "X", "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .text(let model) = field else { return XCTFail("Expected .text") }
        XCTAssertEqual(model.subtype, .plain)
    }

    func test_text_unknownSubtype_defaultsToPlain() throws {
        // An unrecognised subtype string must not throw — it defaults to .plain
        let data = json("""
        { "id": "x", "order": 1, "type": "TEXT", "subtype": "RICH_TEXT",
          "label": "X", "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .text(let model) = field else { return XCTFail("Expected .text") }
        XCTAssertEqual(model.subtype, .plain)
    }

    func test_text_withRegex_parsesCorrectly() throws {
        let data = json("""
        { "id": "code", "order": 1, "type": "TEXT", "subtype": "PLAIN",
          "label": "Promo Code", "required": true,
          "regex": "^[A-Z]{4}\\\\d{2}$", "error_message": "Invalid code." }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .text(let model) = field else { return XCTFail("Expected .text") }
        XCTAssertNotNil(model.regex)
        XCTAssertEqual(model.errorMessage, "Invalid code.")
    }

    // -------------------------------------------------------------------------
    // MARK: - DROPDOWN
    // -------------------------------------------------------------------------

    func test_dropdown_singleSelect_parsesCorrectly() throws {
        let data = json("""
        {
          "id": "billing", "order": 5, "type": "DROPDOWN", "label": "Billing",
          "required": true, "allow_multiple": false,
          "options": [
            { "id": "opt1", "label": "Option 1" },
            { "id": "opt2", "label": "Option 2" }
          ]
        }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .dropdown(let model) = field else { return XCTFail("Expected .dropdown") }
        XCTAssertFalse(model.allowMultiple)
        XCTAssertEqual(model.options.count, 2)
        XCTAssertEqual(model.options[0].id,    "opt1")
        XCTAssertEqual(model.options[0].label, "Option 1")
    }

    func test_dropdown_multiSelect_withDefaultValues_parsesCorrectly() throws {
        let data = json("""
        {
          "id": "networks", "order": 4, "type": "DROPDOWN", "label": "Networks",
          "required": true, "allow_multiple": true,
          "options": [{ "id": "g", "label": "Google" }, { "id": "m", "label": "Meta" }],
          "default_values": ["g"]
        }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .dropdown(let model) = field else { return XCTFail("Expected .dropdown") }
        XCTAssertTrue(model.allowMultiple)
        XCTAssertEqual(model.defaultValues, ["g"])
    }

    func test_dropdown_emptyOptions_parsesWithoutThrowing() throws {
        let data = json("""
        { "id": "d", "order": 1, "type": "DROPDOWN", "label": "D",
          "required": false, "options": [] }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .dropdown(let model) = field else { return XCTFail("Expected .dropdown") }
        XCTAssertTrue(model.options.isEmpty)
    }

    // -------------------------------------------------------------------------
    // MARK: - TOGGLE
    // -------------------------------------------------------------------------

    func test_toggle_defaultTrue_parsesCorrectly() throws {
        let data = json("""
        { "id": "ai", "order": 8, "type": "TOGGLE", "label": "Enable AI",
          "default_value": true, "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .toggle(let model) = field else { return XCTFail("Expected .toggle") }
        XCTAssertTrue(model.defaultValue)
        XCTAssertFalse(model.required)
    }

    func test_toggle_missingDefaultValue_isFalse() throws {
        // default_value absent → must fall back to false, not throw
        let data = json("""
        { "id": "t", "order": 1, "type": "TOGGLE", "label": "T", "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .toggle(let model) = field else { return XCTFail("Expected .toggle") }
        XCTAssertFalse(model.defaultValue)
    }

    // -------------------------------------------------------------------------
    // MARK: - CHECKBOX
    // -------------------------------------------------------------------------

    func test_checkbox_withMetadataAndClickableColor_parsesCorrectly() throws {
        let data = json("""
        {
          "id": "legal", "order": 10, "type": "CHECKBOX",
          "label": "I agree to Terms of Service and Privacy Policy.",
          "required": true,
          "metadata": {
            "Terms of Service": "https://example.com/terms",
            "Privacy Policy":   "https://example.com/privacy"
          },
          "clickable_text_color": "#BB86FC",
          "error_message": "Must accept."
        }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .checkbox(let model) = field else { return XCTFail("Expected .checkbox") }
        XCTAssertEqual(model.metadata?["Terms of Service"], "https://example.com/terms")
        XCTAssertEqual(model.metadata?["Privacy Policy"],   "https://example.com/privacy")
        XCTAssertEqual(model.clickableTextColor, "#BB86FC")
        XCTAssertTrue(model.required)
        XCTAssertEqual(model.errorMessage, "Must accept.")
    }

    func test_checkbox_withoutMetadata_parsesCorrectly() throws {
        let data = json("""
        { "id": "cb", "order": 1, "type": "CHECKBOX", "label": "Accept", "required": true }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .checkbox(let model) = field else { return XCTFail("Expected .checkbox") }
        XCTAssertNil(model.metadata)
        XCTAssertNil(model.clickableTextColor)
    }

    // -------------------------------------------------------------------------
    // MARK: - COLOR_PICKER
    // -------------------------------------------------------------------------

    func test_colorPicker_withDefaultValue_parsesCorrectly() throws {
        let data = json("""
        { "id": "brand_color", "order": 6, "type": "COLOR_PICKER",
          "label": "Brand Color", "required": true, "default_value": "#FF5733" }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .colorPicker(let model) = field else { return XCTFail("Expected .colorPicker") }
        XCTAssertEqual(model.id,           "brand_color")
        XCTAssertEqual(model.defaultValue, "#FF5733")
        XCTAssertTrue(model.required)
    }

    func test_colorPicker_withoutDefaultValue_parsesCorrectly() throws {
        let data = json("""
        { "id": "c", "order": 1, "type": "COLOR_PICKER", "label": "Color", "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .colorPicker(let model) = field else { return XCTFail("Expected .colorPicker") }
        XCTAssertNil(model.defaultValue)
    }

    // -------------------------------------------------------------------------
    // MARK: - Unknown / Unsupported Types
    // -------------------------------------------------------------------------

    func test_unknownType_datePicker_decodesAsUnknown() throws {
        // DATE_PICKER is not in ComponentType → must produce .unknown, not throw
        let data = json("""
        { "id": "date", "order": 6, "type": "DATE_PICKER", "label": "Date", "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .unknown = field else {
            return XCTFail("Expected .unknown for DATE_PICKER, got \(field)")
        }
    }

    func test_unknownType_slider_decodesAsUnknown() throws {
        let data = json("""
        { "id": "s", "order": 1, "type": "SLIDER", "label": "Slider", "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        XCTAssertFalse(field.isKnown, "SLIDER must not be treated as a known field")
    }

    func test_unknownType_emptyTypeString_decodesAsUnknown() throws {
        let data = json("""
        { "id": "e", "order": 1, "type": "", "label": "Empty", "required": false }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        guard case .unknown = field else {
            return XCTFail("Expected .unknown for empty type string")
        }
    }

    func test_unknownType_computedProperties_areSafe() throws {
        // All computed properties on .unknown must return safe fallbacks — no crashes
        let data = json("""
        { "id": "x", "order": 99, "type": "DATE_PICKER", "label": "X", "required": true }
        """)
        let field = try decoder.decode(FormField.self, from: data)
        XCTAssertFalse(field.isKnown)
        XCTAssertFalse(field.isRequired)               // always false for unknown
        XCTAssertEqual(field.fieldId,  "__unknown__")  // sentinel, not the JSON id
        XCTAssertEqual(field.order,    Int.max)        // sorts to the very end
        XCTAssertNil(field.errorMessage)
    }

    // -------------------------------------------------------------------------
    // MARK: - Mixed fields array
    // -------------------------------------------------------------------------

    func test_fieldsArray_withUnknownTypes_doesNotThrow() throws {
        let data = json("""
        [
          { "id": "name",  "order": 1, "type": "TEXT",        "subtype": "PLAIN", "label": "Name",  "required": true  },
          { "id": "date",  "order": 2, "type": "DATE_PICKER",                     "label": "Date",  "required": false },
          { "id": "color", "order": 3, "type": "COLOR_PICKER",                    "label": "Color", "required": false }
        ]
        """)
        let fields = try decoder.decode([FormField].self, from: data)

        XCTAssertEqual(fields.count, 3)
        XCTAssertTrue(fields[0].isKnown,  "TEXT must be known")
        XCTAssertFalse(fields[1].isKnown, "DATE_PICKER must be unknown")
        XCTAssertTrue(fields[2].isKnown,  "COLOR_PICKER must be known")
    }

    // -------------------------------------------------------------------------
    // MARK: - FormConfig — sortedKnownFields
    // -------------------------------------------------------------------------

    func test_sortedKnownFields_filtersUnknownAndSortsByOrder() throws {
        let data = json("""
        {
          "theme": { "background_color": "#000", "text_color": "#FFF",
                     "border_color": "#333", "error_color": "#F00" },
          "form_title": "Test Form",
          "fields": [
            { "id": "c", "order": 3, "type": "TEXT",        "subtype": "PLAIN", "label": "C", "required": false },
            { "id": "d", "order": 2, "type": "DATE_PICKER",                     "label": "D", "required": false },
            { "id": "a", "order": 1, "type": "TOGGLE",                          "label": "A", "required": false },
            { "id": "b", "order": 2, "type": "DROPDOWN",                        "label": "B", "required": false, "options": [] }
          ]
        }
        """)
        let config = try decoder.decode(FormConfig.self, from: data)
        let sorted = config.sortedKnownFields

        // DATE_PICKER removed → 3 known fields
        XCTAssertEqual(sorted.count, 3)

        // Ascending order
        XCTAssertEqual(sorted[0].fieldId, "a")  // order 1
        XCTAssertEqual(sorted[1].fieldId, "b")  // order 2
        XCTAssertEqual(sorted[2].fieldId, "c")  // order 3

        // The unknown field must not appear anywhere
        XCTAssertFalse(sorted.contains { $0.fieldId == "d" })
    }

    // -------------------------------------------------------------------------
    // MARK: - Invalid data — missing required keys
    // -------------------------------------------------------------------------

    func test_invalidData_missingId_throwsDecodingError() {
        let data = json("""
        { "order": 1, "type": "TEXT", "label": "Name", "required": true }
        """)
        XCTAssertThrowsError(try decoder.decode(FormField.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Missing 'id' must throw DecodingError")
        }
    }

    func test_invalidData_missingLabel_throwsDecodingError() {
        let data = json("""
        { "id": "name", "order": 1, "type": "TEXT", "required": true }
        """)
        XCTAssertThrowsError(try decoder.decode(FormField.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Missing 'label' must throw DecodingError")
        }
    }

    func test_invalidData_missingOrder_throwsDecodingError() {
        let data = json("""
        { "id": "name", "type": "TEXT", "label": "Name", "required": true }
        """)
        XCTAssertThrowsError(try decoder.decode(FormField.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Missing 'order' must throw DecodingError")
        }
    }

    func test_invalidData_dropdown_optionsNotArray_throwsDecodingError() {
        let data = json("""
        { "id": "d", "order": 1, "type": "DROPDOWN", "label": "D",
          "required": false, "options": "not_an_array" }
        """)
        XCTAssertThrowsError(try decoder.decode(FormField.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "'options' must be an array")
        }
    }

    func test_invalidData_toggle_defaultValueIsString_throwsDecodingError() {
        // "yes" is not a valid Bool — decoder must throw
        let data = json("""
        { "id": "t", "order": 1, "type": "TOGGLE", "label": "T",
          "required": false, "default_value": "yes" }
        """)
        XCTAssertThrowsError(try decoder.decode(FormField.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "String default_value for TOGGLE must throw")
        }
    }

    func test_invalidData_completelyMalformedJSON_throwsDecodingError() {
        let data = json("{ not valid json }")
        XCTAssertThrowsError(try decoder.decode(FormField.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}
