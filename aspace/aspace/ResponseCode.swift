//
//  ResponseCode.swift
//  aspace
//
//  Created by Terrance Li on 7/23/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import Foundation

class ResponseCode : NSObject {
    var responseCode: String = ""
    
    override init() {
        super.init()
    }
    
    init(_ responseCode: String) {
        self.responseCode = responseCode
    }
}
