//
//  ContentView.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var locationManager: LocationManager

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var selectedView: Int = 0 // 0 = Map View, 1 = Raw Data View

    var body: some View {
        NavigationView {
            VStack {
                // Main content area
                if selectedView == 0 {
                    MapView()
                } else {
                    RawDataView()
                }
                
                // Bottom tray for switching views
                HStack {
                    Button(action: {
                        selectedView = 0
                    }) {
                        VStack {
                            Image(systemName: "map.fill")
                                .font(.title2)
                            Text("Map")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedView == 0 ? Color.blue : Color.clear)
                        .foregroundColor(selectedView == 0 ? .white : .primary)
                    }
                    .cornerRadius(10)
                    
                    Button(action: {
                        selectedView = 1
                    }) {
                        VStack {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                            Text("Raw Data")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedView == 1 ? Color.blue : Color.clear)
                        .foregroundColor(selectedView == 1 ? .white : .primary)
                    }
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
        .onAppear {
            locationManager.startTracking()
        }
        .onDisappear {
            locationManager.stopTracking()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

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

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

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