import Foundation

/// Seed call history for the mock backend.
public enum CallFixtures {
    public static let seed: [CallDTO] = [
        CallDTO(id: "call1", conversationId: "c1", counterpartId: "u2", type: "voice", direction: "outgoing", outcome: "completed", startedAt: "2024-09-20T19:00:00Z", duration: 245),
        CallDTO(id: "call2", conversationId: "c2", counterpartId: "u3", type: "video", direction: "incoming", outcome: "missed", startedAt: "2024-09-20T13:30:00Z", duration: 0),
        CallDTO(id: "call3", conversationId: "c4", counterpartId: "u4", type: "voice", direction: "incoming", outcome: "completed", startedAt: "2024-09-19T20:15:00Z", duration: 512),
        CallDTO(id: "call4", conversationId: "c1", counterpartId: "u2", type: "video", direction: "outgoing", outcome: "declined", startedAt: "2024-09-18T17:05:00Z", duration: 0),
    ]
}
