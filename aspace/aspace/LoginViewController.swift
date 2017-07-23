//
//  ViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/22/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var countryCodeInput: UITextField!
    @IBOutlet weak var phoneNumberInput: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
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
        
        print(compositePhoneNumber)
    }
    
    func reenableButton() {
        signInButton.isEnabled = true
    }
    
    
    //Restricts UITextField to only take in numbers
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let aSet = NSCharacterSet(charactersIn:"0123456789").inverted
        let compSepByCharInSet = string.components(separatedBy: aSet)
        let numberFiltered = compSepByCharInSet.joined(separator: "")
        return string == numberFiltered
    }

}

