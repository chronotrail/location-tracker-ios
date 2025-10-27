
import Foundation
import CoreData
import CoreLocation

@objc(Location)
public class Location: NSManagedObject {

}

extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var needsSync: Bool

}

extension Location : Identifiable {

}
