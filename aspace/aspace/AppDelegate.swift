//
//  AppDelegate.swift
//
//  Created by Terrance Li on 7/22/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let aspaceBaseURL = "http://138.68.241.101:3000/api/"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController: LoginViewController = mainStoryboard.instantiateViewController(withIdentifier: "LoginController") as! LoginViewController
        let mapViewController: MapViewController = mainStoryboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        
        let storage = UserDefaults.standard
        
        guard let realmEncryptionKey = storage.object(forKey: "realm_encryption_key") as? Data else {
            //login screen
            self.window?.rootViewController = loginViewController
            self.window?.makeKeyAndVisible()
            
            return true
        }
        
        print(realmEncryptionKey)
        
        let config = Realm.Configuration(encryptionKey: realmEncryptionKey)
        do {
            let realm = try Realm(configuration: config)
            
            guard let credentials = realm.objects(UserCredential.self).first else {
                //login screen
                self.window?.rootViewController = loginViewController
                self.window?.makeKeyAndVisible()
                try! realm.write {
                    realm.delete(realm.objects(UserCredential.self))
                }
                
                return true
            }
            
            let reauthParams: Parameters = [
                "user_id": credentials.userID,
                "access_token": credentials.accessToken,
                "phone": credentials.phoneNumber
            ]
            
            //Alamofire REAUTH
            Alamofire.request(aspaceBaseURL + "users/auth/reauth", method: .post, parameters: reauthParams, encoding: URLEncoding.httpBody).responseJSON { (response: DataResponse<Any>) in
                
                let reauthRawResponse = response.map { json -> ResponseCode in
                    let dictionary = json as? [String: Any]
                    return ResponseCode(dictionary!)
                }
                
                if let reauthResponse = reauthRawResponse.value {
                    let code = reauthResponse.responseCode
                    print("Reauthenticate Response Code: \(code)")
                    
                    if code == "101" || code == "102" {
                        self.window?.rootViewController = mapViewController
                        self.window?.makeKeyAndVisible()
                        
                        return
                    } else {
                        //login screen
                        self.window?.rootViewController = loginViewController
                        self.window?.makeKeyAndVisible()
                        try! realm.write {
                            realm.delete(realm.objects(UserCredential.self))
                        }
                        
                        return
                    }
                }
            }

            
        } catch let error as NSError {
            fatalError("Error opening realm: \(error)")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

