import Foundation

/// Describes a call the UI wants presented (either "I'm calling someone" or "someone is
/// calling me, simulated"). `Identifiable` so it can back a `.fullScreenCover(item:)`.
public struct ActiveCallRequest: Identifiable, Hashable {
    public let id = UUID()
    public let conversationId: String
    public let counterpartId: String
    public let counterpartName: String
    public let type: CallType
    public let direction: CallDirection

    public init(conversationId: String, counterpartId: String, counterpartName: String, type: CallType, direction: CallDirection) {
        self.conversationId = conversationId
        self.counterpartId = counterpartId
        self.counterpartName = counterpartName
        self.type = type
        self.direction = direction
    }
}
