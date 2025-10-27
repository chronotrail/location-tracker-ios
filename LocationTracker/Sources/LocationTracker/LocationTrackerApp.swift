import SwiftUI

@main
struct LocationTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            let context = persistenceController.container.viewContext
            ContentView(locationManager: LocationManager(context: context))
                .environment(\.managedObjectContext, context)
        }
    }
}
