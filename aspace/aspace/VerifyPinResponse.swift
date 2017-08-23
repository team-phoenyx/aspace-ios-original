//
//  VerifyPinResponse.swift
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import Foundation

class VerifyPinResponse {
    var responseCode: String
    var accessToken: String
    var userID: String
    
    init(_ dictionary: [String: Any]) {
        self.responseCode = dictionary["resp_code"] as? String ?? ""
        self.accessToken = dictionary["access_token"] as? String ?? ""
        self.userID = dictionary["user_id"] as? String ?? ""
    }
}
