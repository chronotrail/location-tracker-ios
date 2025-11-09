//
//  Place+Extensions.swift
//  LocationTracker
//
//  Created by Jong-Hee Kang on 11/8/25.
//

import Foundation
import CoreData

extension Place {
    var displayAddress: String {
        if let formatted = formattedAddress, !formatted.isEmpty {
            return formatted
        }

        let parts = [street, city, state, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        if parts.isEmpty {
            return String(format: "%.5f, %.5f", latitude, longitude)
        }

        return parts.joined(separator: ", ")
    }
}
