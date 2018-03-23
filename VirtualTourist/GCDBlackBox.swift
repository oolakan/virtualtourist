//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Swifta on 3/22/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
