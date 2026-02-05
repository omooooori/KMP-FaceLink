import SwiftUI
import KMPFaceLink

struct ContentView: View {
    @StateObject private var viewModel = FaceTrackingViewModel()
    @State private var showBlendShapes = false

    var body: some View {
        ZStack {
            // Camera preview background
            ARCameraView(isRunning: $viewModel.isTracking)
                .ignoresSafeArea()

            // Tracking overlay
            VStack {
                // Status bar at top
                HStack {
                    StatusBadge(text: viewModel.statusText, isTracking: viewModel.isTracking)
                    Spacer()
                    Button {
                        showBlendShapes.toggle()
                    } label: {
                        Image(systemName: showBlendShapes ? "list.bullet.circle.fill" : "list.bullet.circle")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .padding()

                Spacer()

                // Head rotation display
                HeadRotationView(text: viewModel.headRotationText)
                    .padding(.horizontal)

                // Blend shapes panel (collapsible)
                if showBlendShapes {
                    BlendShapesPanel(text: viewModel.blendShapesText)
                        .frame(maxHeight: 200)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Control button
                Button(viewModel.isTracking ? "Stop" : "Start") {
                    withAnimation {
                        viewModel.toggleTracking()
                    }
                }
                .buttonStyle(TrackingButtonStyle(isTracking: viewModel.isTracking))
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showBlendShapes)
    }
}

// MARK: - Subviews

struct StatusBadge: View {
    let text: String
    let isTracking: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isTracking ? .green : .gray)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

struct HeadRotationView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct BlendShapesPanel: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TrackingButtonStyle: ButtonStyle {
    let isTracking: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(width: 100, height: 50)
            .background(isTracking ? .red : .blue, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - ViewModel

@MainActor
class FaceTrackingViewModel: ObservableObject {
    @Published var statusText = "Idle"
    @Published var headRotationText = "P: 0.0  Y: 0.0  R: 0.0"
    @Published var blendShapesText = "Tap Start to begin tracking..."
    @Published var isTracking = false

    private var tracker: FaceTracker?
    private var observeTasks: [Task<Void, Never>] = []

    init() {
        let companion = BlendShapeEnhancerConfig.Companion.shared
        let config = FaceTrackerConfig(
            smoothingConfig: SmoothingConfig.Ema(alpha: 0.4),
            enhancerConfig: BlendShapeEnhancerConfig.Default(
                sensitivityOverrides: companion.defaultSensitivityMap,
                deadZoneOverrides: companion.defaultDeadZoneMap,
                geometricBlendWeight: 0.7
            ),
            enableSmoothing: true,
            smoothingFactor: 0.4,
            enableCalibration: false,
            cameraFacing: .front
        )
        tracker = FaceTrackerFactory_iosKt.createFaceTracker(
            platformContext: PlatformContext(),
            config: config
        )
    }

    func toggleTracking() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }

    private func startTracking() {
        guard let tracker = tracker else { return }
        Task {
            try await tracker.start()
            isTracking = true
            statusText = "Tracking"
            observeData()
        }
    }

    private func stopTracking() {
        guard let tracker = tracker else { return }
        cancelObserveTasks()
        Task {
            try await tracker.stop()
            isTracking = false
            statusText = "Stopped"
        }
    }

    private func observeData() {
        guard let tracker = tracker else { return }

        let dataTask = Task { [weak self] in
            for await data in tracker.trackingData {
                guard let self, !Task.isCancelled else { break }
                let head = data.headTransform
                self.headRotationText = String(
                    format: "P: %+.1f  Y: %+.1f  R: %+.1f",
                    head.pitch, head.yaw, head.roll
                )
                let lines = data.blendShapes.sorted { $0.key.name < $1.key.name }
                    .map { "\($0.key.arKitName): \(String(format: "%.3f", $0.value.floatValue))" }
                self.blendShapesText = lines.joined(separator: "\n")
            }
        }

        let stateTask = Task { [weak self] in
            for await state in tracker.state {
                guard let self, !Task.isCancelled else { break }
                switch state {
                case .idle: self.statusText = "Idle"
                case .starting: self.statusText = "Starting..."
                case .tracking: self.statusText = "Tracking"
                case .stopped: self.statusText = "Stopped"
                case .error: self.statusText = "Error"
                default: self.statusText = "Unknown"
                }
            }
        }

        observeTasks = [dataTask, stateTask]
    }

    private func cancelObserveTasks() {
        observeTasks.forEach { $0.cancel() }
        observeTasks = []
    }

    deinit {
        observeTasks.forEach { $0.cancel() }
        tracker?.release()
    }
}

#Preview {
    ContentView()
}
