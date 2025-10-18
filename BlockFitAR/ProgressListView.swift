//
//  ProgressListView.swift
//  BlockFitAR
//
//  Created by Kisura W.S.P on 2025-10-18.
//

// ProgressListView.swift
import SwiftUI
import CoreData

struct ProgressListView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \LevelProgress.levelId, ascending: true)
        ],
        animation: .default
    )
    private var items: FetchedResults<LevelProgress>

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("No progress yet")
                            .font(.headline)
                        Text("Play a level to save your best time and stars here.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 48)
                } else {
                    List {
                        ForEach(items) { lp in
                            NavigationLink {
                                ProgressDetailView(lp: lp)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(DS.brandSoft)
                                        Image(systemName: "star.fill").foregroundStyle(DS.brand)
                                    }
                                    .frame(width: 36, height: 36)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(levelName(for: lp.levelId ?? "—"))
                                            .font(.headline)
                                        HStack(spacing: 8) {
                                            Text("Best: \(formatSeconds(lp.bestTimeSec))")
                                            Text("•")
                                            Text("⭐️ \(lp.stars)")
                                            if let d = lp.completedAt {
                                                Text("•").foregroundStyle(.secondary)
                                                Text(d.formatted(date: .abbreviated, time: .shortened))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .font(.subheadline).monospacedDigit()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Data")
            .toolbar {
                // Optional quick-delete for demo resets
                if !items.isEmpty {
                    Button(role: .destructive) {
                        items.forEach { ctx.delete($0) }
                        try? ctx.save()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func formatSeconds(_ s: Double) -> String {
        if s == 0 { return "—" }
        return "\(Int(s))s"
    }

    private func levelName(for id: String) -> String {
        demoLevels.first(where: { $0.id == id })?.displayName ?? "Level \(id)"
    }
}
