//
//  GeocoderResponse.swift
//  aspace
//
//  Created by Terrance Li on 7/26/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import Foundation

class GeocoderResponse {
    var locationSuggestions = [LocationSuggestion]()
    
    init(_ dictionary: [String: Any]) {
        let featuresArray = dictionary["features"] as! [[String : Any]]
        
        for feature in featuresArray {
            let suggestion = LocationSuggestion.init(id: feature["id"] as! String, name: feature["text"] as! String, address: feature["place_name"] as! String)
            locationSuggestions.append(suggestion)
        }
    }

}
