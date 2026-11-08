import Foundation
import Observation
import Core
import Mock

/// Call lifecycle: `ringing` -> `connected` -> `ended`. `ended` is terminal; the screen dismisses on it.
enum CallSessionStatus: Sendable {
    case ringing
    case connected
    case ended
}

/// Improve: an explicit low-bandwidth indicator + a visible "switched to audio only"
/// message instead of a video call silently degrading with no explanation.
enum NetworkQuality: String, CaseIterable, Sendable {
    case good
    case fair
    case poor
}

/// Drives one call session. There is no real media/signalling: the callee answering, the connection
/// quality and the 12% decline chance are simulated with timers so the demo can show every UI state.
@MainActor
@Observable
final class CallViewModel {
    /// The call this session represents; immutable for the lifetime of the screen.
    let request: ActiveCallRequest
    private(set) var status: CallSessionStatus = .ringing
    /// Seconds since `connectedAt`, refreshed once a second by the timer task (so it ticks in whole-second steps).
    private(set) var elapsed: TimeInterval = 0
    private(set) var networkQuality: NetworkQuality = .good
    /// Set while video quality is `.poor`; the screen hides the camera toggle and explains why. Never set for voice calls.
    private(set) var isDegradedToAudioOnly = false
    var isMuted = false
    var isCameraOn = true

    @ObservationIgnored private var isPreview = false
    private let repository: ICallRepository
    private let scheduler: NotificationScheduling
    /// Id of the call-log entry created in `start()`; nil if that request failed, in which case `finish` skips `endCall`.
    private var callRecordId: String?
    private var connectedAt: Date?
    /// Timer, network-simulation and ring tasks are not UI state (hence `@ObservationIgnored`); all are cancelled in `finish` and `deinit`.
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var networkTask: Task<Void, Never>?
    @ObservationIgnored private var ringTask: Task<Void, Never>?

    init(request: ActiveCallRequest, repository: ICallRepository = CallRepository(), scheduler: NotificationScheduling = NotificationScheduler.shared) {
        self.scheduler = scheduler
        self.request = request
        self.repository = repository
    }

    deinit {
        timerTask?.cancel()
        networkTask?.cancel()
        ringTask?.cancel()
    }

    /// Creates the call-log record, then for outgoing calls starts the simulated ring. Incoming calls
    /// stay `.ringing` until `answer()` or `decline()`. A failed `startCall` is ignored (the call still runs, it just isn't logged).
    func start() async {
        guard !isPreview else { return }
        if let call = try? await repository.startCall(
            conversationId: request.conversationId,
            counterpartId: request.counterpartId,
            type: request.type,
            direction: request.direction
        ) {
            callRecordId = call.id
        }

        guard request.direction == .outgoing else { return }

        // Simulated callee: rings 1.5-2.5s, then answers (88%) or declines. The status check avoids connecting after the user already hung up.
        ringTask = Task {
            try? await Task.sleep(nanoseconds: UInt64.random(in: 1_500_000_000...2_500_000_000))
            guard !Task.isCancelled, status == .ringing else { return }
            if Double.random(in: 0...1) < 0.12 {
                await finish(outcome: .declined)
            } else {
                connect()
            }
        }
    }

    /// Accepts an incoming call; ignored unless still ringing.
    func answer() {
        guard status == .ringing else { return }
        connect()
    }

    /// Rejects an incoming call. Recorded as `.declined`, which also raises a missed-call notification (see `finish`).
    func decline() async {
        await finish(outcome: .declined)
    }

    /// Ends the call from the in-call controls. Outcome depends on when it ends: `.completed` once connected,
    /// otherwise `.noAnswer` (outgoing, cancelled while ringing) or `.missed` (incoming).
    func hangUp() async {
        let outcome: CallOutcome = status == .connected ? .completed : (request.direction == .outgoing ? .noAnswer : .missed)
        await finish(outcome: outcome)
    }

    private func connect() {
        status = .connected
        connectedAt = Date()
        startTimer()
        startNetworkSimulation()
    }

    /// Ticks elapsed time from wall-clock `connectedAt` rather than counting ticks, so sleep jitter does not accumulate drift.
    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, let connectedAt else { return }
                elapsed = Date().timeIntervalSince(connectedAt)
            }
        }
    }

    /// Randomly changes quality every 3-6s. For video calls a `.poor` reading flips to audio only and a better one flips back.
    private func startNetworkSimulation() {
        networkTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 3_000_000_000...6_000_000_000))
                guard !Task.isCancelled else { return }
                networkQuality = NetworkQuality.allCases.randomElement() ?? .good
                if request.type == .video {
                    isDegradedToAudioOnly = (networkQuality == .poor)
                }
            }
        }
    }

    /// Single exit path: stops all tasks, marks `.ended` (before the awaits, so the screen dismisses
    /// immediately), persists the outcome with the final `elapsed`, and notifies for incoming missed/declined calls.
    private func finish(outcome: CallOutcome) async {
        ringTask?.cancel()
        timerTask?.cancel()
        networkTask?.cancel()
        status = .ended
        if let callRecordId {
            _ = try? await repository.endCall(callRecordId, outcome: outcome, duration: elapsed)
        }
        if request.direction == .incoming, outcome == .missed || outcome == .declined {
            await scheduler.notifyMissedCall(
                callerName: request.counterpartName,
                conversationId: request.conversationId,
                isMuted: false
            )
        }
    }
}

#if DEBUG
/// Preview-only states for `CallViewModel`; see `init(previewScenario:)`.
enum CallPreviewScenario {
    case incomingRinging
    case outgoingRinging
    case connectedVoice
    case connectedVideo
    case degradedVideo
    case ended
}

extension CallViewModel {
    /// Sets state directly; never starts timers or tasks, and never touches the shared scheduler.
    convenience init(previewScenario scenario: CallPreviewScenario) {
        let counterpart = PreviewData.otherUsers.first ?? PreviewData.currentUser
        let isVideo: Bool
        let direction: CallDirection
        switch scenario {
        case .incomingRinging: isVideo = false; direction = .incoming
        case .outgoingRinging, .connectedVoice, .ended: isVideo = false; direction = .outgoing
        case .connectedVideo, .degradedVideo: isVideo = true; direction = .outgoing
        }
        let request = ActiveCallRequest(
            conversationId: PreviewData.directConversation.id,
            counterpartId: counterpart.id,
            counterpartName: counterpart.displayName,
            type: isVideo ? .video : .voice,
            direction: direction
        )
        self.init(request: request, scheduler: PreviewNotificationScheduler(status: .authorized))
        isPreview = true
        switch scenario {
        case .incomingRinging, .outgoingRinging:
            status = .ringing
        case .connectedVoice, .connectedVideo:
            status = .connected; elapsed = 83
        case .degradedVideo:
            status = .connected; elapsed = 192; networkQuality = .poor; isDegradedToAudioOnly = true
        case .ended:
            status = .ended
        }
    }
}
#endif
