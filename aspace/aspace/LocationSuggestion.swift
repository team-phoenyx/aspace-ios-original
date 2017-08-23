//
//  LocationSuggestion.swift
//
//  Created by Terrance Li on 7/26/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import Foundation
import Mapbox

class LocationSuggestion {
    var id: String
    var name: String
    var address: String
    var coordinates: CLLocationCoordinate2D
    var bboxPythagoreanSize: Double
    
    init(id: String, name: String, address: String, latitude: Double, longitude: Double, bbox: [Double]) {
        self.id = id
        self.name = name
        self.address = address
        self.coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        self.bboxPythagoreanSize = 1200.0
        self.bboxPythagoreanSize = self.getDistanceMeters(latMin: bbox[1], lonMin: bbox[0], latMax: bbox[3], lonMax: bbox[2]) + 500
    }
    
    func getDistanceMeters(latMin: Double, lonMin: Double, latMax: Double, lonMax: Double) -> Double {
        
        if (latMin == 0 && latMax == 0 && lonMin == 0 && lonMax == 0) {
            return 1200.0
        }
        
        let radius: Double = 3959.0 // Miles
        
        let deltaP = (latMax * Double.pi / 180 - latMin * Double.pi / 180)
        let deltaL = (lonMax * Double.pi / 180 - lonMin * Double.pi / 180)
        let a = sin(deltaP/2) * sin(deltaP/2) + cos(latMin * Double.pi / 180) * cos(latMax * Double.pi / 180) * sin(deltaL/2) * sin(deltaL/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = radius * c
        
        return d * 1609.34 // distance in meters rounded to 2 decimal places
    }
}
