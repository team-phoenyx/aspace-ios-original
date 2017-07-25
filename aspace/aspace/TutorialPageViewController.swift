//
//  TutorialPageViewController.swift
//  aspace
//
//  Created by Terrance Li on 7/24/17.
//  Copyright © 2017 aspace. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var realmEncryptionKey: Data!
    var identifiers: NSArray = ["TutorialStartController", "TutorialNameController", "TutorialCarController", "TutorialLocationsController", "TutorialWelcomeController"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.dataSource = self
        self.delegate = self
        
        let startingViewController = self.viewControllerAtIndex(index: 0)
        let viewControllers: NSArray = [startingViewController!]
        self.setViewControllers(viewControllers as? [UIViewController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor.white
        appearance.currentPageIndicatorTintColor = UIColor.init(rgb: 0x0288D1)
        appearance.backgroundColor = UIColor.darkGray
    }
    
    func viewControllerAtIndex(index: Int) -> UIViewController! {
        switch index {
        case 0:
            return self.storyboard?.instantiateViewController(withIdentifier: "TutorialStartController")
        case 1:
            return self.storyboard?.instantiateViewController(withIdentifier: "TutorialNameController")
        case 2:
            return self.storyboard?.instantiateViewController(withIdentifier: "TutorialCarController")
        case 3:
            return self.storyboard?.instantiateViewController(withIdentifier: "TutorialLocationsController")
        case 4:
            return self.storyboard?.instantiateViewController(withIdentifier: "TutorialWelcomeController")
        default:
            return self.storyboard?.instantiateViewController(withIdentifier: "TutorialStartController")
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let identifier = viewController.restorationIdentifier
        let index = self.identifiers.index(of: identifier!)
        
        //if the index is the end of the array, return nil since we dont want a view controller after the last one
        if index == identifiers.count - 1 {
            return nil
        }
        
        //increment the index to get the viewController after the current index
        return self.viewControllerAtIndex(index: index + 1)
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let identifier = viewController.restorationIdentifier
        let index = self.identifiers.index(of: identifier!)
        
        //if the index is 0, return nil since we dont want a view controller before the first one
        if index == 0 {
            return nil
        }
        
        //decrement the index to get the viewController before the current one
        return self.viewControllerAtIndex(index: index - 1)
        
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.identifiers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
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

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
