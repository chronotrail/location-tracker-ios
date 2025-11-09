//
//  ContentView.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import SwiftUI
import CoreData
import MapKit

enum MapDisplayMode: String, CaseIterable, Identifiable {
    case rawOnly = "Raw"
    case placeOnly = "Place"
    case both = "Both"
    var id: Self { self }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var locationManager: LocationManager
    
    @StateObject private var dataProvider: DataProvider
    @State private var selectedView: Int = 0 // 0 = Map View, 1 = Raw Data View
    @State private var displayMode: MapDisplayMode = .rawOnly
    @State private var selectedDate = Date()
    @State var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    ))
    @State private var showingSettings: Bool = false

    init() {
        let context = PersistenceController.shared.container.viewContext
        _dataProvider = StateObject(wrappedValue: DataProvider(viewContext: context))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Main content area
                if selectedView == 0 {
                    MapView(dataProvider: dataProvider, displayMode: $displayMode, selectedDate: $selectedDate, position: $position)
                } else {
                    RawDataView(dataProvider: dataProvider, displayMode: $displayMode, selectedDate: $selectedDate)
                }
                
                VStack(spacing: 0) {
                    Picker("Display Mode", selection: $displayMode) {
                        ForEach(MapDisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    
                    // Bottom tray for switching views
                    HStack {
                        Button(action: {
                            selectedView = 0
                        }) {
                            VStack {
                                Image(systemName: "map.fill")
                                    .font(.title2)
                                Text("Map")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedView == 0 ? Color.blue.opacity(0.2) : Color.clear)
                        }
                        .cornerRadius(10)
                        
                        Button(action: {
                            selectedView = 1
                        }) {
                            VStack {
                                Image(systemName: "list.bullet")
                                    .font(.title2)
                                Text("Raw Data")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selectedView == 1 ? Color.blue.opacity(0.2) : Color.clear)
                        }
                        .font(.caption)
                        .cornerRadius(10)
                    }
                    .background(Color(.systemGray6))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(locationManager)
        }
        .onChange(of: selectedDate) {
            dataProvider.fetchData(for: selectedDate)
        }
        .onChange(of: selectedView) { oldValue, newValue in
            if oldValue != newValue, newValue == 0 { // switched to map view
                if let latest = dataProvider.items.first {
                    let coord = CLLocationCoordinate2D(latitude: latest.latitude, longitude: latest.longitude)
                    position = .region(
                        MKCoordinateRegion(
                            center: coord,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                    print("Re-center map when switching back to MapView")
                }
            }
        }
        .onAppear {
            locationManager.startTracking()
            locationManager.refreshCurrentLocation()
            dataProvider.fetchData(for: selectedDate)
            if let latest = dataProvider.items.first {
                position = .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: latest.latitude, longitude: latest.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }

    private func addItem() {
        withAnimation {
            guard let location = locationManager.currentLocation else {
                print("Warning: Current location is not available.")
                return
            }
            
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.latitude = location.coordinate.latitude
            newItem.longitude = location.coordinate.longitude

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
