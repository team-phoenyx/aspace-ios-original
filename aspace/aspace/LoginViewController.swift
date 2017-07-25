//
//  ViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/22/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit
import Alamofire
import RealmSwift

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var countryCodeInput: UITextField!
    @IBOutlet weak var phoneNumberInput: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var aspaceBaseURL = "http://192.241.224.224:3000/api/"
    let storage = UserDefaults.standard
    
    @IBAction func signInAction(_ sender: UIButton) {
        signIn(countryCodeInput.text! + phoneNumberInput.text!)
        countryCodeInput.resignFirstResponder()
        phoneNumberInput.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == phoneNumberInput {
            signIn(countryCodeInput.text! + phoneNumberInput.text!)
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        countryCodeInput.delegate = self
        phoneNumberInput.delegate = self
    }

    func signIn(_ compositePhoneNumber: String) {
        activityIndicator.startAnimating()
        signInButton.isEnabled = false
        signInButton.setTitle("Resend", for: UIControlState.normal)
        
        Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(reenableButton), userInfo: nil, repeats: false)
        
        //Alamofire request to server
        let getPinParams: Parameters = [
            "phone" : compositePhoneNumber
        ]
        Alamofire.request(aspaceBaseURL + "users/auth/pin", method: .post, parameters: getPinParams, encoding: URLEncoding.httpBody).responseJSON { (response: DataResponse<Any>) in
            
            let reqPinResponse = response.map { json -> ResponseCode in
                let dictionary = json as? [String: Any]
                return ResponseCode(dictionary!)
            }
            
            if let responseCodeResponse = reqPinResponse.value {
                let code = responseCodeResponse.responseCode
                print("Reqeust PIN Response Code: \(code)")
                
                if code == "100" {
                    let alert = UIAlertController(title: "Enter Pin", message: "You will receive a PIN via text shortly", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addTextField(configurationHandler: {(textField: UITextField!) in
                        textField.placeholder = "Enter PIN"
                        textField.keyboardType = .numberPad
                        textField.isSecureTextEntry = true
                        textField.textAlignment = .center
                        textField.delegate = self
                    })
                    alert.addAction(UIAlertAction(title: "Sign In", style: UIAlertActionStyle.default, handler: {action in
                        self.authenticate(pin: alert.textFields![0].text!, compositePhoneNumber: compositePhoneNumber)
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
                    
                    self.present(alert, animated: true, completion: nil)
                } else {
                    //TODO something went wrong w/ the PIN request
                }
            }
            self.activityIndicator.stopAnimating()
        }
        
        print("PIN requested; Phone #: " + compositePhoneNumber)
    }
    
    func reenableButton() {
        signInButton.isEnabled = true
    }
    
    func authenticate(pin: String, compositePhoneNumber: String) {
        activityIndicator.startAnimating()
        print("Attempt verification; Phone #: " + compositePhoneNumber + "; PIN: " + pin)
        
        //Alamofire request to server
        let verifyPinParams: Parameters = [
            "phone" : compositePhoneNumber,
            "pin" : pin
        ]
        
        Alamofire.request(aspaceBaseURL + "users/auth/verify", method: .post, parameters: verifyPinParams, encoding: URLEncoding.httpBody).responseJSON { (response: DataResponse<Any>) in
            
            let verPinResponse = response.map { json -> VerifyPinResponse in
                let dictionary = json as? [String: Any]
                return VerifyPinResponse(dictionary!)
            }
            
            if let authResponse = verPinResponse.value {
                let code = authResponse.responseCode
                print("Verify PIN Response Code: \(code)")
                
                if code == "101" {
                    self.storeRealmCredentials(userID: authResponse.userID, accessToken: authResponse.accessToken, phoneNumber: compositePhoneNumber)
                    print("Access Token: \(authResponse.accessToken); User ID: \(authResponse.userID)")
                    
                    //TODO NEW USER login successful, move to TUTORIAL
                    self.performSegue(withIdentifier: "loginToTutorialSegue", sender: nil)
                } else if code == "102" {
                    self.storeRealmCredentials(userID: authResponse.userID, accessToken: authResponse.accessToken, phoneNumber: compositePhoneNumber)
                    print("Access Token: \(authResponse.accessToken); User ID: \(authResponse.userID)")
                    
                    //TODO RETURNING USER login successful, move to MAP
                    self.performSegue(withIdentifier: "loginToMapSegue", sender: nil)
                } else {
                    //TODO something went wrong w/ the authentication (make dialog)
                }
            }
            self.activityIndicator.stopAnimating()
        }

    }
    
    func storeRealmCredentials(userID: String, accessToken: String, phoneNumber: String) {
        var realmEncryptionKey: Data
        if (storage.object(forKey: "realm_encryption_key") == nil) {
            realmEncryptionKey = Data(count: 64)
            _ = realmEncryptionKey.withUnsafeMutableBytes { bytes in
                SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
            }
            storage.set(realmEncryptionKey, forKey: "realm_encryption_key")
            print(realmEncryptionKey)
        } else {
            realmEncryptionKey = storage.object(forKey: "realm_encryption_key")! as! Data
            print(realmEncryptionKey)
        }
        
        let config = Realm.Configuration(encryptionKey: realmEncryptionKey)
        do {
            let realm = try Realm(configuration: config)
            
            let credential = UserCredential()
            credential.userID = userID
            credential.accessToken = accessToken
            credential.phoneNumber = phoneNumber
            
            try! realm.write {
                realm.add(credential)
            }
        } catch let error as NSError {
            fatalError("Error opening realm: \(error)")
        }
    }
    
    
    //Restricts UITextField to only take in numbers
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let aSet = NSCharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined(separator: "")
        return string == numberFiltered
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loginToMapSegue" {
            let mapViewController = segue.destination as! MapViewController
            
            mapViewController.realmEncryptionKey = storage.object(forKey: "realm_encryption_key") as! Data
        } else if segue.identifier == "loginToTutorialSegue" {
            let tutorialViewController = segue.destination as! TutorialPageViewController
            
            tutorialViewController.realmEncryptionKey = storage.object(forKey: "realm_encryption_key") as! Data
        }
    }

}

