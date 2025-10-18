import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PlayRoot()
                .tabItem { Label("Play", systemImage: "arkit") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }

            ProgressListView()
                .tabItem { Label("Data", systemImage: "list.bullet.rectangle.portrait") }
        }
    }
}

// MARK: - Play tab
private struct PlayRoot: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ARPuzzleView(level: demoLevels[0])
                    } label: {
                        Label("Quick Start (L1)", systemImage: "play.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(DS.brand)
                    }

                    NavigationLink("Level Select") { LevelSelectView() }
                } header: { Text("Play") }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tip")
                            .font(.headline).foregroundStyle(DS.brand)
                        Text("Scan a bright, textured surface. Tap to spawn blocks. Tap a block for options. Triple-tap to snap.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("BlockFit AR")
        }
    }
}

struct LevelSelectView: View {
    var body: some View {
        List(demoLevels) { level in
            NavigationLink(level.displayName) { ARPuzzleView(level: level) }
        }
        .navigationTitle("Levels")
    }
}


#Preview {
    ContentView()
}
