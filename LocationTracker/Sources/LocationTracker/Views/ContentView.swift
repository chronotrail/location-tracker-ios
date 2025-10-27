import SwiftUI
import MapKit
import CoreData

struct ContentView: View {
    @StateObject var locationManager: LocationManager
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedDate = Date()
    @State private var locations: [Location] = []

    var body: some View {
        VStack {
            Text("Location Tracker")
                .font(.largeTitle)
            
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .padding()
            .onChange(of: selectedDate) { _ in
                fetchLocations()
            }

            MapView(locations: locations)
                .edgesIgnoringSafeArea(.all)

            Button("Start Tracking") {
                locationManager.requestLocationPermission()
                locationManager.startUpdatingLocation()
            }
            .padding()
        }
        .onAppear {
            fetchLocations()
        }
    }

    private func fetchLocations() {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: selectedDate)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Location.timestamp, ascending: true)]
        
        do {
            locations = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch locations: \(error.localizedDescription)")
        }
    }
}

struct MapView: UIViewRepresentable {
    var locations: [Location]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        updateOverlays(for: uiView)
        updateRegion(for: uiView)
    }
    
    private func updateOverlays(for mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        let coordinates = locations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }
    
    private func updateRegion(for mapView: MKMapView) {
        guard let firstLocation = locations.first else { return }
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: firstLocation.latitude, longitude: firstLocation.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let routePolyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: routePolyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.shared.container.viewContext
        let locationManager = LocationManager(context: context)
        ContentView(locationManager: locationManager).environment(\.managedObjectContext, context)
    }
}
