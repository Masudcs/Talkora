@testable import Talkora
import XCTest
@testable import Core
@testable import Onboarding

final class PhoneNumberValidatorTests: XCTestCase {
    func test_validate_withLocalElevenDigitNumber_shouldReturnInternationalForm() {
        XCTAssertEqual(try? PhoneNumberValidator.validate("01712345678").get(), "+8801712345678")
    }

    func test_validate_withEveryOperatorPrefix_shouldSucceed() {
        for operatorDigit in 3...9 {
            let number = "01\(operatorDigit)12345678"
            XCTAssertNotNil(try? PhoneNumberValidator.validate(number).get(), number)
        }
    }

    func test_validate_withCountryCodeForms_shouldNormalizeToSameNumber() {
        let inputs = ["+8801912345678", "8801912345678", "008801912345678", "+880 1912-345678"]
        for input in inputs {
            XCTAssertEqual(try? PhoneNumberValidator.validate(input).get(), "+8801912345678", input)
        }
    }

    func test_validate_withSpacesAndDashes_shouldIgnoreThem() {
        XCTAssertEqual(try? PhoneNumberValidator.validate(" 01812-345 678 ").get(), "+8801812345678")
    }

    func test_validate_withTenDigits_shouldReturnTooShort() {
        XCTAssertEqual(PhoneNumberValidator.validate("0171234567"), .failure(.tooShort))
    }

    func test_validate_withTwelveDigits_shouldReturnTooLong() {
        XCTAssertEqual(PhoneNumberValidator.validate("017123456789"), .failure(.tooLong))
    }

    func test_validate_withUnsupportedOperatorPrefix_shouldReturnInvalidPrefix() {
        XCTAssertEqual(PhoneNumberValidator.validate("01212345678"), .failure(.invalidPrefix))
        XCTAssertEqual(PhoneNumberValidator.validate("02712345678"), .failure(.invalidPrefix))
    }

    func test_validate_withLettersOrForeignNumber_shouldFail() {
        XCTAssertEqual(PhoneNumberValidator.validate("0171234abcd"), .failure(.invalidCharacters))
        XCTAssertEqual(PhoneNumberValidator.validate("+15551234567"), .failure(.invalidPrefix))
    }
}
