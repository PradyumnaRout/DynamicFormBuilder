# DynamicFormBuilder

A production-quality **Server-Driven UI** form engine built with SwiftUI. The entire form — its fields, layout order, validation rules, and visual theme — is driven by a local JSON configuration file. No UI is hardcoded.

---

## Overall Approach & Architecture

The project is structured in strict vertical layers. Each layer has one responsibility and communicates only with the layer directly below it.

```
JSON (form_config.json)
        ↓
  Parsing Layer          JSONLoader  →  FormParsingService
        ↓
  Model Layer            FormConfig  →  [FormField]  →  typed models
        ↓
  ViewModel Layer        FormViewModel  (state, validation, submission)
        ↓
  View Layer             FormRendererView  →  DynamicFieldView  →  field views
```

### MVVM

| Role | Type | Responsibility |
|---|---|---|
| **Model** | `FormConfig`, `FormField`, field models | Pure data, Codable, zero UI imports |
| **ViewModel** | `FormViewModel` | State, value mutation, validation orchestration, submission |
| **View** | `FormRendererView` + field views | Render only — reads from VM, writes back through VM |

### Polymorphic Decoding

The `"fields"` array in JSON contains heterogeneous objects. A single `FormField` enum with a custom `init(from:)` performs a two-pass decode — first reads only the `"type"` key to identify the component, then re-uses the same `Decoder` cursor to decode the full object into the correct strongly-typed model. Unrecognised types (e.g. `DATE_PICKER`) decode silently as `.unknown` and are filtered out by `sortedKnownFields`, so the app never crashes on a future field type it doesn't yet support.

### Validation Pipeline

Validation is built from small composable `FieldValidator` protocol conformances — `RequiredValidator`, `MaxLengthValidator`, `RegexValidator`, `URLValidator`. `ValidationService` assembles the right chain per field type and subtype at runtime. Each mutator in `FormViewModel` calls `validateField(id:)` immediately, so error state is always in sync with input state.

### Theme Engine

`ThemeManager` is a `@MainActor` `ObservableObject` singleton. It is seeded with `Theme.default` at launch and updated the moment `FormConfig` finishes decoding. It is injected at the root via `.environmentObject` so every view in the hierarchy reads the same live theme without prop-drilling.

### Keyboard Focus

`@FocusState<String?>` lives in `FormRendererView` and is threaded down to text field views as `FocusState<String?>.Binding`. `FormViewModel` computes `focusableFieldIds` — the ordered list of text-only field IDs — and exposes `nextFocusableId(after:)` / `previousFocusableId(before:)` so the toolbar arrows and return-key handler can advance focus without the view needing to know anything about field ordering.

---

## Project Structure

```
DynamicFormBuilder/
├── Models/
│   ├── Enums/
│   │   ├── ComponentType.swift       — TEXT | DROPDOWN | TOGGLE | CHECKBOX | COLOR_PICKER | unknown
│   │   └── TextSubtype.swift         — PLAIN | MULTILINE | NUMBER | URI | SECURE
│   ├── FormField.swift               — Polymorphic enum + computed extensions
│   ├── FormConfig.swift              — Root model, sortedKnownFields
│   ├── Theme.swift                   — Hex color strings + Theme.default
│   ├── TextFieldModel.swift
│   ├── DropdownFieldModel.swift
│   ├── ToggleFieldModel.swift
│   ├── CheckboxFieldModel.swift
│   ├── ColorPickerFieldModel.swift
│   └── DropdownOption.swift
├── Services/
│   ├── JSONLoader.swift              — Generic async bundle loader
│   ├── FormParsingService.swift      — Wraps loader, debug logging
│   └── FormError.swift              — Typed errors + DecodingError formatting
├── Validation/
│   ├── FieldValue.swift              — Typed union: string | bool | strings | empty
│   ├── ValidationResult.swift        — .valid | .invalid(String)
│   ├── FieldValidator.swift          — Protocol
│   ├── ValidationService.swift       — Assembles chains, validates all
│   └── Validators/
│       ├── RequiredValidator.swift
│       ├── MaxLengthValidator.swift
│       ├── RegexValidator.swift      — Full-string match enforced
│       └── URLValidator.swift        — URL(string:) + scheme allowlist
├── Theme/
│   ├── ThemeManager.swift            — @MainActor singleton ObservableObject
│   └── Color+Hex.swift               — init(hex:) + toHex()
├── ViewModels/
│   └── FormViewModel.swift           — State, focus chain, isSubmitEnabled, payload
├── Views/
│   ├── FormRendererView.swift        — Root: loading | error | form
│   ├── DynamicFieldView.swift        — Type-safe dispatch to field views
│   ├── Modifiers/
│   │   └── OnChangeCompat.swift      — iOS 16/17 onChange compatibility
│   └── Fields/
│       ├── ValidatedFieldContainer.swift   — Reusable label + animated error wrapper
│       ├── DynamicTextFieldView.swift      — All 5 subtypes
│       ├── DynamicDropdownFieldView.swift  — Sheet picker, single/multi
│       ├── DynamicToggleFieldView.swift
│       ├── DynamicCheckboxFieldView.swift  — AttributedString rich text
│       └── DynamicColorPickerFieldView.swift — Swatch + hex label + ColorPicker
└── LocalJsons/
    └── form_config.json
```

---

## Product Decisions

### 1. Unknown field types decode as `.unknown` rather than throwing

The JSON may contain field types the current app version does not support (the `DATE_PICKER` and `COLOR_PICKER` fields demonstrated this). Two options existed:

- **Throw a `DecodingError`** — the entire `fields` array fails and the form does not load.
- **Silently produce `.unknown`** — unrecognised fields are filtered out; all other fields render normally.

The second approach was chosen because a form that partially renders is more useful than a completely blank screen. It also means the server can add new field types without forcing a client update. `sortedKnownFields` filters `.unknown` entries so they never reach the view layer. `isKnown` is a single computed property on `FormField` that makes this filtering trivial.

### 2. `FieldValue` stores color as `.string(hex)` — not a dedicated `.color` case

When `COLOR_PICKER` was added, the question was whether `FieldValue` needed a new `case color(Color)`. It does not, for two reasons:

- `Color` is not `Codable` and is not `Equatable` in a stable way across OS versions, which would have broken the `Equatable` conformance on `FieldValue` and made `validationResults` diffs unreliable.
- The submission payload needs a serialisable value. A hex string (`"#FF5733"`) is directly usable in any JSON payload without an extra conversion step.

`Color+Hex.swift` provides `init(hex:)` and `toHex()` as the conversion boundary. The view converts `Color → hex` on write and `hex → Color` on read. The rest of the system treats color values identically to any other string field.

### 3. URL validation is enforced by subtype, not by JSON configuration

The `destination_url` field uses `subtype: "URI"`. The initial implementation placed the URL regex pattern in the JSON (`"regex": "^https?://..."`). This was reverted because:

- Regex-based URL validation is fragile — it rejects valid internationalised domain names (IDNs) and IPv6 addresses that `Foundation`'s `URL` parser handles correctly.
- It creates a contract risk: if the server omits the regex, validation silently disappears.

Instead, `ValidationService.validateText` unconditionally appends a `URLValidator` for every `.uri` subtype field. `URLValidator` uses `URL(string:)` with a scheme allowlist (`http`, `https`) and a non-nil host check — the same parser the OS uses everywhere. The JSON `"regex"` key still exists for custom patterns on other field types; URI just has a guaranteed baseline.

---

## What I Would Improve With More Time

**1. DATE_PICKER component**  
A `DATE_PICKER` field already appears in the JSON. The full stack — `DatePickerFieldModel`, `DynamicDatePickerFieldView`, validation — is straightforward to add following the same pattern as `COLOR_PICKER`. It was deliberately left as `.unknown` to demonstrate that the safe-ignore mechanism works in practice.

**2. Accessibility**  
Every field view needs `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityValue`. The error message from `ValidatedFieldContainer` should be posted as an `UIAccessibility.post(notification: .announcement, argument:)` when it appears so VoiceOver users hear validation feedback immediately.

**3. Snapshot tests**  
The unit tests cover JSON parsing thoroughly. UI regression would be better covered with snapshot tests (`swift-snapshot-testing`) on each field view across light/dark theme and all validation states (valid, invalid, empty).

**4. Dependency injection for `ThemeManager` and services**  
All services are singletons accessed via `.shared`. For testability, `FormViewModel` should receive `ThemeManager` as an injected dependency rather than calling `ThemeManager.shared.apply(...)` directly. This would allow unit tests to verify theme application without side-effecting the shared instance.

**5. Scroll-to-error on submission**  
When the user taps Submit and multiple fields are invalid, the form should scroll to the first invalid field and set focus to it if it is a text field. Currently it only shows the error indicators in place.

**6. Haptic feedback**  
Validation failures and successful submission benefit from haptic feedback (`UINotificationFeedbackGenerator`) to reinforce the result without the user needing to read error text.

---

## What I Got Stuck On & How I Worked Through It

**`onChange` iOS version compatibility**  
SwiftUI's two-parameter `onChange(of:) { oldValue, newValue in }` closure was introduced in iOS 17. The project's deployment target caused the compiler to reject it. The fix was a `View+OnChangeCompat` extension that branches on `#available(iOS 17, *)` — the iOS 17 path uses the two-parameter form, the iOS 16 path uses the single-parameter `perform:` overload. Both paths expose only `newValue` to callers, keeping the call site identical regardless of OS version.

**Polymorphic decoding — same `Decoder` instance for two passes**  
The first attempt at polymorphic decoding opened a keyed container for `"type"`, then tried to open a second keyed container with all keys on the same container. This produced a `DecodingError.keyNotFound` because the narrow `CodingKeys` enum only declared `case type`. The fix was to keep the first container strictly for the type-peek, then pass the original `decoder` (not the container) to each model's `init(from:)`. The decoder's cursor had not advanced, so each model received the full JSON object with all its keys available.

**`RegexValidator` partial match bug**  
The initial implementation used `regex.firstMatch(in: text, range: fullRange) != nil`, which returns `true` if the pattern matches *anywhere* in the string. A value like `"  https://good.com  "` (with spaces) would pass a URL regex because the pattern matched the substring in the middle. The fix was to compare `match.range == fullRange` — the match must span the entire string, not just contain a matching substring.

---

## Requirements Checklist

| Requirement | Status |
|---|---|
| MVVM architecture | ✅ |
| Entire UI driven by local JSON | ✅ |
| Offline only | ✅ |
| Codable-based parsing | ✅ |
| Dynamic rendering | ✅ |
| Validation support (required, max_length, regex, URL) | ✅ |
| Reusable component strategy | ✅ |
| Enum separation for types and subtypes | ✅ |
| Unknown component types ignored safely | ✅ |
| TEXT — PLAIN, MULTILINE, NUMBER, URI, SECURE | ✅ |
| DROPDOWN — single and multi-select | ✅ |
| TOGGLE | ✅ |
| CHECKBOX — rich text with clickable metadata links | ✅ |
| COLOR_PICKER | ✅ |
| Dynamic keyboard focus (Next / Done toolbar) | ✅ |
| Submit disabled until required fields filled | ✅ |
| Hex color theme engine | ✅ |
| `onChange` iOS 16/17 compatibility | ✅ |
| XCTest polymorphic parsing tests | ✅ |
