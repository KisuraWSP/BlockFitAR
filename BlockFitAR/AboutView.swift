//
//  AboutView.swift
//  BlockFitAR
//
//  Created by Kisura W.S.P on 2025-10-18.
//

// AboutView.swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero
                DS.glassCard {
                    HStack(alignment: .center, spacing: 16) {
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(DS.brand)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BlockFit AR")
                                .font(.title.bold())
                            Text("Place 3D blocks into matching holes on real-world surfaces. Drag to move, rotate with two fingers, lock to freeze, and triple-tap to snap.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // How to Play
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Play").font(.headline)
                    Label("Scan a flat surface until yellow slots appear.", systemImage: "camera.viewfinder")
                    Label("Tap to spawn blocks (one per slot).", systemImage: "plus.viewfinder")
                    Label("Tap a block for actions: Lock / Unlock / Snap.", systemImage: "hand.tap")
                    Label("Drag to move; rotate with two fingers.", systemImage: "rotate.3d")
                    Label("Triple-tap a block to snap directly.", systemImage: "hand.tap.fill")
                }

                // Scoring
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scoring").font(.headline)
                    Text("Finish faster with fewer failed snaps to earn more ⭐️. Your best time and stars per level are saved.")
                        .foregroundStyle(.secondary)
                }

                // Tech
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tech & Design").font(.headline)
                    Text("Built with SwiftUI, ARKit + SceneKit primitives, and Core Data. Targets are placed relative to the detected plane center. Accessibility: large digits for time/attempts, haptic feedback on snap.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .navigationTitle("About")
    }
}
