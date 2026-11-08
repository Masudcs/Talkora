import Foundation

public enum BotRoutes: EndpointConvertible {
    case allBots

    public var endpoint: Endpoint {
        switch self {
        case .allBots:
            return Endpoint(path: "/bots")
        }
    }
}
