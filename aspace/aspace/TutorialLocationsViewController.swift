//
//  TutorialLocationsViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit
import SearchTextField

class TutorialLocationsViewController: UIViewController {
    
    var homeLocID: String!
    var workLocID: String!
    var homeAddress: String!
    var workAddress: String!

    @IBOutlet weak var homeAddressTextField: SearchTextField!
    @IBOutlet weak var workAddressTextField: SearchTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
