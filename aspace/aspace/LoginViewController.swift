//
//  ViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/22/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit
import Alamofire

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var countryCodeInput: UITextField!
    @IBOutlet weak var phoneNumberInput: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    private var aspaceBaseURL = "http://192.241.224.224:3000/api/"
    
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func signIn(_ compositePhoneNumber: String) {
        signInButton.isEnabled = false
        signInButton.setTitle("Resend", for: UIControlState.normal)
        
        Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(reenableButton), userInfo: nil, repeats: false)
        
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
        
        //Alamofire request to server
        //Alamofire.request(aspaceBaseURL + "users/auth/pin").response
        
        print("PIN requested; Phone #: " + compositePhoneNumber)
    }
    
    func reenableButton() {
        signInButton.isEnabled = true
    }
    
    func authenticate(pin: String, compositePhoneNumber: String) {
        print("Attempt verification; Phone #: " + compositePhoneNumber + "; PIN: " + pin)
    }
    
    
    //Restricts UITextField to only take in numbers
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let aSet = NSCharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined(separator: "")
        return string == numberFiltered
    }

}

