//
//  OwnProfileImageCell.swift
//  Finder
//
//  Created by Ying Yu on 5/22/20.
//  Copyright © 2020 DJay. All rights reserved.
//

import UIKit

class OwnProfileImageCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblUserAbout: UILabel!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblUserLocation: UILabel!
    @IBOutlet weak var lblUserDistance: UILabel!
    @IBOutlet weak var imgLocationIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imgLocationIcon.image = UIImage(named: "ic_location")?.imageWithColor(color: .white)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initCell(imageFile:PFFileObject?){
        
        if let pic = imageFile {
            pic.getDataInBackground { (data, error) in
                if error == nil && data != nil{
                    self.imgView.image = UIImage(data: data!)
                }
            }
         
        }else{
            self.imgView.image = UIImage(named: "AppIcon")
        }
    }
    
    func initCell(user: PFUser?) {
        guard let user = user else {
            self.lblUserName.text = ""
            self.lblUserDistance.text = ""
            self.lblUserLocation.text = ""
            self.imgLocationIcon.isHidden = true
            self.lblUserAbout.text = ""
            self.imgView.image = UIImage(named: "AppIcon")
            return
        }
        
        if let pic = user.object(forKey: "dpLarge") as? PFFileObject {
            pic.getDataInBackground { (data, error) in
                if error == nil && data != nil {
                    self.imgView.image = UIImage(data: data!)
                }
            }
        } else {
            self.imgView.image = UIImage(named: "AppIcon")
        }
        
        let name = user.object(forKey: "name") as? String ?? ""
        let age: Int = user.object(forKey: "age") as? Int ?? 30
        
        self.lblUserName.text = String(format: "%@, %d", name, age)
        self.lblUserAbout.text = user.object(forKey: "about") as? String ?? ""
        self.lblUserLocation.text = user.object(forKey: "locationText") as? String ?? ""
        
        if user != currentuser {
            self.imgLocationIcon.isHidden = false
            if let mygeo = currentuser?.object(forKey: "location") as? PFGeoPoint,
                let getUsergeo = user.object(forKey: "location") as? PFGeoPoint {
                
                let distance: Int = Int(mygeo.distanceInKilometers(to: getUsergeo))
                lblUserDistance.text = "\(distance) km"
                
            } else {
                lblUserDistance.text = "0 km"
            }
        } else {
            self.imgLocationIcon.isHidden = true
            lblUserDistance.text = ""
        }
    }

}
