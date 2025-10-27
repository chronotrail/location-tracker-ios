import Foundation
import CoreLocation
import CoreData

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let viewContext: NSManagedObjectContext

    @Published var lastLocation: CLLocation? = nil

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 50 // meters
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }

    func requestLocationPermission() {
        self.locationManager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        addLocationToCoreData(location: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with error: \(error.localizedDescription)")
    }
    
    private func addLocationToCoreData(location: CLLocation) {
        let newLocation = Location(context: viewContext)
        newLocation.latitude = location.coordinate.latitude
        newLocation.longitude = location.coordinate.longitude
        newLocation.timestamp = location.timestamp
        newLocation.needsSync = true
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}