//
//  ARPuzzleView.swift
//  BlockFitAR
//
//  Created by Kisura W.S.P on 2025-10-18.
//

import SwiftUI
import CoreData

enum GameState { case ready, playing, won }

// Commands the AR scene can execute
enum BlockCommand: Equatable {
    case lock(Int)
    case unlock(Int)
    case snap(Int)
}

struct ARPuzzleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var ctx

    @State private var statusText: String = "Scan a flat surface…"
    @State private var snapped: Bool = false
    @State private var distanceText: String = "—"
    @State private var state: GameState = .ready
    @State private var seconds: Int = 0
    @State private var attempts: Int = 0

    // UI for block action menu
    @State private var selectedBlockIndex: Int? = nil
    @State private var showBlockMenu = false
    @State private var command: BlockCommand? = nil
    @State private var isLocked: [Bool] = [false, false, false, false] // enough for our levels

    let level: Level

    var body: some View {
        ZStack(alignment: .top) {
            ARPuzzleSceneView(
                level: level,
                statusText: $statusText,
                snapped: $snapped,
                distanceText: $distanceText,
                onFailedSnap: { attempts += 1 },
                onSelectBlock: { idx in
                    selectedBlockIndex = idx
                    showBlockMenu = true
                },
                command: $command,
                lockState: $isLocked
            )
            .ignoresSafeArea()
            .onChange(of: snapped) { if $0 { handleWin() } }

            topHUD
            if state == .won { winBanner }
        }
        .confirmationDialog(
            "Block options",
            isPresented: $showBlockMenu,
            titleVisibility: .visible
        ) {
            if let idx = selectedBlockIndex {
                if isLocked.indices.contains(idx), isLocked[idx] {
                    Button("Unlock") { command = .unlock(idx) }
                } else {
                    Button("Lock") { command = .lock(idx) }
                }
                Button("Snap to Hole") { command = .snap(idx) }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("Cancel", role: .cancel) { }
            }
        }
        .onAppear { startTimer() }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: UI
    var topHUD: some View {
        HStack {
            Text(level.displayName).bold()
            Spacer()
            Text("⏱ \(seconds)s  •  ↻ \(attempts)").monospacedDigit()
            Button("Exit") { dismiss() }.buttonStyle(.bordered)
        }
        .padding(.horizontal).padding(.top, 12)
        .background(.ultraThinMaterial)
    }

    var winBanner: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Text("Level Complete!").font(.title2.bold())
                Text("Time \(seconds)s  •  Attempts \(attempts)").monospacedDigit()
                Text("⭐️ \(starsFor(time: seconds, attempts: attempts))")
                HStack {
                    Button("Next Level") { goToNextLevel() }
                        .buttonStyle(.borderedProminent)
                    Button("Retry") { retry() }
                }
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.bottom, 40)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: state)
    }

    // MARK: Game flow
    private func startTimer() {
        state = .playing
        seconds = 0
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if state != .playing { t.invalidate() }
            else { seconds += 1 }
        }
    }

    private func handleWin() {
        state = .won
        saveProgress(levelId: level.id, timeSec: seconds, attempts: attempts)
    }

    private func retry() { dismiss() }
    private func goToNextLevel() { dismiss() }

    // MARK: Persistence (same as before)
    private func saveProgress(levelId: String, timeSec: Int, attempts: Int) {
        let stars = starsFor(time: timeSec, attempts: attempts)
        let req: NSFetchRequest<LevelProgress> = LevelProgress.fetchRequest()
        req.predicate = NSPredicate(format: "levelId == %@", levelId)
        let current = (try? ctx.fetch(req))?.first ?? LevelProgress(context: ctx)
        current.levelId = levelId
        current.completedAt = Date()
        let t = Double(timeSec)
        if current.bestTimeSec == 0 || t < current.bestTimeSec { current.bestTimeSec = t }
        if current.stars < Int16(stars) { current.stars = Int16(stars) }
        try? ctx.save()
    }
}
