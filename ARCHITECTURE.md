# Talkora architecture

SwiftUI, iOS 17, MVVM with `@Observable` ViewModels. Built with Tuist (`tuist generate`, then open
`Talkora.xcworkspace`; run it again after adding, moving or deleting a Swift file). Three environments, one scheme each: `Talkora-Dev`, `-Staging`, `-Prod`.

## Modules

Layout follows ART 4.0: every module is a Tuist framework with its code in `Targets/<Module>/Sources`. The app target is just
`Talkora/` (`App/`, `Resources/`, `Configuration/`). `Project.swift` lists the modules (`sharedModules`, `featureDependencies`).

| Module | Contents | Depends on |
|---|---|---|
| `Core` | Domain `Models`, `Repositories/<Feature>/` (the `I<Feature>Repository` protocol next to its `<Feature>Repository`, built on `APIClientProtocol`, as in MyStore), `DTOs` + `Mappers`, `Network` (`Endpoint`, `*Routes`, `APIClientProtocol`, `APIClientProvider`, `RealAPIClient`, `APIBackend`, stubs), `MockBackend` (the in-memory fake server `MockAPIClient`, `MockDataStore`, fixtures), `DI`, `Navigation` (`NavController`, `BaseDestination`), `Session` (`AuthSessionStore`, `AppLockManager`), `Notifications`, `Errors`, `Utils` | Moya, Alamofire |
| `CommonUI` | Design system, `NavigationHost`, `PushRowButton`, dumb reusable views, `ThemeStore` | `Core` |
| `Mock` | Debug-only `PreviewData` and `PreviewNotificationScheduler` for `#Preview`s and tests | `Core`, `CommonUI` |
| 11 feature modules: `Calls`, `ContactsFeature`, `MediaSharing`, `Messaging` (chats, groups, bots, channels, search), `Notifications`, `Onboarding`, `Payments`, `Privacy`, `Profile`, `Reactions`, `Stories` | `UI/Screens/<Screen>/` (a `…Screen.swift` plus its `…ViewModel.swift`), `UI/Components`, `Navigation`, `Utils` | `Core`, `CommonUI`, `Mock` (previews only), plus the features it opens, declared in `Project.swift` |
| `Talkora` (app) | `App/`: entry point, `AppShellView` (onboarding vs main vs lock screen), `RootView` (tabs), nothing else: no wiring code, see "Repositories" and "Crossing feature boundaries" | everything |

- **Access.** Everything other targets use is `public` in `Core`, `CommonUI` and `Mock`, with explicit public `init`s. A feature keeps its
  screens and view models internal and exposes only the destinations other features open plus the few entry screens the app embeds
  (`ConversationListScreen`, `StatusScreen`, `ContactsScreen`, `CallLogScreen`, `ProfileScreen`, `OnboardingFlowScreen`,
  `AppLockScreen`), each with a public init that takes no view model. Tests use `@testable import <Module>`.
- **Direction.** `Core` must not reference `Mock/` or the app: the demo OTP code, for example, is passed into `AuthRepository` by
  the composition root. Features reference only the features listed for them in `Project.swift`, and that graph stays acyclic (see "Crossing feature boundaries").
- **Naming.** A module must not share a name with an Apple framework: a module called `Contacts` shadowed the system
  `Contacts.framework` and crashed the UI test runner at launch, hence `ContactsFeature`.
- **Repositories.** Like MyStore, a ViewModel takes its repository in `init` with a concrete default, `init(repository: IChatRepository = ChatRepository())`,
  and every repository can be created with no arguments. They all use `APIClientProvider.shared.client`, chosen on first use from `APIBackend.current`
  (mock by default, stubbed or live via launch argument): the mock backend lives in `Core`, so nothing has to configure it at launch.
  Tests pass stubs (`StubChatRepository()`) or a client (`ChatRepository(api:)`). There is no DI container.
- **Previews.** `PreviewData` lives in `Mock`, so features import it for `#Preview`s only. `PreviewScenario` lives in `Core`.
- **Adding a feature.** Create `Targets/<Name>/Sources`, add it to `featureDependencies` in `Project.swift` with the features it opens (no cycles), put the destinations other features open in `Navigation/`, then run `tuist generate`.
- **Tests** stay central in `TalkoraTests/` (they cross modules); ART 4.0's per-module `Tests` folders are not used. `TalkoraTests/Features/<Module>/` mirrors the modules, one file per ViewModel (`<Name>ViewModelTests.swift`).

Dependency direction: `Screen → ViewModel → IRepository protocol ← Repository → APIClientProtocol`.
Views never touch repositories; ViewModels never touch the network.

## Navigation

`RootView` hosts the tabs; each tab owns a `NavigationStack` (`CommonUI/NavigationHost`) and the `NavController`
that drives it, so a tab keeps its own title, toolbar and search field. Screens push with
`navController.navigateTo(Destination.X(...))`; `NavigationHost` resolves every `BaseDestination`. Each feature
declares its destinations in `Targets/<Module>/Sources/Navigation/` (no central route enum). List rows that push
use `PushRowButton`. Sheets and full-screen covers stay local to the screen that presents them, and a sheet that
needs its own pushes (like `ChatSettingsSheet`) keeps its own `NavigationStack`. A single shared stack with the tabs
inside it was tried and rejected: it drops the tab screens' `navigationTitle`, toolbar and `searchable`.

### Crossing feature boundaries

Each module owns its destinations: a `Destination.X` subclass next to its screen that overrides `getScreen` (as in
ART 4.0). A feature that opens another feature's screen imports that module and pushes it with
`navController.navigateTo(Destination.X())`; present with `Destination.X().presentedScreen()`. Closure parameters
(`onSent`, `onJump`, `onCompleted`) report results back to the presenter.

The feature graph in `Project.swift` (`featureDependencies`) must stay acyclic. Features that open each other live in
one module: that is why chats, groups, bots, channels and search are all in `Messaging`. If a new feature would need to
open a screen that opens it back, put the two in the same module instead of adding a cycle. Shared pieces live in
`Core` (models, the notification service) or `CommonUI` (dumb components such as `MediaThumbnail`,
`ReactionBarView`, `PaymentMessageCard`, `UserSelectionRow`).

## ViewModels and dependencies

- One `@MainActor @Observable` ViewModel per screen, next to the screen. State is `LoadableState<T>`
  (`idle / loading / loaded / empty / failed`) or plain properties for forms.
- ViewModels take their repositories in `init` with a concrete default:
  `init(repository: IChatRepository = ChatRepository())`. Screens build their own
  ViewModel with its own repositories. Tests pass stubs explicitly.
- App-wide state is also a shared default: `AuthSessionStore.shared`, `AppLockManager.shared`,
  `ThemeStore.shared`, `NotificationScheduler.shared` (behind the `NotificationScheduling` protocol).
- Errors are normalized with `error.asAppError`.

## Backends

All repositories share one `APIClientProtocol` (`APIClientProvider.shared`), chosen on first use in `APIClientProvider.makeAPIClient`
by `APIBackend`. Select it with the launch argument `-talkora-backend <mock|stubbed|live>` or the
`TALKORA_BACKEND` environment variable.

| Backend | What it is |
|---|---|
| `mock` (default) | `MockAPIClient`: a stateful in-memory server; edits persist while the app runs |
| `stubbed` | Debug builds only. The real Moya stack answering from `Resources/Stubs/stubs.json` (static canned responses) |
| `live` | The real Moya stack against `AppEnvironment.apiBaseURL`. Not usable yet: there is no sign-in or token storage |

**Stubbed mode.** `StubCatalog` maps `"METHOD /path"` to a response; unknown ids fall back to the generic
`{id}` route. `-talkora-stub-fail "GET /conversations=500,*=503"` (or `TALKORA_STUB_FAIL`) makes
routes fail so error screens can be exercised. All stub code is behind `#if DEBUG`, and `stubs.json` is
excluded from Release bundles (`EXCLUDED_SOURCE_FILE_NAMES` in `Project.swift`).

**Regenerate `stubs.json`** after changing fixtures, DTOs or endpoints:

```
TEST_RUNNER_GENERATE_STUBS=1 TEST_RUNNER_STUBS_OUTPUT_PATH="$PWD/Talkora/Resources/Stubs/stubs.json" \
  xcodebuild test -workspace Talkora.xcworkspace -scheme Talkora-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:TalkoraTests/StubCatalogGeneratorTests
```

## Adding an endpoint or repository method

1. Add a case to the feature's route enum in `Core/Network/*Routes.swift` (it builds the `Endpoint`; repositories never write
   paths inline), add the method to the `I<Feature>Repository` protocol in `Core/Repositories/<Feature>`, and implement it in the feature's `<Feature>Repository`
   with `api.request(FeatureRoutes.case(...))`.
2. Route it in `Targets/Core/Sources/MockBackend/MockAPIClient` (and `MockDataStore` if it needs new state).
3. Call it from `TalkoraTests/Tools/StubTour.swift`, then regenerate `stubs.json` (command above).
   `StubCoverageTests` fails if a repository route has no stub or a tour call isn't answered.

## Previews

Every screen has `#Preview`s inside `#if DEBUG`. Each ViewModel has a debug-only
`init(previewScenario:)` that sets state directly (no repository calls) and an `isPreview` flag that makes
`load()` / `start()` a no-op. Screens accept an injected `viewModel:`. Sample data is `PreviewData`
(`Mock/Preview`), built from the same fixtures as the mock backend; `PreviewScenario` and
`FormPreviewScenario` pick the state. Previews use isolated stores (`PreviewData.defaults`), never the
shared ones. `PreviewDataSmokeTests` and the `PreviewSmoke*Tests` build every preview ViewModel.

## Tests

`TalkoraTests` (unit; stubs in `Support/`) and `TalkoraUITests`. Run everything:

```
xcodebuild test -workspace Talkora.xcworkspace -scheme Talkora-Dev \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

UI tests drive the app with launch arguments (for example `-talkora.session.currentUserId u1` to skip
onboarding, `-talkora-backend stubbed`).

## Known gaps

- `live` needs sign-in and token storage before it can work.
- `AppRoute` and `DeepLinkParser` exist but nothing uses them yet.
- Call and story timers (ring, elapsed time, auto-advance) aren't covered by unit tests.
