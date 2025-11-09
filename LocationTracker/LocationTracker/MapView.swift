//
//  MapView.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import SwiftUI
import CoreData
import MapKit
import Combine

struct MapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var dataProvider: DataProvider
    
    @State private var showingDatePicker = false
    @Binding private var displayMode: MapDisplayMode
    @Binding private var selectedDate: Date
    @Binding var position: MapCameraPosition
    
    init(dataProvider: DataProvider, displayMode: Binding<MapDisplayMode>, selectedDate: Binding<Date>, position: Binding<MapCameraPosition>) {
        print("MapView initialized")
        self.dataProvider = dataProvider
        self._displayMode = displayMode
        self._selectedDate = selectedDate
        self._position = position
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map view
            Map(position: $position) {
                mapAnnotations
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                Button(action: { showingDatePicker = true}) {
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
                
                Button(action: {
                    dataProvider.fetchData(for: selectedDate)
                }) {
                    Text(countText)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .underline()
                }
                .accessibilityLabel("Refresh data")
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle("Location Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $selectedDate)
        }
        .onChange(of: dataProvider.items) {
            print("Items updated, centering map on latest data")
            centerMapOnLatest()
        }
        .onChange(of: dataProvider.places) {
            print("Places updated, centering map on latest data")
            centerMapOnLatest()
        }
    }
    
    private func centerMapOnLatest() {
        print("centerMapOnLatest() called")
        var coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        if let place = dataProvider.places.first {
            coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            print("Centering on Place at \(place.latitude), \(place.longitude)")
        } else if let item = dataProvider.items.first {
            coordinate = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
            print("Centering on Item at \(item.latitude), \(item.longitude)")
        }
        
        let span = position.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        
        let newRegion = MKCoordinateRegion(
            center: coordinate,
            span: span
        )
        
        position = .region(newRegion)
    }
    
    @MapContentBuilder
    private var mapAnnotations: some MapContent {
        switch displayMode {
        case .rawOnly:
            ForEach(dataProvider.items) { item in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)) {
                    Circle()
                        .stroke(Color.red.opacity(0.8), lineWidth: 1)
                        .frame(width: 8, height: 8)
                }
            }
        case .placeOnly:
            ForEach(dataProvider.places) { place in
                let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                Annotation("", coordinate: coordinate) {
                    VStack(spacing: 2) {
                        Text(place.name ?? place.displayAddress)
                            .font(.caption2)
                            .lineLimit(1)
                            .padding(4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(6)
                            .shadow(radius: 1)
                        Circle()
                            .stroke(Color.orange.opacity(0.7), lineWidth: 3)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        case .both:
            ForEach(dataProvider.items) { item in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)) {
                    Circle()
                        .stroke(Color.red.opacity(0.8), lineWidth: 1)
                        .frame(width: 8, height: 8)
                }
            }
            ForEach(dataProvider.places) { place in
                let coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                Annotation("", coordinate: coordinate) {
                    VStack(spacing: 2) {
                        Text(place.name ?? place.displayAddress)
                            .font(.caption2)
                            .lineLimit(1)
                            .padding(4)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(6)
                            .shadow(radius: 1)
                        Circle()
                            .stroke(Color.orange.opacity(0.7), lineWidth: 3)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }
        
    private var countText: String {
        switch displayMode {
        case .rawOnly:
            return "\(dataProvider.items.count) samples"
        case .placeOnly:
            return "\(dataProvider.places.count) places"
        case .both:
            return "\(dataProvider.items.count) samples, \(dataProvider.places.count) places"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    MapView(
        dataProvider: PersistenceController.preview.dataProvider,
        displayMode: .constant(.rawOnly),
        selectedDate: .constant(Date()),
        position: .constant(.region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )))
    ).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
