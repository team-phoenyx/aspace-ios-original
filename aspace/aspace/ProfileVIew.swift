//
//  ProfileVIew.swift
//
//  Created by Terrance Li on 8/1/17.
//  Copyright © 2017 Terrance Li. All rights reserved.
//

import UIKit
import PureLayout

class ProfileView: UIView {
    var shouldSetupConstraints = true
    
    var nameLabel: UILabel!
    var savedLocationsLabel: UILabel!
    var locationsTableView: UITableView!
    
    var parentViewSize: CGRect!
    
    init(frame: CGRect, name: String, locations: [LocationSuggestion]) {
        super.init(frame: frame)
        parentViewSize = superview?.bounds
        
        nameLabel = UILabel()
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
        self.addSubview(nameLabel)
        
        savedLocationsLabel = UILabel()
        savedLocationsLabel.textColor = UIColor.darkGray
        self.addSubview(savedLocationsLabel)
        
        locationsTableView = UITableView()
        self.addSubview(locationsTableView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        parentViewSize = superview?.bounds
    }
    
    override func updateConstraints() {
        if(shouldSetupConstraints) {
            // AutoLayout constraints
            nameLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 32.0)
            savedLocationsLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 16.0)
            locationsTableView.autoPinEdge(.top, to: .bottom, of: savedLocationsLabel, withOffset: 8.0)
            
            nameLabel.autoAlignAxis(.vertical, toSameAxisOf: superview!)
            savedLocationsLabel.autoAlignAxis(.vertical, toSameAxisOf: superview!)
            locationsTableView.autoAlignAxis(.vertical, toSameAxisOf: superview!)
            
            shouldSetupConstraints = false
        }
        super.updateConstraints()
    }
}
