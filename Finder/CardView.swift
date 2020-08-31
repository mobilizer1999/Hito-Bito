//
//  CardView.swift
//  Finder
//
//  Created by djay mac on 28/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit
import CoreLocation


class CardView: MDCSwipeToChooseView {
    
    
    var userimage:UIImageView = UIImageView()
    var userdetails:DetailsUser!
    var toUser:PFUser!
    var navController = UINavigationController()
    var user1pic:UIImage!
    var button = UIButton()
    
    
    init(frame:CGRect,user:PFUser,options:MDCSwipeToChooseViewOptions) {
        super.init(frame: frame,options:options)
        
        if self.frame.height > 400.00 {
            self.frame.origin.y = self.frame.origin.y + (self.frame.height - 400)/2
            self.frame.size.height = 400.00
        }
        
        
        userdetails = Bundle.main.loadNibNamed("UserDetails", owner: self, options: nil)?.last as? DetailsUser
        toUser = user
        
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 2
        
        
        userimage.frame = CGRect(x: 5, y: 5, width: self.bounds.width - 10, height: self.bounds.width - 10)
        self.insertSubview(userimage, belowSubview: self.imageView)
        userimage.layer.cornerRadius = 5
        userimage.layer.masksToBounds = true
        
        
        userdetails.frame = CGRect(x: 0, y: self.bounds.height - 80, width: self.bounds.width, height: 80)
        self.addSubview(userdetails)
        
        button = UIButton(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        
        self.addSubview(button)
        getUserDetails(forUser: user)
        

    }

    
    func getUserDetails(forUser:PFUser) {
        
        let name = forUser.object(forKey: "name") as! String
        let age = forUser.object(forKey: "age") as! Int
        let about = forUser.object(forKey: "about") as! String

        userdetails.nameAge.text = "\(name), \(age)"
        userdetails.about.text = "\(about)"
        
        if let mygeo = currentuser?.object(forKey: "location") as? PFGeoPoint,
            let getUsergeo = forUser.object(forKey: "location") as? PFGeoPoint {
            
            let distance: Int = Int(mygeo.distanceInKilometers(to: getUsergeo))
            userdetails.distance.text = "📍\(Int(distance)) km"
        } else {
            userdetails.distance.text = "📍0 km"

        }
        
        // get user  pics
        if let pica = forUser.object(forKey: "dpLarge") as? PFFileObject {
            
            pica.getDataInBackground { (data, error) in
                if error == nil{
                    self.user1pic = UIImage(data: data!)
                    self.userimage.image = self.user1pic
                }
            }
            
        
        }
        
    }

    
    
    override func awakeFromNib() {
        
    }
    
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}
