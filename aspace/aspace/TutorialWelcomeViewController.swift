//
//  TutorialWelcomeViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit

class TutorialWelcomeViewController: UIViewController {

    let storage = UserDefaults.standard
    
    @IBAction func startButtonClick(_ sender: UIButton) {
        self.performSegue(withIdentifier: "tutorialToMapSegue", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tutorialToMapSegue" {
            let mapViewController = segue.destination as! MapViewController
            
            mapViewController.realmEncryptionKey = storage.object(forKey: "realm_encryption_key") as! Data
        }
    }
    
    

}
