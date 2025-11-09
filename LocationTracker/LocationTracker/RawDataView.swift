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
    
    @ObservedObject var dataProvider: DataProvider
    
    @State private var showingDatePicker = false
    @Binding var displayMode: MapDisplayMode
    @Binding private var selectedDate: Date
    
    init(dataProvider: DataProvider, displayMode: Binding<MapDisplayMode>, selectedDate: Binding<Date>) {
        self.dataProvider = dataProvider
        self._displayMode = displayMode
        self._selectedDate = selectedDate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                switch displayMode {
                case .rawOnly:
                    Section(header: Text("Raw Samples (\(dataProvider.items.count))")) {
                        ForEach(dataProvider.items) { item in ItemRowView(item: item) }
                    }
                case .placeOnly:
                    Section(header: Text("Places (\(dataProvider.places.count))")) {
                        ForEach(dataProvider.places) { place in PlaceRowView(place: place) }
                    }
                case .both:
                    Section(header: Text("Places (\(dataProvider.places.count))")) {
                        ForEach(dataProvider.places) { place in PlaceRowView(place: place) }
                    }
                    Section(header: Text("Raw Samples (\(dataProvider.items.count))")) {
                        ForEach(dataProvider.items) { item in ItemRowView(item: item) }
                    }
                }
            }
            .refreshable {
                dataProvider.fetchData(for: selectedDate)
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
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Data View")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ItemRowView: View {
    @ObservedObject var item: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.timestamp ?? Date(), style: .time).font(.headline)
            HStack {
                Text(String(format: "%.4f, %.4f", item.latitude, item.longitude))
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct PlaceRowView: View {
    @ObservedObject var place: Place
    
    private var duration: String {
        guard let start = place.startTime, let end = place.endTime else { return "N/A" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: start, to: end) ?? "0m"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Stay for \(duration)")
                    .font(.headline)
                HStack {
                    Text(String(format: "%.4f, %.4f", place.latitude, place.longitude))
                }
                .font(.caption)
                Text("\(place.sampleCount) samples")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RawDataView(
        dataProvider: PersistenceController.preview.dataProvider,
        displayMode: .constant(.rawOnly),
        selectedDate: .constant(Date())
    ).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
