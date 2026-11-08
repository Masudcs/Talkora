import ProjectDescription

/// The only three environments Talkora supports. Each one maps to a Debug and a Release
/// build configuration, an `Environment-<Name>.xcconfig`, and a scheme.
enum BuildEnvironment: String, CaseIterable {
    case development = "Development"
    case staging = "Staging"
    case production = "Production"

    var schemeName: String {
        switch self {
        case .development: "Talkora-Dev"
        case .staging: "Talkora-Staging"
        case .production: "Talkora-Prod"
        }
    }

    var debugName: ConfigurationName { .init(stringLiteral: "Debug-\(rawValue)") }
    var releaseName: ConfigurationName { .init(stringLiteral: "Release-\(rawValue)") }

    /// Lets code use `#if DEVELOPMENT` / `#if STAGING` / `#if PRODUCTION`.
    private var compilationCondition: String { rawValue.uppercased() }

    var configurations: [Configuration] {
        [
            .debug(
                name: debugName,
                settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEBUG \(compilationCondition)"],
                xcconfig: "Talkora/Configuration/Debug-\(rawValue).xcconfig"
            ),
            .release(
                name: releaseName,
                settings: [
                    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) \(compilationCondition)",
                    // Stubbed-backend responses are for development and tests only; keep them out of release bundles.
                    "EXCLUDED_SOURCE_FILE_NAMES": "stubs.json",
                ],
                xcconfig: "Talkora/Configuration/Release-\(rawValue).xcconfig"
            ),
        ]
    }
}

let configurations: [Configuration] = BuildEnvironment.allCases.flatMap(\.configurations)

func scheme(for env: BuildEnvironment) -> Scheme {
    .scheme(
        name: env.schemeName,
        shared: true,
        buildAction: .buildAction(targets: ["Talkora"]),
        testAction: .targets(["TalkoraTests", "TalkoraUITests"], configuration: env.debugName),
        runAction: .runAction(configuration: env.debugName),
        archiveAction: .archiveAction(configuration: env.releaseName),
        profileAction: .profileAction(configuration: env.releaseName),
        analyzeAction: .analyzeAction(configuration: env.debugName)
    )
}

/// Modules follow ART 4.0's layout: `Targets/<Module>/Sources`. Shared modules come first. A feature module declares
/// the other features it opens in `featureDependencies` and owns its destinations (`Destination.X.getScreen`), as in
/// ART 4.0. The feature graph must stay acyclic, so features that open each other live together in `Messaging`.
let sharedModules = ["Core", "CommonUI", "Mock"]
let featureDependencies: [String: [String]] = [
    "Calls": [],
    "ContactsFeature": ["Messaging"], // not "Contacts": that would shadow Apple's Contacts.framework
    "MediaSharing": [],
    "Messaging": ["Calls", "MediaSharing", "Payments", "Reactions"],
    "Notifications": [],
    "Onboarding": [],
    "Payments": [],
    "Privacy": [],
    "Profile": ["Notifications", "Payments", "Privacy"],
    "Reactions": [],
    "Stories": [],
]
let featureModules = featureDependencies.keys.sorted()

/// A framework module. Shared.xcconfig pins PRODUCT_MODULE_NAME to the app's module, so each module needs its own.
func frameworkTarget(name: String, dependencies: [TargetDependency]) -> Target {
    .target(
        name: name,
        destinations: .iOS,
        product: .framework,
        bundleId: "com.talkora.app.\(name.lowercased())",
        deploymentTargets: .iOS("17.0"),
        infoPlist: .default,
        sources: ["Targets/\(name)/Sources/**/*.swift"],
        dependencies: dependencies,
        settings: .settings(
            base: ["PRODUCT_MODULE_NAME": "$(TARGET_NAME:c99extidentifier)"],
            configurations: configurations
        )
    )
}

let moduleTargets: [Target] =
    [
        frameworkTarget(name: "Core", dependencies: [.external(name: "Moya"), .external(name: "Alamofire")]),
        frameworkTarget(name: "CommonUI", dependencies: [.target(name: "Core")]),
        frameworkTarget(name: "Mock", dependencies: [.target(name: "Core"), .target(name: "CommonUI")]),
    ]
    + featureModules.map { module in
        frameworkTarget(
            name: module,
            dependencies: (sharedModules + featureDependencies[module, default: []]).map { .target(name: $0) }
        )
    }

let allModuleDependencies: [TargetDependency] = (sharedModules + featureModules).map { .target(name: $0) }

let project = Project(
    name: "Talkora",
    options: .options(automaticSchemesOptions: .disabled),
    settings: .settings(configurations: configurations),
    targets: moduleTargets + [
        .target(
            name: "Talkora",
            destinations: .iOS,
            product: .app,
            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER)",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .file(path: "Talkora/Resources/Info.plist"),
            sources: ["Talkora/App/**/*.swift"],
            resources: ["Talkora/Resources/Assets.xcassets", "Talkora/Resources/Stubs/**"],
            dependencies: allModuleDependencies,
            settings: .settings(configurations: configurations)
        ),
        .target(
            name: "TalkoraTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.talkora.app.tests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["TalkoraTests/**/*.swift"],
            dependencies: [.target(name: "Talkora")] + allModuleDependencies + [.external(name: "Moya")],
            settings: .settings(
                // Shared.xcconfig pins PRODUCT_MODULE_NAME to the app's module; test bundles need their own.
                base: ["PRODUCT_MODULE_NAME": "$(TARGET_NAME:c99extidentifier)"],
                configurations: configurations
            )
        ),
        .target(
            name: "TalkoraUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.talkora.app.uitests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["TalkoraUITests/**/*.swift"],
            dependencies: [.target(name: "Talkora")],
            settings: .settings(
                // Shared.xcconfig pins PRODUCT_MODULE_NAME to the app's module; test bundles need their own.
                base: ["PRODUCT_MODULE_NAME": "$(TARGET_NAME:c99extidentifier)"],
                configurations: configurations
            )
        ),
    ],
    schemes: BuildEnvironment.allCases.map(scheme(for:))
)
