//
//  LocationSuggestion.swift
//  aspace
//
//  Created by Terrance Li on 7/26/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import Foundation

class LocationSuggestion {
    var id: String
    var name: String
    var address: String
    
    init(id: String, name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}
