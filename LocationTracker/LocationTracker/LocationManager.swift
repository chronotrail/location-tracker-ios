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
    private var lastLocation: CLLocation?
    private var lastSaveTime: Date?
    private var currentSamplingInterval: TimeInterval = 60 // Start with 1 minute
    private var timer: Timer?
    
    // Adaptive sampling parameters
    private let minSamplingInterval: TimeInterval = 10 // 10 seconds
    private let maxSamplingInterval: TimeInterval = 300 // 5 minutes
    private let distanceThreshold: CLLocationDistance = 10 // 10 meters
    private let timeThreshold: TimeInterval = 60 // 1 minute
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            startPeriodicSampling()
        case .notDetermined:
            requestLocationPermission()
        default:
            print("Location permission not granted")
        }
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        stopPeriodicSampling()
    }
    
    private func startPeriodicSampling() {
        timer = Timer.scheduledTimer(withTimeInterval: currentSamplingInterval, repeats: true) { _ in
            self.sampleLocation()
        }
    }
    
    private func stopPeriodicSampling() {
        timer?.invalidate()
        timer = nil
    }
    
    private func sampleLocation() {
        guard let location = locationManager.location else { return }
        saveLocation(location)
        adjustSamplingRate(for: location)
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
    
    private func adjustSamplingRate(for location: CLLocation) {
        guard let lastLocation = self.lastLocation else {
            self.lastLocation = location
            return
        }
        
        let distance = location.distance(from: lastLocation)
        let timeInterval = Date().timeIntervalSince(lastSaveTime ?? Date.distantPast)
        
        // Adjust sampling rate based on movement
        if distance < distanceThreshold && timeInterval < timeThreshold {
            // User is not moving much, increase sampling interval (less frequent)
            currentSamplingInterval = min(maxSamplingInterval, currentSamplingInterval * 1.5)
        } else {
            // User is moving, decrease sampling interval (more frequent)
            currentSamplingInterval = max(minSamplingInterval, currentSamplingInterval / 1.5)
        }
        
        // Update timer with new interval
        stopPeriodicSampling()
        startPeriodicSampling()
        
        self.lastLocation = location
        self.lastSaveTime = Date()
        
        print("Sampling interval adjusted to: \(currentSamplingInterval) seconds")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // This is called when location updates are available
        // We're using our own periodic sampling, so we don't need to do anything here
        // unless we want to use these updates for something else
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