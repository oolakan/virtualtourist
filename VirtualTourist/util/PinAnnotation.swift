//
//  PinAnnotation.swift
//  VirtualTourist
//
//  Created by Swifta on 3/23/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import MapKit
import UIKit

class PinAnnotation: NSObject, MKAnnotation {
    var pin: PinEntity
    var coordinate: CLLocationCoordinate2D
    
    init(pin: PinEntity, coordinate: CLLocationCoordinate2D) {
        self.pin = pin
        self.coordinate = coordinate
    }
}

