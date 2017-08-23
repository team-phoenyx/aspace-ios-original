//
//  ResponseCode.swift
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import Foundation

class ResponseCode {
    var responseCode: String
    
    init(_ dictionary: [String: Any]) {
        self.responseCode = dictionary["resp_code"] as? String ?? ""
    }
}
