//
//  LocationManager.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 10/25/25.
//

import Foundation
import CoreLocation
import CoreMotion
import CoreData

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionActivityManager()
    private var viewContext: NSManagedObjectContext
    private let placeExtractor: PlaceExtractor
    
    private var lastSaveTime: Date?
    private var lastSavedLocation: CLLocation?
    private var isContinuousUpdating = false
    
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
        self.placeExtractor = PlaceExtractor(viewContext: viewContext)
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 30 // meters
        locationManager.activityType = .otherNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
        requestMotionPermission()
    }
    
    func requestMotionPermission() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        motionManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, error in
            if let error = error {
                print("⚠️ Motion permission not granted: \(error.localizedDescription)")
            } else {
                print("✅ Motion permission granted or already authorized")
            }
        }
    }

    func startTracking() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startContinuousUpdates()
        case .notDetermined:
            requestAuthorization()
        default:
            print("⚠️ Location permission not granted")
        }
    }
    
    func stopTracking() {
        stopContinuousUpdates()
        stopMonitoringSignificantChanges()
        stopRegionMonitoring()
    }
    
    func refreshCurrentLocation() {
        if CLLocationManager.locationServicesEnabled() {
            print("📍 Requesting one-time location refresh on launch")
            locationManager.requestLocation()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        guard newLocation.horizontalAccuracy >= 0 && newLocation.horizontalAccuracy <= 100 else {
            print("Discarding inaccurate location. Accuracy: \(newLocation.horizontalAccuracy)")
            return
        }
        
        let now = newLocation.timestamp
        let speed = max(newLocation.speed, 0)
        let movedDistance = newLocation.distance(from: lastSavedLocation ?? newLocation)

        var minInterval: TimeInterval
        if speed > 5 || movedDistance > 100 {
            // Moving fast → sample frequently
            minInterval = 30     // seconds
        } else if speed > 1.5 || movedDistance > 30 {
            // Walking → moderate
            minInterval = 90
        } else {
            // Stationary → slow
            minInterval = 300    // 5 minutes
        }

        if let last = lastSaveTime, now.timeIntervalSince(last) < minInterval {
            queryRecentActivityAndAdjustMode()
            return
        }
        
        currentLocation = newLocation
        saveLocation(newLocation)
        placeExtractor.processNewLocation(newLocation)
        
        lastSaveTime = now
        lastSavedLocation = newLocation
        
        queryRecentActivityAndAdjustMode()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region.identifier == "stay-region" else { return }
        print("🚶 Exited stay region — switching to continuous updates")
        stopRegionMonitoring()
        startContinuousUpdates()
    }
}

private extension LocationManager {
    func saveLocation(_ location: CLLocation) {
        let item = Item(context: viewContext)
        item.timestamp = location.timestamp
        item.latitude = location.coordinate.latitude
        item.longitude = location.coordinate.longitude
        try? viewContext.save()
    }
    
    func startContinuousUpdates() {
        guard !isContinuousUpdating else { return }
        
        print("🚗 Switching to continuous updates")
        stopMonitoringSignificantChanges()
        stopRegionMonitoring()
        
        locationManager.startUpdatingLocation()
        isContinuousUpdating = true
    }
    
    func stopContinuousUpdates() {
        guard isContinuousUpdating else { return }
        
        print("🧘 Switching to significant change updates")
        locationManager.stopUpdatingLocation()

        startMonitoringSignificantChanges()
        if let loc = currentLocation {
            startStayRegion(at: loc)
        }
        isContinuousUpdating = false
    }
    
    func startMonitoringSignificantChanges() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else { return }
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func stopMonitoringSignificantChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func queryRecentActivityAndAdjustMode() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        motionManager.queryActivityStarting(from: Date(timeIntervalSinceNow: -30), to: Date(), to: .main) { [weak self] activities, _ in
            guard let self = self, let activity = activities?.last else { return }

            let isMoving = activity.automotive || activity.cycling || activity.running || activity.walking
            if isMoving && !self.isContinuousUpdating {
                self.startContinuousUpdates()
            } else if !isMoving && self.isContinuousUpdating {
                self.stopContinuousUpdates()
            }
        }
    }
    
    func startStayRegion(at location: CLLocation) {
        stopRegionMonitoring() // clear previous region
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: 120, // meters (minimum reliable radius)
            identifier: "stay-region"
        )
        region.notifyOnExit = true
        region.notifyOnEntry = false
        locationManager.startMonitoring(for: region)
        print("📍 Geofence set at (\(location.coordinate.latitude), \(location.coordinate.longitude))")
    }
    
    func stopRegionMonitoring() {
        for region in locationManager.monitoredRegions where region.identifier == "stay-region" {
            locationManager.stopMonitoring(for: region)
            print("🧹 Removed stay region")
        }
    }
}
