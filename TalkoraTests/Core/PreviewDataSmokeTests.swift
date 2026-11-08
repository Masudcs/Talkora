#if DEBUG
@testable import Talkora
import XCTest
@testable import Core
@testable import Mock
@testable import Calls
@testable import Messaging
@testable import ContactsFeature
@testable import Notifications
@testable import Onboarding
@testable import Payments
@testable import Privacy
@testable import Profile
@testable import Stories

/// Guards the `#Preview` setup: every preview ViewModel must build from the fixtures without
/// crashing, and `load()` must leave the canned state alone.
@MainActor
final class PreviewDataSmokeTests: XCTestCase {
    private let scenarios: [PreviewScenario] = [.loaded, .loading, .empty, .failed]

    func test_previewData_isPopulated() {
        XCTAssertFalse(PreviewData.users.isEmpty)
        XCTAssertFalse(PreviewData.conversations.isEmpty)
        XCTAssertFalse(PreviewData.calls.isEmpty)
        XCTAssertFalse(PreviewData.stories.isEmpty)
        XCTAssertFalse(PreviewData.channels.isEmpty)
        XCTAssertFalse(PreviewData.communities.isEmpty)
        XCTAssertFalse(PreviewData.transactions.isEmpty)
        XCTAssertFalse(PreviewData.messages(in: PreviewData.directConversation.id).isEmpty)
        XCTAssertTrue(PreviewData.adminChannel.isAdmin(PreviewData.currentUser.id))
    }

    func test_listViewModels_buildForEveryScenario() {
        for scenario in scenarios {
            _ = ConversationListViewModel(previewScenario: scenario)
            _ = CallLogViewModel(previewScenario: scenario)
            _ = ContactsViewModel(previewScenario: scenario)
            _ = StatusViewModel(previewScenario: scenario)
            _ = ChannelDirectoryViewModel(previewScenario: scenario)
            _ = WalletViewModel(previewScenario: scenario)
        }
    }

    func test_detailViewModels_buildForEveryScenario() {
        for scenario in scenarios {
            _ = ChatThreadViewModel(previewScenario: scenario)
            _ = ChatThreadViewModel(previewScenario: scenario, isGroup: true)
            _ = GroupInfoViewModel(previewScenario: scenario)
            _ = ChannelDetailViewModel(previewScenario: scenario)
            _ = ChannelDetailViewModel(previewScenario: scenario, isAdmin: true)
        }
        _ = CommunityDetailViewModel()
        _ = StoryViewerViewModel()
    }

    func test_load_onPreviewViewModel_keepsCannedState() async {
        let viewModel = ConversationListViewModel(previewScenario: .failed)

        await viewModel.load()

        XCTAssertNotNil(viewModel.state.error)
    }

    func test_chatThreadPreview_exposesParticipantAndMessages() {
        let direct = ChatThreadViewModel(previewScenario: .loaded)
        XCTAssertNotNil(direct.otherParticipant)
        XCTAssertFalse(direct.messages.isEmpty)

        let group = ChatThreadViewModel(previewScenario: .loaded, isGroup: true)
        XCTAssertFalse(group.groupMembers.isEmpty)
    }

    func test_onboardingFormPreviews_matchTheirScenario() {
        XCTAssertTrue(PhoneEntryViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(PhoneEntryViewModel(previewScenario: .empty).canSubmit)
        XCTAssertNotNil(PhoneEntryViewModel(previewScenario: .invalid).validationMessage)
        XCTAssertTrue(PhoneEntryViewModel(previewScenario: .submitting).state.isLoading)
        XCTAssertNotNil(PhoneEntryViewModel(previewScenario: .failed).state.error)

        XCTAssertTrue(OTPVerificationViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(OTPVerificationViewModel(previewScenario: .invalid).canSubmit)
        XCTAssertTrue(OTPVerificationViewModel(previewScenario: .submitting).verifyState.isLoading)

        XCTAssertTrue(UsernameLoginViewModel(previewScenario: .filled).canSubmit)
        XCTAssertNotNil(UsernameLoginViewModel(previewScenario: .invalid).identifierMessage)

        XCTAssertTrue(ProfileSetupViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(ProfileSetupViewModel(previewScenario: .empty).canSubmit)

        XCTAssertTrue(PINSetupViewModel(previewScenario: .filled).canSubmit)
        XCTAssertTrue(PINSetupViewModel(previewScenario: .invalid).pinsMismatch)

        XCTAssertTrue(QRLoginViewModel(previewScenario: .submitting).state.isLoading)
        XCTAssertNotNil(QRLoginViewModel(previewScenario: .failed).state.error)
    }

    func test_settingsPreviews_matchTheirScenario() async {
        for scenario in scenarios {
            _ = ProfileViewModel(previewScenario: scenario)
            _ = DataUsageViewModel(previewScenario: scenario)
            _ = PrivacyViewModel(previewScenario: scenario)
        }
        XCTAssertNotNil(ProfileViewModel(previewScenario: .loaded).user)
        XCTAssertNotNil(ProfileViewModel(previewScenario: .failed).userState.error)
        XCTAssertGreaterThan(DataUsageViewModel(previewScenario: .loaded).totalBytes, 0)
        XCTAssertNotNil(DataUsageViewModel(previewScenario: .loaded).exportFileURL)
        XCTAssertTrue(PrivacyViewModel(previewScenario: .loaded).isAppLockEnabled)
        XCTAssertFalse(PrivacyViewModel(previewScenario: .loaded).blockedUsers.isEmpty)

        let notifications = NotificationSettingsViewModel(previewStatus: .authorized)
        XCTAssertTrue(notifications.isAuthorized)
        XCTAssertFalse(notifications.groupConversations.isEmpty)
        await notifications.load()
        XCTAssertTrue(notifications.isAuthorized)
        XCTAssertFalse(NotificationSettingsViewModel(previewStatus: .denied).isAuthorized)
    }

    func test_formPreviews_forProfileAndPinScreens_matchTheirScenario() {
        XCTAssertTrue(EditProfileViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(EditProfileViewModel(previewScenario: .empty).canSubmit)
        XCTAssertFalse(EditProfileViewModel(previewScenario: .invalid).canSubmit)
        XCTAssertFalse(EditProfileViewModel(previewScenario: .filled).avatarChoices.isEmpty)

        XCTAssertTrue(AppLockViewModel(previewScenario: .filled).canSubmit)
        XCTAssertFalse(AppLockViewModel(previewScenario: .invalid).canSubmit)
        XCTAssertTrue(AppLockViewModel(previewScenario: .submitting).isVerifying)
        XCTAssertNotNil(AppLockViewModel(previewScenario: .failed).errorMessage)

        XCTAssertTrue(SetAppLockPINViewModel(previewScenario: .filled).canSubmit)
        XCTAssertTrue(SetAppLockPINViewModel(previewScenario: .invalid).pinsMismatch)
        XCTAssertTrue(SetAppLockPINViewModel(previewScenario: .submitting).isSaving)
        XCTAssertNotNil(SetAppLockPINViewModel(previewScenario: .failed).error)
    }
}
#endif
