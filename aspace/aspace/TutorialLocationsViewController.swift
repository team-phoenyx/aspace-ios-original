//
//  TutorialLocationsViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit
import SearchTextField
import CoreLocation
import Alamofire

class TutorialLocationsViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    
    let geocoderBaseURL: String = "https://api.mapbox.com/"
    
    var currentSuggestions = [LocationSuggestion]()
    
    var homeLocID: String!
    var workLocID: String!
    var homeAddress: String!
    var workAddress: String!

    @IBOutlet weak var homeAddressTextField: SearchTextField!
    @IBOutlet weak var workAddressTextField: SearchTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }

        homeAddressTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        workAddressTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        homeAddressTextField.inlineMode = true
        workAddressTextField.inlineMode = true
        
        homeAddressTextField.itemSelectionHandler = { item, itemPosition in
            self.homeAddressTextField.text = item.title
            self.homeAddress = item.title
            self.homeLocID = self.currentSuggestions[itemPosition].id
        }
        
        workAddressTextField.itemSelectionHandler = { item, itemPosition in
            self.workAddressTextField.text = item.title
            self.workAddress = item.title
            self.workLocID = self.currentSuggestions[itemPosition].id
        }
    }
    
    func textFieldDidChange(_ textField: SearchTextField) {
        var newText = textField.text!
        
        if (newText == "") { return }
        
        newText = newText.replacingOccurrences(of: " ", with: "%20")
        let proximityString = "\(currentLocation.longitude),\(currentLocation.latitude)"
        let accessToken = "pk.eyJ1IjoicGFyY2FyZSIsImEiOiJjajVpdHpsN2wxa3dxMzNwZ3dsNzFsNjAxIn0.xROQiNWCYJI-3EvHd0-NzQ"
        
        print("Request URL: \(geocoderBaseURL)geocoding/v5/mapbox.places/\(newText).json?proximity=\(proximityString)&access_token=\(accessToken)")
        Alamofire.request(geocoderBaseURL + "geocoding/v5/mapbox.places/\(newText).json?proximity=\(proximityString)&access_token=\(accessToken)", method: .get).responseJSON { (response: DataResponse<Any>) in
            
            let geocodeResponse = response.map { json -> GeocoderResponse in
                let dictionary = json as? [String: Any]
                return GeocoderResponse(dictionary!)
            }
            
            
            self.currentSuggestions.removeAll()
            self.currentSuggestions = (geocodeResponse.value?.locationSuggestions)!
            
            var parsedSuggestions = [SearchTextFieldItem]()
            for suggestion in self.currentSuggestions {
                let singleParsedSuggestion = SearchTextFieldItem(title: suggestion.name, subtitle: suggestion.address)
                parsedSuggestions.append(singleParsedSuggestion)
            }
            
            textField.filterItems(parsedSuggestions)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location!.coordinate
        print("Current Location = \(self.currentLocation.latitude) \(self.currentLocation.longitude)")
    }
}
