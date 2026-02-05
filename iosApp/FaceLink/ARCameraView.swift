import SwiftUI
import ARKit
import SceneKit

/// SwiftUI wrapper for ARSCNView that displays camera preview with face mesh overlay
struct ARCameraView: UIViewRepresentable {
    @Binding var isRunning: Bool
    @Binding var showLandmarks: Bool

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.delegate = context.coordinator
        sceneView.automaticallyUpdatesLighting = true
        sceneView.showsStatistics = false
        context.coordinator.sceneView = sceneView
        return sceneView
    }

    func updateUIView(_ sceneView: ARSCNView, context: Context) {
        context.coordinator.showLandmarks = showLandmarks

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
        guard sceneView.session.configuration == nil else { return }

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        configuration.maximumNumberOfTrackedFaces = 1
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: Coordinator) {
        sceneView.session.pause()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSCNViewDelegate {
        weak var sceneView: ARSCNView?
        var showLandmarks = true
        private var faceNode: SCNNode?

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let device = sceneView?.device,
                  let faceGeometry = ARSCNFaceGeometry(device: device, fillMesh: true) else {
                return nil
            }

            let node = SCNNode(geometry: faceGeometry)
            node.geometry?.firstMaterial?.fillMode = .lines
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.8)
            node.geometry?.firstMaterial?.isDoubleSided = true
            node.isHidden = !showLandmarks

            faceNode = node
            return node
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
            }

            // Update mesh with new blend shapes
            faceGeometry.update(from: faceAnchor.geometry)

            // Update visibility
            node.isHidden = !showLandmarks
        }
    }
}

#Preview {
    ARCameraView(isRunning: .constant(true), showLandmarks: .constant(true))
        .ignoresSafeArea()
}
