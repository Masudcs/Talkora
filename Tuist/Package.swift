// swift-tools-version: 5.10
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "Alamofire": .framework,
        "Moya": .framework,
    ],
    baseSettings: .settings(configurations: [
        .debug(name: "Debug-Development"),
        .debug(name: "Debug-Staging"),
        .debug(name: "Debug-Production"),
        .release(name: "Release-Development"),
        .release(name: "Release-Staging"),
        .release(name: "Release-Production"),
    ])
)
#endif

let package = Package(
    name: "Talkora",
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.3"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.12.0"),
    ]
)
