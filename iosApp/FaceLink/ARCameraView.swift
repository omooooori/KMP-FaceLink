import SwiftUI
import ARKit

/// SwiftUI wrapper for ARSCNView that displays camera preview with face tracking
struct ARCameraView: UIViewRepresentable {
    @Binding var isRunning: Bool

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.automaticallyUpdatesLighting = true
        sceneView.showsStatistics = false
        return sceneView
    }

    func updateUIView(_ sceneView: ARSCNView, context: Context) {
        if isRunning {
            startSession(sceneView)
        } else {
            sceneView.session.pause()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func startSession(_ sceneView: ARSCNView) {
        guard ARFaceTrackingConfiguration.isSupported else { return }

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: Coordinator) {
        sceneView.session.pause()
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        // Can be extended for face mesh rendering in future
    }
}

#Preview {
    ARCameraView(isRunning: .constant(true))
        .ignoresSafeArea()
}
