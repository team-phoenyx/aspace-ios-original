//
//  UserCredential.swift
//  aspace
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import Foundation
import RealmSwift

class UserCredential: Object {
    dynamic var userID: String = ""
    dynamic var accessToken: String = ""
    dynamic var phoneNumber: String = ""
}
