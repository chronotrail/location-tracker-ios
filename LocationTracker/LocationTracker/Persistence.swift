//
//  Persistence.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create a sample Place for today
        let newPlace = Place(context: viewContext)
        newPlace.startTime = Date().addingTimeInterval(-3600) // An hour ago
        newPlace.endTime = Date()
        newPlace.latitude = 33.7962
        newPlace.longitude = -118.1113
        newPlace.sampleCount = 12

        // Create a few sample Items for today
        for i in 0..<5 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date().addingTimeInterval(TimeInterval(-i * 120)) // Every 2 minutes
            newItem.latitude = 33.7962 + Double.random(in: -0.001...0.001)
            newItem.longitude = -118.1113 + Double.random(in: -0.001...0.001)
            newItem.processed = (i < 2) // Mark some as processed
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        result.dataProvider.fetchData(for: Date())
        
        return result
    }()
    
    let container: NSPersistentContainer
    
    let dataProvider: DataProvider

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LocationTracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        dataProvider = DataProvider(viewContext: container.viewContext)
    }
    
    func seedInitialDataIfNeeded() {
        #if DEBUG
        let hasSeededKey = "hasSeededInitialData"
        let hasSeeded = UserDefaults.standard.bool(forKey: hasSeededKey)
        guard !hasSeeded else { return }
        let viewContext = container.viewContext
        print("Seeding initial data...")
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let place = Place(context: viewContext)
        place.startTime = yesterday.addingTimeInterval(-3600) // An hour ago
        place.endTime = yesterday
        place.latitude = 33.7962
        place.longitude = -118.1113
        place.sampleCount = 12

        // Create a few sample Items for today
        for i in 0..<5 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date().addingTimeInterval(TimeInterval(-i * 120)) // Every 2 minutes
            newItem.latitude = 33.7962 + Double.random(in: -0.001...0.001)
            newItem.longitude = -118.1113 + Double.random(in: -0.001...0.001)
            newItem.processed = false
        }
        
        do {
            try viewContext.save()
            UserDefaults.standard.set(true, forKey: hasSeededKey)
            print("Successfully seeded initial data.")
        } catch {
            let nsError = error as NSError
            print("Error seeding initial data: \(nsError), \(nsError.userInfo)")
        }
        #endif
    }
}
