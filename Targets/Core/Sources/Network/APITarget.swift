import Foundation
import Moya

/// How a target answers when stubbed. Only `EndpointTarget` overrides it today, and nothing reads the value yet.
public enum StubResponseKind: Sendable {
    case disabled, success, failure, error
}

/// Describes one API endpoint for `APIProvider`: a Moya `TargetType` plus cache policy and stub
/// data. One enum per feature conforms to this (see `Core/Network/*API.swift`).
public protocol APITarget: TargetType {
    var cachePolicy: URLRequest.CachePolicy { get }

    var stubResponseType: StubResponseKind { get }
    var stubStatusCode: Int { get }
    var stubData: Data? { get }
}

/// Defaults: no extra headers, always reload from the network, stubbing off. The stub status and body can be overridden per case through environment variables (see below).
public extension APITarget {
    static var queueLabel: String { "com.talkora.network.\(Self.self)" }

    var headers: [String: String]? { nil }
    var cachePolicy: URLRequest.CachePolicy { .reloadIgnoringLocalAndRemoteCacheData }

    // UI tests can pass canned responses through the environment:
    //   talkora-stub-status-<case> = status code, <case> = JSON body.
    var stubResponseType: StubResponseKind { .disabled }
    var stubStatusCode: Int {
        ProcessInfo.processInfo.environment["\(uiTestEnvKeyResponseStatusCode)-\(self)"].flatMap(Int.init) ?? 200
    }
    var stubData: Data? {
        ProcessInfo.processInfo.environment["\(self)"]?.data(using: .utf8)
    }
    var sampleData: Data { stubData ?? .init() }
}

/// Command-line argument that switches every `APIProvider` to stubbed responses.
public let uiTestArgEnable = "talkora-stub-network"
/// Environment key prefix for a per-target stub status code, suffixed with `-<case name>`.
public let uiTestEnvKeyResponseStatusCode = "talkora-stub-status"
/// Evaluated once at launch.
public let isStubNetworkEnabled = ProcessInfo.processInfo.arguments.contains(uiTestArgEnable)

/// Applies each target's `cachePolicy` to its outgoing request.
public struct CachePolicyPlugin: PluginType {
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let target = target as? APITarget else { return request }
        var request = request
        request.cachePolicy = target.cachePolicy
        return request
    }
}
