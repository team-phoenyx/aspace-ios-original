//
//  MapViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit
import SearchTextField
import CoreLocation
import Mapbox
import QuartzCore
import Alamofire

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    
    //CONSTANTS
    let geocoderBaseURL: String = "https://api.mapbox.com/"
    
    //REALM
    var realmEncryptionKey: Data!
    
    //BOOL FLAGS
    var hasSetInitialMapLocation = false
    
    //SUGGESTIONS
    var currentSuggestions = [LocationSuggestion]()

    //LOCATION
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    var currentHeading: CLLocationDirection!
    
    //MARKERS
    var destinationMarker: MGLPointAnnotation!
    
    //OUTLETS
    @IBOutlet weak var searchTextField: SearchTextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var snapLocationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //INIT LOCATIONS
        self.locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        //INIT NAVBAR
        self.setupNavigationBar()
        
        //INIT BUTTON
        self.setupButton()
        
        //INIT MAPVIEW
        mapView.delegate = self
        
        //INIT SEARCHTEXTFIELD
        searchTextField.theme.font = UIFont.systemFont(ofSize: 14)
        
        searchTextField.highlightAttributes = [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 14)]
        
        searchTextField.theme.cellHeight = 40
        
        searchTextField.theme.bgColor = UIColor (red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        searchTextField.itemSelectionHandler = { item, itemPosition in
            self.searchTextField.text = item.title
            
            let suggestion = self.currentSuggestions[itemPosition]
            let searchedLocation = suggestion.coordinates
            let size = suggestion.bboxPythagoreanSize
            
            self.mapView.setCamera(MGLMapCamera.init(lookingAtCenter: searchedLocation, fromDistance: size, pitch: 0.0, heading: 0), animated: true)
            self.searchTextField.resignFirstResponder()
            
            self.markDestination(coordinates: searchedLocation, title: item.title) //TODO use subtitles to show availability of parking spaces
        }
        
        searchTextField.userStoppedTypingHandler = {
            if let query = self.searchTextField.text {
                if query.characters.count > 2 {
                    self.searchTextField.showLoadingIndicator()
                    
                    self.getSuggestionsBackground(query) { suggestions in
                        self.searchTextField.filterItems(suggestions)
                        
                        self.searchTextField.stopLoadingIndicator()
                    }
                }
            }
        }
    }
    
    func markDestination(coordinates: CLLocationCoordinate2D, title: String) {
        if (destinationMarker != nil) {
            mapView.removeAnnotation(destinationMarker)
        }
        
        destinationMarker = MGLPointAnnotation()
        destinationMarker.coordinate = coordinates
        destinationMarker.title = title
        mapView.addAnnotation(destinationMarker)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupButton() {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        visualEffectView.frame = snapLocationButton.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        visualEffectView.isUserInteractionEnabled = false
        snapLocationButton.isOpaque = false
        snapLocationButton.insertSubview(visualEffectView, at: 0)
        snapLocationButton.bringSubview(toFront: snapLocationButton.imageView!)
        snapLocationButton.layer.cornerRadius = 8
        snapLocationButton.clipsToBounds = true
    }
    
    func setupNavigationBar() {
        let bounds = self.navigationBar.bounds
        
        //Add the blur effect
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationBar.isTranslucent = true
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.addSubview(visualEffectView)
        self.navigationBar.sendSubview(toBack: visualEffectView)
        
        //Resize textfield
        self.searchTextField.frame.size.width = bounds.width
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location!.coordinate
        print("Current Location = \(self.currentLocation.latitude) \(self.currentLocation.longitude) @ \(currentHeading)")
        
        if !hasSetInitialMapLocation {
            snapLocationToUser(snapHeading: false)
        }
        hasSetInitialMapLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading
    }
    
    func snapLocationToUser(snapHeading: Bool) {
        var heading = 0.0
        if snapHeading {
            heading = currentHeading ?? 0.0
        }
        mapView.setCamera(MGLMapCamera.init(lookingAtCenter: currentLocation, fromDistance: 1200.0, pitch: 0, heading: heading), animated: true)
    }
    
    
    @IBAction func snapLocationButtonPressed(_ sender: UIButton) {
        snapLocationToUser(snapHeading: true)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
