import SwiftUI
import Core
import CommonUI

/// Full-screen voice/video call UI. Dismisses itself as soon as the view model reaches `.ended`; incoming ringing calls show answer/decline, everything else shows mute/camera/hang up.
struct CallScreen: View {
    let request: ActiveCallRequest
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CallViewModel

    init(request: ActiveCallRequest, viewModel: CallViewModel? = nil) {
        self.request = request
        _viewModel = State(wrappedValue: viewModel ?? CallViewModel(request: request))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                TalkoraAvatar(name: request.counterpartName, size: 120)
                Text(request.counterpartName)
                    .font(.title)
                    .foregroundStyle(.white)
                statusText

                if viewModel.status == .connected {
                    NetworkQualityBadge(quality: viewModel.networkQuality)
                }
                if viewModel.isDegradedToAudioOnly {
                    Text("Weak connection — switched to audio only")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()
                controls
            }
            .padding(24)
        }
        // start() places the call record and, for outgoing calls, begins the simulated ring.
        .task { await viewModel.start() }
        .onChange(of: viewModel.status) {
            // Ending is driven by the view model (hang up, decline or remote end); the screen only reacts to it.
            if viewModel.status == .ended { dismiss() }
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch viewModel.status {
        case .ringing:
            Text(request.direction == .outgoing ? "Calling…" : "Incoming \(request.type == .video ? "video" : "voice") call…")
                .foregroundStyle(.white.opacity(0.8))
        case .connected:
            Text(formattedElapsed)
                .foregroundStyle(.white.opacity(0.8))
                .monospacedDigit()
        case .ended:
            Text("Call ended")
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var formattedElapsed: String {
        let total = Int(viewModel.elapsed)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    @ViewBuilder
    private var controls: some View {
        if viewModel.status == .ringing, request.direction == .incoming {
            HStack(spacing: 32) {
                CallControlButton(systemImage: "phone.down.fill", background: .red) {
                    Task { await viewModel.decline() }
                }
                CallControlButton(systemImage: "phone.fill", background: .green) {
                    viewModel.answer()
                }
            }
        } else {
            HStack(spacing: 32) {
                CallControlButton(systemImage: viewModel.isMuted ? "mic.slash.fill" : "mic.fill") {
                    viewModel.isMuted.toggle()
                }
                if request.type == .video, !viewModel.isDegradedToAudioOnly {
                    CallControlButton(systemImage: viewModel.isCameraOn ? "video.fill" : "video.slash.fill") {
                        viewModel.isCameraOn.toggle()
                    }
                }
                CallControlButton(systemImage: "phone.down.fill", background: .red) {
                    Task { await viewModel.hangUp() }
                }
            }
        }
    }
}

private struct CallControlButton: View {
    let systemImage: String
    var background: Color = Color.white.opacity(0.25)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(background)
                .clipShape(Circle())
        }
    }
}

/// Connection-quality indicator shown only while connected.
private struct NetworkQualityBadge: View {
    let quality: NetworkQuality

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(color)
    }

    private var iconName: String {
        switch quality {
        case .good: return "wifi"
        case .fair: return "wifi.exclamationmark"
        case .poor: return "wifi.slash"
        }
    }

    private var label: String {
        switch quality {
        case .good: return "Good connection"
        case .fair: return "Fair connection"
        case .poor: return "Poor connection"
        }
    }

    private var color: Color {
        switch quality {
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

#if DEBUG
@MainActor private func callPreview(_ scenario: CallPreviewScenario) -> some View {
    let vm = CallViewModel(previewScenario: scenario)
    return CallScreen(request: vm.request, viewModel: vm)
}

#Preview("Incoming Ringing") { callPreview(.incomingRinging) }
#Preview("Outgoing Ringing") { callPreview(.outgoingRinging) }
#Preview("Connected Voice") { callPreview(.connectedVoice) }
#Preview("Connected Video") { callPreview(.connectedVideo) }
#Preview("Degraded to Audio") { callPreview(.degradedVideo) }
#Preview("Ended") { callPreview(.ended) }
#endif
