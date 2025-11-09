//
//  ReverseGeocoder.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 11/8/25.
//

import CoreLocation
import CoreData

class ReverseGeocoder {
    static let shared = ReverseGeocoder()
    private let geocoder = CLGeocoder()
    private var cache: [String: CLPlacemark] = [:]
    private let cacheRadius: CLLocationDistance = 30 // meters
    private init() {}
    
    func resolve(place: Place, in context: NSManagedObjectContext) async {
        guard place.formattedAddress == nil else { return }

        let coordinateKey = String(format: "%.4f,%.4f", place.latitude, place.longitude)
        if let cached = cache.first(where: {
            let parts = $0.key.split(separator: ",")
            guard parts.count == 2,
                  let lat = Double(parts[0]),
                  let lon = Double(parts[1]) else { return false }
            let other = CLLocation(latitude: lat, longitude: lon)
            let current = CLLocation(latitude: place.latitude, longitude: place.longitude)
            return current.distance(from: other) < cacheRadius
        })?.value {
            apply(placemark: cached, to: place, in: context)
            return
        }

        let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let first = placemarks.first {
                cache[coordinateKey] = first
                apply(placemark: first, to: place, in: context)
            }
        } catch {
            print("⚠️ Reverse geocoding failed for \(place): \(error.localizedDescription)")
        }
    }
    
    private func apply(placemark: CLPlacemark, to place: Place, in context: NSManagedObjectContext) {
        place.name = placemark.name
        place.street = placemark.thoroughfare
        place.city = placemark.locality
        place.state = placemark.administrativeArea
        place.country = placemark.country
        place.formattedAddress = [
            placemark.name,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }.joined(separator: ", ")
        try? context.save()
    }
}
