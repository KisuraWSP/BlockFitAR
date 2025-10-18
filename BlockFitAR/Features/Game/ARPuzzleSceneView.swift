import SwiftUI
import ARKit
import SceneKit
import CoreHaptics

struct ARPuzzleSceneView: UIViewRepresentable {
    let level: Level
    @Binding var statusText: String
    @Binding var snapped: Bool
    @Binding var distanceText: String
    var onFailedSnap: () -> Void = {}

    // New: notify parent when a block is tapped (to open menu)
    var onSelectBlock: (Int) -> Void = { _ in }

    // New: parent can send commands to scene (lock/unlock/snap)
    @Binding var command: BlockCommand?

    // New: shared lock state (so UI can know what's locked)
    @Binding var lockState: [Bool]

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.automaticallyUpdatesLighting = true
        view.delegate = context.coordinator

        view.debugOptions = [.showFeaturePoints, .showWorldOrigin]

        let cfg = ARWorldTrackingConfiguration()
        cfg.planeDetection = [.horizontal]
        cfg.environmentTexturing = .automatic
        view.session.run(cfg)

        // Gestures
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)

        let rotate = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotate(_:)))
        view.addGestureRecognizer(rotate)

        // New: triple-tap to auto-snap selected/tapped block
        let tripleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTripleTap(_:)))
        tripleTap.numberOfTapsRequired = 3
        view.addGestureRecognizer(tripleTap)
        // ensure single tap waits for triple (so they don’t conflict)
        tap.require(toFail: tripleTap)

        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Consume command (if any) on every update
        if let cmd = command {
            context.coordinator.apply(cmd)
            DispatchQueue.main.async { self.command = nil }
        }
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARPuzzleSceneView
        var engine: CHHapticEngine?

        var targetNodes: [SCNNode] = []
        var blockNodes: [SCNNode] = []
        var snappedFlags: [Bool]
        var lockedFlags: [Bool]
        var activeIndex: Int = 0

        var planeCenter: SIMD3<Float>?
        var dragging = false
        var dragPlaneY: Float = 0

        init(_ parent: ARPuzzleSceneView) {
            self.parent = parent
            self.snappedFlags = Array(repeating: false, count: parent.level.pieces.count)
            self.lockedFlags  = Array(repeating: false, count: parent.level.pieces.count)
            super.init()
            prepareHaptics()
        }

        // MARK: Haptics
        func prepareHaptics() { do { engine = try CHHapticEngine(); try engine?.start() } catch { } }
        func bump() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }

        // MARK: Plane detection → place targets once using level offsets (BIGGER holes)
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let plane = anchor as? ARPlaneAnchor, targetNodes.isEmpty else { return }
            planeCenter = plane.center
            let base = plane.center

            for piece in parent.level.pieces {
                let worldX = base.x + piece.offsetX
                let worldZ = base.z + piece.offsetZ
                let n = makeTargetNode(size: CGFloat(piece.sizeM), yaw: piece.yawRadians)
                n.position = SCNVector3(worldX, 0, worldZ)
                node.addChildNode(n)
                targetNodes.append(n)
            }

            DispatchQueue.main.async {
                self.parent.statusText = "Tap to spawn • Tap block for menu • Drag/rotate to fit • Triple-tap to snap"
            }
        }

        // Bigger, obvious targets (plate + rim). Hole margin increased significantly.
        func makeTargetNode(size: CGFloat, yaw: Float) -> SCNNode {
            let margin: CGFloat = 0.02 // +2 cm around the 6 cm cube
            let plate = SCNBox(width: size + margin, height: 0.006, length: size + margin, chamferRadius: 0.004)
            let m1 = SCNMaterial()
            m1.diffuse.contents = UIColor.systemYellow.withAlphaComponent(0.30)
            m1.emission.contents = UIColor.systemYellow.withAlphaComponent(0.20)
            m1.lightingModel = .constant
            plate.materials = [m1]
            let plateNode = SCNNode(geometry: plate)

            let rim = SCNBox(width: size + margin + 0.006, height: 0.003, length: size + margin + 0.006, chamferRadius: 0.004)
            let m2 = SCNMaterial()
            m2.diffuse.contents = UIColor.systemYellow
            m2.emission.contents = UIColor.systemYellow
            m2.lightingModel = .constant
            rim.materials = [m2]
            let rimNode = SCNNode(geometry: rim)
            rimNode.position.y = 0.004

            let parent = SCNNode()
            parent.addChildNode(plateNode)
            parent.addChildNode(rimNode)
            parent.eulerAngles.y = yaw
            return parent
        }

        // MARK: Gestures
        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let view = g.view as? ARSCNView else { return }
            let p = g.location(in: view)

            // Create blocks until we have one per target
            if blockNodes.count < targetNodes.count {
                let hits = view.hitTest(p, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane, .featurePoint])
                guard let hit = hits.first else { return }
                let t = hit.worldTransform
                let pos = SCNVector3(t.columns.3.x, t.columns.3.y + 0.03, t.columns.3.z)
                let node = makeBlockNode(colorIndex: blockNodes.count)
                node.position = pos
                view.scene.rootNode.addChildNode(node)
                blockNodes.append(node)
                activeIndex = blockNodes.count - 1
                pulse(node)
                bump()
                updateOffset()
                return
            }

            // Otherwise: select a block → show menu in SwiftUI
            if let tappedIdx = hitBlockIndex(in: view, at: p) {
                activeIndex = tappedIdx
                pulse(blockNodes[activeIndex])
                updateOffset()
                parent.onSelectBlock(tappedIdx)
            } else {
                // tap empty → try snap active one
                checkSnap(for: activeIndex)
            }
        }

        // Triple tap: snap the tapped block immediately (if over its hole)
        @objc func handleTripleTap(_ g: UITapGestureRecognizer) {
            guard let view = g.view as? ARSCNView else { return }
            let p = g.location(in: view)
            if let idx = hitBlockIndex(in: view, at: p) {
                checkSnap(for: idx, force: true) // allow regardless of current offset tolerance
            }
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard let view = g.view as? ARSCNView, blockNodes.indices.contains(activeIndex) else { return }
            if lockedFlags.indices.contains(activeIndex), lockedFlags[activeIndex] { return } // 🔒 ignore moves when locked

            let block = blockNodes[activeIndex]
            let p = g.location(in: view)

            switch g.state {
            case .began:
                dragPlaneY = block.position.y
                dragging = true
            case .changed:
                let hits = view.hitTest(p, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
                if let hit = hits.first {
                    let t = hit.worldTransform
                    block.position = SCNVector3(t.columns.3.x, dragPlaneY, t.columns.3.z)
                    updateOffset()
                }
            default:
                dragging = false
                checkSnap(for: activeIndex)
            }
        }

        @objc func handleRotate(_ g: UIRotationGestureRecognizer) {
            guard blockNodes.indices.contains(activeIndex) else { return }
            if lockedFlags.indices.contains(activeIndex), lockedFlags[activeIndex] { return } // 🔒 ignore rotates when locked

            let block = blockNodes[activeIndex]
            if g.state == .changed || g.state == .ended {
                block.eulerAngles.y -= Float(g.rotation)
                g.rotation = 0
                updateOffset()
            }
        }

        // MARK: Helpers
        func makeBlockNode(colorIndex: Int) -> SCNNode {
            let box = SCNBox(width: 0.06, height: 0.06, length: 0.06, chamferRadius: 0.004)
            let m = SCNMaterial()
            m.diffuse.contents = (colorIndex % 2 == 0) ? UIColor.systemTeal : UIColor.systemPink
            box.materials = [m]
            return SCNNode(geometry: box)
        }

        func hitBlockIndex(in view: ARSCNView, at point: CGPoint) -> Int? {
            let hits = view.hitTest(point, options: [.boundingBoxOnly: true])
            guard let first = hits.first else { return nil }
            if let idx = blockNodes.firstIndex(of: first.node) { return idx }
            if let parent = first.node.parent, let idx = blockNodes.firstIndex(of: parent) { return idx }
            return nil
        }

        func pulse(_ node: SCNNode) {
            node.runAction(.sequence([
                .scale(to: 1.08, duration: 0.08),
                .scale(to: 1.00, duration: 0.10)
            ]))
        }

        func updateOffset() {
            guard blockNodes.indices.contains(activeIndex),
                  targetNodes.indices.contains(activeIndex) else {
                DispatchQueue.main.async { self.parent.distanceText = "—" }
                return
            }
            let b = blockNodes[activeIndex]
            let t = targetNodes[activeIndex]
            let dx = b.position.x - t.position.x
            let dz = b.position.z - t.position.z
            let offset = sqrt(dx*dx + dz*dz)
            DispatchQueue.main.async {
                self.parent.distanceText = String(
                    format: "Block %@ Δ: %.1f cm",
                    self.activeIndex == 0 ? "A" : "B",
                    offset * 100
                )
            }
        }

        // force=true lets triple-tap snap even if slightly outside tolerance
        func checkSnap(for index: Int, force: Bool = false) {
            guard blockNodes.indices.contains(index),
                  targetNodes.indices.contains(index) else { return }
            if snappedFlags[index] { return }

            let b = blockNodes[index]
            let t = targetNodes[index]
            let dx = b.position.x - t.position.x
            let dz = b.position.z - t.position.z
            let offset = sqrt(dx*dx + dz*dz)

            let yawDelta = abs(angleDiff(b.eulerAngles.y, t.eulerAngles.y))
            let tol = parent.level.snapToleranceCM / 100.0
            let yawTol = parent.level.snapYawDeg * .pi / 180.0

            if force || (offset < tol && yawDelta < yawTol) {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.15
                b.position = SCNVector3(t.position.x, t.position.y + 0.03, t.position.z)
                b.eulerAngles.y = t.eulerAngles.y
                SCNTransaction.commit()

                snappedFlags[index] = true
                success()
                flashGreen(b)

                if snappedFlags.allSatisfy({ $0 }) {
                    parent.snapped = true
                    parent.statusText = "Level complete!"
                } else {
                    parent.statusText = "Nice! Block \(index == 0 ? "A" : "B") fitted. Fit the other one."
                }
            } else {
                parent.onFailedSnap()
                bump()
            }
        }

        func flashGreen(_ node: SCNNode) {
            node.runAction(.sequence([
                .customAction(duration: 0.001) { _,_ in node.geometry?.firstMaterial?.emission.contents = UIColor.systemGreen },
                .wait(duration: 0.25),
                .customAction(duration: 0.001) { _,_ in node.geometry?.firstMaterial?.emission.contents = UIColor.black }
            ]))
        }

        func angleDiff(_ a: Float, _ b: Float) -> Float {
            var d = fmodf(a - b, 2 * .pi)
            if d < -.pi { d += 2 * .pi }
            if d >  .pi { d -= 2 * .pi }
            return abs(d)
        }

        // MARK: Command intake from SwiftUI (lock/unlock/snap)
        func apply(_ cmd: BlockCommand) {
            switch cmd {
            case .lock(let idx):
                guard blockNodes.indices.contains(idx) else { return }
                lockedFlags[idx] = true
                parent.lockState[safe: idx] = true
                // Dim when locked
                blockNodes[idx].geometry?.firstMaterial?.multiply.contents = UIColor.black.withAlphaComponent(0.15)
            case .unlock(let idx):
                guard blockNodes.indices.contains(idx) else { return }
                lockedFlags[idx] = false
                parent.lockState[safe: idx] = false
                blockNodes[idx].geometry?.firstMaterial?.multiply.contents = UIColor.white
            case .snap(let idx):
                checkSnap(for: idx, force: true)
            }
        }
    }
}

// Safe index setter
private extension Array where Element == Bool {
    subscript(safe idx: Int) -> Bool? {
        get { (0..<count).contains(idx) ? self[idx] : nil }
        set {
            guard (0..<count).contains(idx), let v = newValue else { return }
            self[idx] = v
        }
    }
}
