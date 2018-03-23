//
//  PinEntity+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Swifta on 3/23/18.
//  Copyright © 2018 Udacity. All rights reserved.
//
//

import Foundation
import CoreData


extension PinEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PinEntity> {
        return NSFetchRequest<PinEntity>(entityName: "Pin")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photos: NSSet?

}

// MARK: Generated accessors for photos
extension PinEntity {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: PhotoEntity)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: PhotoEntity)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)

}
