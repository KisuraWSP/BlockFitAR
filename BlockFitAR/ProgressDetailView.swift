//
//  ProgressDetailView.swift
//  BlockFitAR
//
//  Created by Kisura W.S.P on 2025-10-18.
//

// ProgressDetailView.swift
import SwiftUI

struct ProgressDetailView: View {
    @ObservedObject var lp: LevelProgress

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DS.glassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(levelTitle).font(.title2.bold())
                        HStack(spacing: 12) {
                            label("Best Time", "\(bestTime)")
                            label("Stars", "⭐️ \(lp.stars)")
                        }
                        if let date = lp.completedAt {
                            Text("Last Completed: \(date.formatted(date: .abbreviated, time: .shortened))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Raw Values").font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("levelId: \(lp.levelId ?? "—")")
                        Text("bestTimeSec: \(Int(lp.bestTimeSec))")
                        Text("stars: \(lp.stars)")
                        Text("completedAt: \(lp.completedAt?.description(with: .current) ?? "—")")
                    }
                    .font(.callout).foregroundStyle(.secondary)
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
        .navigationTitle(levelTitle)
    }

    private var levelTitle: String {
        let id = lp.levelId ?? "—"
        return demoLevels.first(where: { $0.id == id })?.displayName ?? "Level \(id)"
    }
    private var bestTime: String { lp.bestTimeSec == 0 ? "—" : "\(Int(lp.bestTimeSec))s" }

    @ViewBuilder private func label(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold))
        }
    }
}
