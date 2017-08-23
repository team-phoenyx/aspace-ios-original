//
//  ParkingSpot.swift
//
//  Created by Terrance Li on 7/30/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import Foundation
import Mapbox

class ParkingSpot {
    var blockID: String
    var spotID: Int
    var lat: Double
    var lon: Double
    var statusTaken: Bool
    var marker: ParkingSpotPointAnnotation!
    
    init(blockID: String, spotID: Int, lat: Double, lon: Double, statusTaken: Bool) {
        self.blockID = blockID
        self.spotID = spotID
        self.lat = lat
        self.lon = lon
        self.statusTaken = statusTaken
    }
    
    func addMarker(annotation: ParkingSpotPointAnnotation) {
        self.marker = annotation
    }
}
