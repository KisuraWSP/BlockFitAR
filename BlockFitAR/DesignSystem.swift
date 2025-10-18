//
//  DesignSystem.swift
//  BlockFitAR
//
//  Created by Kisura W.S.P on 2025-10-18.
//

// DesignSystem.swift
import SwiftUI

enum DS {
    static let brand = Color(.displayP3, red: 0.08, green: 0.37, blue: 0.88, opacity: 1) // deep blue
    static let brandSoft = Color(.displayP3, red: 0.08, green: 0.37, blue: 0.88, opacity: 0.12)

    static func capsuleLabel(_ text: String) -> some View {
        Text(text)
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    static func glassCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
