//
//  Level.swift
//  BlockFitAR
//
//  Created by Kisura W.S.P on 2025-10-18.
//
import Foundation
import simd

struct Level: Identifiable, Codable, Hashable {
    let id: String
    let displayName: String
    let pieces: [Piece]                 // hole positions/rotations relative to plane center
    let snapToleranceCM: Float = 2.5    // distance tolerance
    let snapYawDeg: Float = 12          // rotation tolerance

    struct Piece: Codable, Hashable {
        let offsetX: Float              // meters
        let offsetZ: Float              // meters
        let yawRadians: Float
        let sizeM: Float = 0.06         // 6 cm cube
    }
}

// 5 small, demoable levels
let demoLevels: [Level] = [
    Level(id: "L1", displayName: "Two Fit",
          pieces: [.init(offsetX: -0.20, offsetZ:  0.00, yawRadians: 0),
                   .init(offsetX:  0.20, offsetZ:  0.00, yawRadians: 0)]),
    Level(id: "L2", displayName: "Angle Match",
          pieces: [.init(offsetX: -0.18, offsetZ: -0.10, yawRadians: .pi/4),
                   .init(offsetX:  0.18, offsetZ:  0.10, yawRadians: -.pi/6)]),
    Level(id: "L3", displayName: "Wide Gap",
          pieces: [.init(offsetX: -0.30, offsetZ:  0.05, yawRadians:  .pi/8),
                   .init(offsetX:  0.30, offsetZ: -0.05, yawRadians: -.pi/8)]),
    Level(id: "L4", displayName: "Tight Turn",
          pieces: [.init(offsetX: -0.12, offsetZ: -0.16, yawRadians:  .pi/2),
                   .init(offsetX:  0.12, offsetZ:  0.16, yawRadians:  .pi/3)]),
    Level(id: "L5", displayName: "Cross",
          pieces: [.init(offsetX:  0.00, offsetZ: -0.22, yawRadians: 0),
                   .init(offsetX:  0.00, offsetZ:  0.22, yawRadians: .pi/2)]),
]

// Simple star calc (keep from before if you already added)
func starsFor(time seconds: Int, attempts: Int) -> Int {
    if seconds <= 20 && attempts <= 2 { return 3 }
    if seconds <= 40 && attempts <= 4 { return 2 }
    return 1
}

