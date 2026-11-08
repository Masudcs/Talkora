import Foundation
import Core

/// Validates Bangladeshi mobile numbers: 11 digits in local form, `01` + operator digit
/// (3-9) + 8 digits, e.g. `01712345678`. The country code form (`+8801712345678`,
/// `8801712345678`, `008801712345678`) is accepted too. Spaces, dashes and brackets are ignored.
enum PhoneNumberValidator {
    /// Why a number was rejected; `message(for:)` gives the user-facing text.
    enum ValidationError: Error, Equatable {
        case invalidCharacters
        case tooShort
        case tooLong
        case invalidPrefix
    }

    /// Length of a local number including the leading 0.
    static let localLength = 11

    /// On success returns the number in international form, `+8801XXXXXXXXX`.
    static func validate(_ input: String) -> Result<String, ValidationError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let separators: Set<Character> = [" ", "-", "(", ")"]
        var digits = ""
        for (index, character) in trimmed.enumerated() {
            if character.isASCII, character.isNumber {
                digits.append(character)
            } else if character == "+", index == 0 {
                // A `+` is only allowed as the first character.
                continue
            } else if separators.contains(character) {
                continue
            } else {
                return .failure(.invalidCharacters)
            }
        }

        let local = localDigits(from: digits)
        guard local.count >= localLength else { return .failure(.tooShort) }
        guard local.count == localLength else { return .failure(.tooLong) }
        guard isValidMobilePrefix(local) else { return .failure(.invalidPrefix) }
        return .success("+880" + local.dropFirst())
    }

    /// Strips the country code (880 / 00880) so the remaining digits start with the trunk `0`.
    private static func localDigits(from digits: String) -> String {
        for prefix in ["00880", "880"] where digits.hasPrefix(prefix) {
            return "0" + digits.dropFirst(prefix.count)
        }
        return digits
    }

    /// Mobile numbers start with 013-019.
    private static func isValidMobilePrefix(_ local: String) -> Bool {
        let chars = Array(local)
        guard chars.count >= 3, chars[0] == "0", chars[1] == "1" else { return false }
        return ("3"..."9").contains(chars[2])
    }

    /// User-facing text for each validation failure.
    static func message(for error: ValidationError) -> String {
        switch error {
        case .invalidCharacters: "Use digits only."
        case .tooShort: "Enter all 11 digits of your mobile number."
        case .tooLong: "A mobile number has 11 digits. Remove the extra digits."
        case .invalidPrefix: "Mobile numbers start with 013 to 019, for example 01712345678."
        }
    }
}
