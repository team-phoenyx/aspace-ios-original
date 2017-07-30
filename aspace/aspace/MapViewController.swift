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
    
    @IBOutlet weak var snapLocationButton: UIButton!
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D!
    
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
        print("Current Location = \(self.currentLocation.latitude) \(self.currentLocation.longitude)")
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
