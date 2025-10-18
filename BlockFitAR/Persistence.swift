//
//  Persistence.swift
//  BlockFitAR
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // Preview store for SwiftUI previews / screenshots
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Seed a few LevelProgress rows so preview UIs have data
        let demo: [(String, Double, Int16)] = [
            ("L1", 18.0, 3),
            ("L2", 37.0, 2)
        ]
        for (id, best, stars) in demo {
            let lp = LevelProgress(context: viewContext)
            lp.levelId = id
            lp.bestTimeSec = best
            lp.stars = stars
            lp.completedAt = Date().addingTimeInterval(-3600) // 1h ago
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // MUST match your .xcdatamodeld name
        container = NSPersistentContainer(name: "BlockFitAR")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // Merge changes if you later use background contexts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
