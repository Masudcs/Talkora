@testable import Talkora
import XCTest
@testable import Core
@testable import Onboarding

@MainActor
final class LoginIdentifierValidatorTests: XCTestCase {
    func test_validate_withWellFormedEmail_shouldReturnLowercasedEmail() {
        let result = try? LoginIdentifierValidator.validate("  Rahim.Uddin+chat@Mail.Example.com ").get()
        XCTAssertEqual(result, .email("rahim.uddin+chat@mail.example.com"))
    }

    func test_validate_withMalformedEmails_shouldReturnInvalidEmail() {
        let inputs = ["rahim@", "@example.com", "rahim@example", "rahim@@example.com", "rahim@exa mple.com",
                      "rahim..uddin@example.com", ".rahim@example.com", "rahim.@example.com", "rahim@example.c"]
        for input in inputs {
            XCTAssertEqual(LoginIdentifierValidator.validate(input), .failure(.invalidEmail), input)
        }
    }

    func test_validate_withValidUsername_shouldReturnUsername() {
        XCTAssertEqual(try? LoginIdentifierValidator.validate("karim_99.dev").get(), .username("karim_99.dev"))
    }

    func test_validate_withShortOrLongUsername_shouldReturnLengthError() {
        XCTAssertEqual(LoginIdentifierValidator.validate("ab"), .failure(.usernameLength))
        XCTAssertEqual(LoginIdentifierValidator.validate(String(repeating: "a", count: 31)), .failure(.usernameLength))
    }

    func test_validate_withBadUsernameCharacters_shouldReturnCharactersError() {
        for input in ["kar im", "karim!", ".karim", "karim.", "ka..rim", "করিম123"] {
            XCTAssertEqual(LoginIdentifierValidator.validate(input), .failure(.usernameCharacters), input)
        }
    }

    func test_validate_withBlankInput_shouldReturnEmpty() {
        XCTAssertEqual(LoginIdentifierValidator.validate("   "), .failure(.empty))
    }

    // MARK: - View model

    func test_login_withInvalidEmail_shouldNotCallRepository() async {
        let stub = StubAuthRepository()
        let viewModel = UsernameLoginViewModel(repository: stub)
        viewModel.identifier = "sara@example"
        viewModel.password = "secret1"

        await viewModel.login()

        XCTAssertFalse(viewModel.canSubmit)
        XCTAssertEqual(stub.loginCallCount, 0)
        XCTAssertEqual(viewModel.identifierMessage, "Enter a valid email address, like name@example.com.")
    }

    func test_login_withMixedCaseEmail_shouldSendLowercasedIdentifier() async {
        let stub = StubAuthRepository()
        stub.loginResult = .success(User(id: "u9", displayName: "Sara", handle: "@sara", avatarURL: nil, status: .online, createdAt: Date()))
        let viewModel = UsernameLoginViewModel(repository: stub)
        viewModel.identifier = "Sara@Example.com"
        viewModel.password = "secret1"

        await viewModel.login()

        XCTAssertEqual(stub.lastLoginIdentifier, "sara@example.com")
        XCTAssertEqual(viewModel.state.value?.id, "u9")
    }
}
