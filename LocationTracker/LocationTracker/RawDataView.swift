//
//  RawDataView.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import SwiftUI
import CoreData

struct RawDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedDate = Date()
    @FetchRequest private var locationItems: FetchedResults<Item>
    @State private var showingDatePicker = false
    
    init() {
        // Configure fetch request to get items for selected date
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)]
        _locationItems = FetchRequest(fetchRequest: fetchRequest)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(locationItems) { item in
                    VStack(alignment: .leading) {
                        Text(item.timestamp!, formatter: itemFormatter)
                            .font(.headline)
                        #if canImport(CoreData)
                        // Check if the Item entity has latitude and longitude properties
                        if item.responds(to: #selector(getter: Item.latitude)) && 
                           item.responds(to: #selector(getter: Item.longitude)) {
                            Text("Latitude: \(item.latitude)")
                                .font(.caption)
                            Text("Longitude: \(item.longitude)")
                                .font(.caption)
                        } else {
                            Text("Latitude: N/A")
                                .font(.caption)
                            Text("Longitude: N/A")
                                .font(.caption)
                        }
                        #else
                        Text("Latitude: N/A")
                            .font(.caption)
                        Text("Longitude: N/A")
                            .font(.caption)
                        #endif
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Date selector button at the bottom
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
        .navigationTitle("Raw Location Data")
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
        .onChange(of: selectedDate) { _, newValue in
            updateFetchRequest(for: newValue)
        }
        .onAppear {
            updateFetchRequest(for: selectedDate)
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

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    RawDataView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}