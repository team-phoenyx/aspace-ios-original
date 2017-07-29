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
        
        homeAddressTextField.theme.font = UIFont.systemFont(ofSize: 14)
        workAddressTextField.theme.font = UIFont.systemFont(ofSize: 14)
        
        homeAddressTextField.highlightAttributes = [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)]
        workAddressTextField.highlightAttributes = [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)]
        
        homeAddressTextField.theme.cellHeight = 40
        workAddressTextField.theme.cellHeight = 40
        
        homeAddressTextField.theme.bgColor = UIColor (red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        workAddressTextField.theme.bgColor = UIColor (red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        let parentViewController = self.parent as! TutorialPageViewController
        
        homeAddressTextField.text = parentViewController.homeName ?? ""
        workAddressTextField.text = parentViewController.workName ?? ""
        
        homeAddressTextField.itemSelectionHandler = { item, itemPosition in
            self.homeAddressTextField.text = item.title
            parentViewController.setHomeLocation(homeAddress: item.subtitle ?? item.title, homeLocID: self.currentSuggestions[itemPosition].id, homeName: item.title)
        }
        
        workAddressTextField.itemSelectionHandler = { item, itemPosition in
            self.workAddressTextField.text = item.title
            parentViewController.setWorkLocation(workAddress: item.subtitle ?? item.title, workLocID: self.currentSuggestions[itemPosition].id, workName: item.title)
        }
        
        homeAddressTextField.userStoppedTypingHandler = {
            if let query = self.homeAddressTextField.text {
                if query.characters.count > 2 {
                    self.homeAddressTextField.showLoadingIndicator()
                    
                    self.getSuggestionsBackground(query) { suggestions in
                        self.homeAddressTextField.filterItems(suggestions)
                        
                        self.homeAddressTextField.stopLoadingIndicator()
                    }
                }
            }
        }
        
        workAddressTextField.userStoppedTypingHandler = {
            if let query = self.workAddressTextField.text {
                if query.characters.count > 2 {
                    self.workAddressTextField.showLoadingIndicator()
                    
                    self.getSuggestionsBackground(query) { suggestions in
                        self.workAddressTextField.filterItems(suggestions)
                        
                        self.workAddressTextField.stopLoadingIndicator()
                    }
                }
            }
        }
    }
    
    func getSuggestionsBackground(_ query: String, callback: @escaping ((_ results: [SearchTextFieldItem]) -> Void)) {
        var newText = query
        newText = newText.replacingOccurrences(of: " ", with: "%20")
        let proximityString = "\(self.currentLocation.longitude),\(self.currentLocation.latitude)"
        let accessToken = "pk.eyJ1IjoicGFyY2FyZSIsImEiOiJjajVpdHpsN2wxa3dxMzNwZ3dsNzFsNjAxIn0.xROQiNWCYJI-3EvHd0-NzQ"
        
        print("Request URL: \(self.geocoderBaseURL)geocoding/v5/mapbox.places/\(newText).json?proximity=\(proximityString)&access_token=\(accessToken)")
        Alamofire.request(self.geocoderBaseURL + "geocoding/v5/mapbox.places/\(newText).json?proximity=\(proximityString)&access_token=\(accessToken)", method: .get).responseJSON { (response: DataResponse<Any>) in
            
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
            
            DispatchQueue.main.async {
                callback(parsedSuggestions)
            }
        }

    }

    
    @IBAction func homeAddressTextChanged(_ sender: SearchTextField) {
        let parentViewController = parent as! TutorialPageViewController
        parentViewController.setHomeLocation(homeAddress: "", homeLocID: "", homeName: "")
    }
    
    @IBAction func workAddressTextChanged(_ sender: SearchTextField) {
        let parentViewController = parent as! TutorialPageViewController
        parentViewController.setWorkLocation(workAddress: "", workLocID: "", workName: "")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location!.coordinate
        print("Current Location = \(self.currentLocation.latitude) \(self.currentLocation.longitude)")
    }
}
