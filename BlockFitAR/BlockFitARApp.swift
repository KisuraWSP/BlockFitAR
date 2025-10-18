//
//  BlockFitARApp.swift
//  BlockFitAR
//
//  Created by Kisura W.S.P on 2025-10-13.
//

import SwiftUI
import CoreData

@main
struct BlockFitARApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tint(DS.brand)
        }
    }
}
