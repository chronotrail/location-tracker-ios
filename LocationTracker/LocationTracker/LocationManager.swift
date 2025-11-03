//
//  LocationManager.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import Foundation
import CoreLocation
import CoreData

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var viewContext: NSManagedObjectContext
    
    // private var lastSavedLocation: CLLocation?
    // private var lastSaveTime: Date?
    
    // private let distanceThreshold: CLLocationDistance = 10 // 10 meters
    // private let timeThreshold: TimeInterval = 60 // 1 minute
    
    @Published var isTrackingEnabled: Bool = true {
        didSet {
            if isTrackingEnabled {
                startTracking()
            } else {
                stopTracking()
            }
        }
    }
    @Published var currentLocation: CLLocation?

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        super.init()
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 30 // meters
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
    }
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        guard isTrackingEnabled else { return }
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            requestLocationPermission()
        default:
            print("Location permission not granted")
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    private func saveLocation(_ location: CLLocation) {
        DispatchQueue.main.async {
            let newItem = Item(context: self.viewContext)
            newItem.timestamp = Date()
            
            // Once latitude and longitude properties are added to Item entity
            #if canImport(CoreData)
            // Check if the Item entity has latitude and longitude properties
            if newItem.responds(to: #selector(setter: Item.latitude)) && 
               newItem.responds(to: #selector(setter: Item.longitude)) {
                newItem.latitude = location.coordinate.latitude
                newItem.longitude = location.coordinate.longitude
            }
            #endif
            
            do {
                try self.viewContext.save()
                print("Location saved: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            } catch {
                print("Failed to save location: \(error)")
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        self.currentLocation = newLocation
        
        self.saveLocation(newLocation)
        
        // Uncomment the following lines if you want to use the new location immediately
        
        // This is called when location updates are available
        // We're using our own periodic sampling, so we don't need to do anything here
        // unless we want to use these updates for something else
        // self.currentLocation = newLocation
        
        // guard let lastLocation = self.lastSavedLocation, let lastTime = self.lastSaveTime else {
        //    self.saveLocation(newLocation)
        //    self.lastSavedLocation = newLocation
        //    self.lastSaveTime = Date()
        //    return
        // }
        
        // let distance = newLocation.distance(from: lastLocation)
        // let timeInterval = Date().timeIntervalSince(lastTime)
        
        // if distance > distanceThreshold || timeInterval > timeThreshold {
        //     self.saveLocation(newLocation)
        //     self.lastSavedLocation = newLocation
        //     self.lastSaveTime = Date()
        // }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        default:
            stopTracking()
        }
    }
}
