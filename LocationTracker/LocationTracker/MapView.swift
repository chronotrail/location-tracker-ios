//
//  MapView.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import SwiftUI
import CoreData
import MapKit

struct MapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedDate = Date()
    @FetchRequest private var locationItems: FetchedResults<Item>
    @State private var showingDatePicker = false
    
    // For MapKit (Apple Maps)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    init() {
        // Configure fetch request to get items for selected date
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)]
        _locationItems = FetchRequest(fetchRequest: fetchRequest)
    }
    
    var body: some View {
        VStack {
            // Map view
            Map(coordinateRegion: $region, annotationItems: locationItems) { item in
                // Once latitude and longitude properties are added to Item,
                // this will show actual location data
#if canImport(CoreData)
                // Check if the Item entity has latitude and longitude properties
                if item.responds(to: #selector(getter: Item.latitude)) &&
                    item.responds(to: #selector(getter: Item.longitude)) {
                    // Use actual location data
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                    // MapMarker(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude),
                    //         tint: .red)
                } else {
                    // Fallback to hardcoded coordinates
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                    //MapMarker(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    //         tint: .red)
                }
#else
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                // MapMarker(coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                //         tint: .red)
#endif
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Date selector button
            HStack {
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text(formattedDate(selectedDate))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Text("Showing \(locationItems.count) locations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Location Map")
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
        .onChange(of: selectedDate) { _, newValue in
            updateFetchRequest(for: newValue)
        }
        .onAppear {
            updateFetchRequest(for: selectedDate)
            
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            do {
                let items = try viewContext.fetch(fetchRequest)
                if let mostRecentItem = items.first {
                    region.center = CLLocationCoordinate2D(latitude: mostRecentItem.latitude, longitude: mostRecentItem.longitude)
                }
            } catch {
                print("Failed to fetch most recent item for map region: \(error)")
            }
        }
        .onChange(of: locationItems.count) {
            if let firstItem = locationItems.first {
                region.center = CLLocationCoordinate2D(latitude: firstItem.latitude, longitude: firstItem.longitude)
            }
        }
    }
    
    private func updateFetchRequest(for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)]
        
        locationItems.nsPredicate = fetchRequest.predicate
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    MapView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
