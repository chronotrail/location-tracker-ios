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
    @StateObject private var locationManager = LocationManager(viewContext: PersistenceController.shared.container.viewContext)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(locationManager)
                .onAppear {
                    locationManager.startTracking()
                }
        }
    }
}