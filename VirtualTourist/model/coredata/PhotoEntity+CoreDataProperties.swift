//
//  PhotoEntity+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Swifta on 3/23/18.
//  Copyright © 2018 Udacity. All rights reserved.
//
//

import Foundation
import CoreData


extension PhotoEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhotoEntity> {
        return NSFetchRequest<PhotoEntity>(entityName: "Photo")
    }

    @NSManaged public var medialUrl: String?
    @NSManaged public var title: String?
    @NSManaged public var image: NSData?
    @NSManaged public var pin: PinEntity?

}
