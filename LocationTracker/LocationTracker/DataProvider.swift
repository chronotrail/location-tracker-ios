//
//  DataProvider.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 11/3/25.
//

import SwiftUI
import CoreData
import Combine

class DataProvider: ObservableObject {
    @Published var items: [Item] = []
    @Published var places: [Place] = []
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func fetchData(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        let itemsRequest: NSFetchRequest<Item> = Item.fetchRequest()
        itemsRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)]
        itemsRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        let placesRequest: NSFetchRequest<Place> = Place.fetchRequest()
        placesRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Place.startTime, ascending: false)]
        placesRequest.predicate = NSPredicate(format: "startTime < %@ AND endTime > %@", endOfDay as NSDate, startOfDay as NSDate)
        
        do {
            let fetchedItems = try viewContext.fetch(itemsRequest)
            let fetchedPlaces = try viewContext.fetch(placesRequest)
            
            DispatchQueue.main.async {
                self.items = fetchedItems
                self.places = fetchedPlaces
                print("DataProvider: Fetched \(self.items.count) items and \(self.places.count) places.")
            }
            
            Task { [weak self] in
                guard let self else { return }
                for place in fetchedPlaces where place.formattedAddress == nil {
                    await ReverseGeocoder.shared.resolve(place: place, in: self.viewContext)
                    try? await Task.sleep(for: .seconds(2))
                }
                
                await MainActor.run {
                    self.objectWillChange.send()
                }
            }
        } catch {
            DispatchQueue.main.async {
                print("DataProvider: Failed to fetch data: \(error)")
                self.items = []
                self.places = []
            }
        }
    }
}
