//
//  GetSpotsResponse.swift
//
//  Created by Terrance Li on 7/30/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import Foundation

class GetSpotsResponse {
    var spots = [ParkingSpot]()
    
    init(_ dictionary: [[String: Any]]) {
        for singleSpot in dictionary {
            let parsedSpot = ParkingSpot.init(blockID: (singleSpot["block_id"] as! String), spotID: singleSpot["spot_id"] as! Int, lat: singleSpot["lat"] as! Double, lon: singleSpot["lon"] as! Double, statusTaken: (singleSpot["status"] as! String) == "T")
            
            spots.append(parsedSpot)
        }
    }
}
