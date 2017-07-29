//
//  TutorialWelcomeViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit
import Alamofire

class TutorialWelcomeViewController: UIViewController {

    let storage = UserDefaults.standard
    
    private var aspaceBaseURL = (UIApplication.shared.delegate as! AppDelegate).aspaceBaseURL
    
    @IBAction func startButtonClick(_ sender: UIButton) {
        
        if let parentViewController = self.parent as? TutorialPageViewController {
            let profileParams = parentViewController.getProfileParameters()
            let userIdentifiers = parentViewController.getUserIdentifiers()
            
            //Alamofire request to server
            let updateProfileParams: Parameters = [
                "name" : profileParams[0],
                "home_address": profileParams[1],
                "work_address": profileParams[2],
                "home_loc_id": profileParams[3],
                "work_loc_id": profileParams[4],
                "user_id": userIdentifiers[0],
                "access_token": userIdentifiers[1],
                "phone": userIdentifiers[2]
            ]
            
            Alamofire.request(aspaceBaseURL + "users/profile/update", method: .post, parameters: updateProfileParams, encoding: URLEncoding.httpBody).responseJSON { (response: DataResponse<Any>) in
                
                let updateProfileRawResponse = response.map { json -> ResponseCode in
                    let dictionary = json as? [String: Any]
                    return ResponseCode(dictionary!)
                }
                
                if let updateProfileResponse = updateProfileRawResponse.value {
                    let code = updateProfileResponse.responseCode
                    print("Update Profile Response Code: \(code)")
                    
                    if code == "100" {
                        self.performSegue(withIdentifier: "tutorialToMapSegue", sender: nil)
                    } else {
                        let alert = UIAlertController(title: "Something went wrong", message: "And we aren't sure why :( Please try again shortly", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }

        }
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
