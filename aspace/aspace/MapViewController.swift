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
import PMAlertController
import RealmSwift

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    
    //CONSTANTS
    let geocoderBaseURL = "https://api.mapbox.com/"
    let aspaceBaseURL = (UIApplication.shared.delegate as! AppDelegate).aspaceBaseURL
    
    //USER IDENTIFIERS
    var userID: String!
    var accessToken: String!
    var phoneNumber: String!
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
    var parkingSpots: [ParkingSpot]!
    var previousParkingSpots: [ParkingSpot]!
    var redrawSpotIDs = [Int: Int]()
    
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
        
        //INIT USER IDENTIFIERS
        let config = Realm.Configuration(encryptionKey: realmEncryptionKey)
        
        do {
            let realm = try Realm(configuration: config)
            
            guard let credentials = realm.objects(UserCredential.self).first else {
                
                return
            }
            
            self.userID = credentials.userID
            self.accessToken = credentials.accessToken
            self.phoneNumber = credentials.phoneNumber
        } catch let error as NSError {
            fatalError("Error opening realm: \(error)")
        }

        
        //Start spot refresh timer
        var timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.updateSpots), userInfo: nil, repeats: true)
    }
    
    func updateSpots() {
        let ne = mapView.visibleCoordinateBounds.ne
        let sw = mapView.visibleCoordinateBounds.sw
        
        let getVisibleSpotsParams: Parameters = [
            "lower_lat": sw.latitude,
            "lower_lon": sw.longitude,
            "upper_lat": ne.latitude,
            "upper_lon": ne.longitude
        ]
        
        Alamofire.request(self.aspaceBaseURL + "spots/onscreen", method: .post, parameters: getVisibleSpotsParams, encoding: URLEncoding.httpBody).responseJSON { (response: DataResponse<Any>) in
            
            let closestSpotsRawResponse = response.map { json -> GetSpotsResponse in
                let dictionary = json as? [[String: Any]]
                return GetSpotsResponse(dictionary!)
            }
            
            self.parkingSpots = closestSpotsRawResponse.value?.spots ?? []
            
            self.drawSpots()
        }
    }
    
    func drawSpots() {
        var deltaParkingSpots = [ParkingSpot]()
        var removedParkingSpots = [ParkingSpot]()
        var nonDeltaParkingSpots = [ParkingSpot]()
        redrawSpotIDs = [Int: Int]()
        
        
        if (previousParkingSpots != nil && previousParkingSpots.count > 0) {
            let redrawData = getDeltaParkingSpots()
            
            deltaParkingSpots = redrawData[0]
            nonDeltaParkingSpots = redrawData[1]
            removedParkingSpots = redrawData[2]
        } else {
            deltaParkingSpots = self.parkingSpots
        }
        
        //Draw changed spots
        for i in 0..<deltaParkingSpots.count {
            let spot = deltaParkingSpots[i]
            
            //remove the previous marker if there is one
            if (redrawSpotIDs[spot.spotID] != nil) {
                mapView.removeAnnotation(previousParkingSpots[redrawSpotIDs[spot.spotID]!].marker)
            }
            
            let marker = ParkingSpotPointAnnotation()
            marker.coordinate = CLLocationCoordinate2D.init(latitude: spot.lat, longitude: spot.lon)
            if (spot.statusTaken) {
                marker.taken = true
            }
            mapView.addAnnotation(marker)
            spot.addMarker(annotation: marker)
            print("marker added to spot \(spot.spotID)")
            deltaParkingSpots.remove(at: i)
            deltaParkingSpots.insert(spot, at: i)
        }
        
        for removeSpot in removedParkingSpots {
            mapView.removeAnnotation(removeSpot.marker)
        }
        
        previousParkingSpots = deltaParkingSpots + nonDeltaParkingSpots
    }
    
    func getDeltaParkingSpots() -> [[ParkingSpot]] {
        var deltas = [ParkingSpot]()
        var nonDeltas = [ParkingSpot]()
        var removes = [ParkingSpot]()
        
        var spotExists = false
        
        for checkSpot in self.parkingSpots {
            spotExists = false
            
            for i in 0..<self.previousParkingSpots.count {
                let previousCheckSpot = self.previousParkingSpots[i]
                if checkSpot.spotID == previousCheckSpot.spotID {
                    spotExists = true
                    
                    if (checkSpot.lat != previousCheckSpot.lat || checkSpot.lon != previousCheckSpot.lon || checkSpot.statusTaken != previousCheckSpot.statusTaken) {
                        deltas.append(checkSpot)
                        redrawSpotIDs[checkSpot.spotID] = i
                    } else {
                        nonDeltas.append(previousCheckSpot)
                    }
                    
                    break
                }
            }
            if (!spotExists) {
                deltas.append(checkSpot)
            }
        }
        
        for i in 0..<self.previousParkingSpots.count {
            let checkStillExistsSpot = self.previousParkingSpots[i]
            
            let oldSpotID = checkStillExistsSpot.spotID
            var spotStillExists = false
            
            for newSpot in self.parkingSpots {
                if (newSpot.spotID == oldSpotID) {
                    spotStillExists = true
                    break
                }
            }
            
            if (!spotStillExists) {
                self.redrawSpotIDs[oldSpotID] = i
                removes.append(checkStillExistsSpot)
            }
        }
        
        var redrawData = [[ParkingSpot]]()
        
        redrawData.insert(deltas, at: 0)
        redrawData.insert(nonDeltas, at: 1)
        redrawData.insert(removes, at: 2)
        return redrawData
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
    
    @IBAction func profileButtonPressed(_ sender: UIBarButtonItem) {
        let getProfileParams: Parameters = [
            "user_id": self.userID,
            "access_token": self.accessToken,
            "phone": self.phoneNumber
        ]
        
        /*
        Alamofire.request(self.aspaceBaseURL + "users/profile/get", method: .post, parameters: getProfileParams, encoding: URLEncoding.httpBody).responseJSON { (response: DataResponse<Any>) in
            
            
            let closestSpotsRawResponse = response.map { json -> GetSpotsResponse in
                let dictionary = json as? [[String: Any]]
                return GetSpotsResponse(dictionary!)
            }
            
            self.parkingSpots = closestSpotsRawResponse.value?.spots ?? []
            
            self.drawSpots()
        }
        */
        
        
        let alertVC = PMAlertController.init(title: "A Title", description: "My Description", image: nil, style: .alert)
        
        let profileView = ProfileView(frame: alertVC.view.bounds, name: "Terrance", locations: [])
        
        alertVC.headerView = profileView
        
        alertVC.addAction(PMAlertAction(title: "Close", style: .cancel, action: { () -> Void in
            print("Capture action Close")
        }))
        
        alertVC.addAction(PMAlertAction(title: "Settings", style: .default, action: { () in
            print("Capture action Settings")
        }))
        
        self.present(alertVC, animated: true, completion: nil)
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
            
            response.result.ifFailure {
                DispatchQueue.main.async {
                    callback([])
                }
                return
            }
            
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
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        if let castAnnotation = annotation as? ParkingSpotPointAnnotation {
            if (castAnnotation.taken) {
                let reuseIdentifier = "reusableTakenDotView"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
                
                if annotationView == nil {
                    annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
                    annotationView?.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                    annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
                    annotationView?.layer.borderWidth = 1.0
                    annotationView?.layer.borderColor = UIColor.white.cgColor
                    annotationView!.backgroundColor = UIColor(red: 1, green: 0.23, blue: 0.19, alpha: 1.0)
                }
                
                return annotationView
            } else {
                let reuseIdentifier = "reusableOpenDotView"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
                
                if annotationView == nil {
                    annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
                    annotationView?.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                    annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
                    annotationView?.layer.borderWidth = 1.0
                    annotationView?.layer.borderColor = UIColor.white.cgColor
                    annotationView!.backgroundColor = UIColor(red: 0.3, green: 0.85, blue: 0.39, alpha: 1.0)
                }
                
                return annotationView
            }
        } else {
            return nil
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
