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

class MapViewController: UIViewController, CLLocationManagerDelegate, MGLMapViewDelegate {
    
    var realmEncryptionKey: Data!
    var hasSetInitialMapLocation = false
    
    @IBOutlet weak var snapLocationButton: UIButton!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    var currentHeading: CLLocationDirection!
    
    @IBOutlet weak var searchTextField: SearchTextField!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var mapView: MGLMapView!
    
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
        
        //searchTextField.filterStrings(["test","test2","test3"])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupButton() {
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        visualEffectView.frame = snapLocationButton.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        visualEffectView.isUserInteractionEnabled = false //This allows touches to forward to the button.
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
        var pitch = 0.0
        if snapHeading {
            pitch = currentHeading ?? 0.0
        }
        mapView.setCamera(MGLMapCamera.init(lookingAtCenter: currentLocation, fromDistance: 1200.0, pitch: CGFloat(pitch), heading: 0), animated: true)
    }
    
    @IBAction func snapLocationButtonPressed(_ sender: UIButton) {
        snapLocationToUser(snapHeading: true)
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
