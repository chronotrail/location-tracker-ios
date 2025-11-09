//
//  LocationTrackerApp.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import SwiftUI

@main
struct LocationTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var locationManager: LocationManager

    init() {
        let context = PersistenceController.shared.container.viewContext
        _locationManager = StateObject(wrappedValue: LocationManager(viewContext: context))
        
        #if DEBUG
        persistenceController.seedInitialDataIfNeeded()
        #endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(locationManager)
        }
    }
}
