//
//  GeocoderResponse.swift
//
//  Created by Terrance Li on 7/26/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import Foundation

class GeocoderResponse {
    var locationSuggestions = [LocationSuggestion]()
    
    init(_ dictionary: [String: Any]) {
        guard let featuresArray = dictionary["features"] as? [[String : Any]] else {
            return
        }
        
        for feature in featuresArray {
            let suggestion = LocationSuggestion.init(id: feature["id"] as! String, name: feature["text"] as! String, address: feature["place_name"] as! String, latitude: (feature["center"] as! [Double])[1], longitude: (feature["center"] as! [Double])[0], bbox: (feature["bbox"] as? [Double]) ?? [0,0,0,0])
            locationSuggestions.append(suggestion)
        }
    }

}
