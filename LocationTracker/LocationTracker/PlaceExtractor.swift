//
//  PlaceExtractor.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 11/3/25.
//

import Foundation
import CoreData
import CoreLocation

class PlaceExtractor {
    private let viewContext: NSManagedObjectContext
    private let geocoder = CLGeocoder()
    
    // Cache to avoid redundant reverse-geocode calls
    private var geocodeCache: [String: String] = [:]
    
    private let placeDistanceThreshold: CLLocationDistance = 30 // 30 meters
    private let minimumPlaceDuration: TimeInterval = 180 // 3 minutes
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func processNewLocation(_ location: CLLocation) {
        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Place.endTime, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        let currentPlace = try? viewContext.fetch(fetchRequest).first
        
        guard let current = currentPlace else {
            createNewPlace(at: location)
            return
        }
        
        let placeLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)
        let distance = location.distance(from: placeLocation)
        
        if distance < placeDistanceThreshold {
            let oldLatitude = current.latitude
            let oldLongitude = current.longitude
            let oldCount = Double(current.sampleCount)
            
            current.sampleCount += 1
            let newCount = Double(current.sampleCount)
            
            current.latitude = (oldLatitude * oldCount + location.coordinate.latitude) / newCount
            current.longitude = (oldLongitude * oldCount + location.coordinate.longitude) / newCount
            
            current.endTime = location.timestamp
        } else {
            finalize(place: current, leftAt: location.timestamp)
            createNewPlace(at: location)
        }
        
        saveContext()
    }
    
    private func createNewPlace(at location: CLLocation) {
        let newPlace = Place(context: viewContext)
        newPlace.startTime = location.timestamp
        newPlace.endTime = location.timestamp
        newPlace.latitude = location.coordinate.latitude
        newPlace.longitude = location.coordinate.longitude
        newPlace.sampleCount = 1
    }
    
    private func finalize(place: Place, leftAt: Date) {
        place.endTime = leftAt
        guard let start = place.startTime else { return }
        let duration = leftAt.timeIntervalSince(start)
        
        if duration < minimumPlaceDuration  {
            print("Discarding short stay: \(place.startTime ?? Date()) - \(place.endTime ?? Date())")
            viewContext.delete(place)
            return
        }
        
        Task {
            await ReverseGeocoder.shared.resolve(place: place, in: viewContext)
        }
    }
    
    private func reverseGeocode(place: Place) {
        let lat = place.latitude
        let lon = place.longitude
        let cacheKey = String(format: "%.3f,%.3f", lat, lon)
        
        // Avoid redundant lookups
        if let cachedName = geocodeCache[cacheKey] {
            place.name = cachedName
            saveContext()
            print("📍 Used cached address: \(cachedName)")
            return
        }
        
        let location = CLLocation(latitude: lat, longitude: lon)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("⚠️ Reverse geocode failed: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("⚠️ No placemark found for (\(lat), \(lon))")
                return
            }
            
            let name = placemark.name ?? ""
            let street = placemark.thoroughfare ?? ""
            let city = placemark.locality ?? ""
            let state = placemark.administrativeArea ?? ""
            let country = placemark.country ?? ""
            let postal = placemark.postalCode ?? ""
            
            let formatted = [name, street, city, state, postal, country]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            
            place.name = name
            place.street = street
            place.city = city
            place.state = state
            place.country = country
            place.postalCode = postal
            place.formattedAddress = formatted
            
            self.geocodeCache[cacheKey] = formatted
            self.saveContext()
            
            print("🏠 Geocoded place: \(formatted)")
        }
    }
    
    private func saveContext() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
            viewContext.rollback()
        }
    }
}
