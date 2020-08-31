//
//  MatchFoundViewController.swift
//  Finder
//
//  Created by djay mac on 01/02/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit

protocol MatchFoundViewControllerDelegate: class {
    func chatNow(room: PFObject, user: PFUser)
}

class MatchFoundViewController: UIViewController {
    
    @IBOutlet weak var friendImageView: UIImageView!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var friendNameLabel: UILabel!

    var getUser:PFUser!
    weak var delegate: MatchFoundViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let photoFile = getUser.object(forKey: "dpLarge") as? PFFileObject {
            photoFile.getDataInBackground { (data, error) -> Void in
                if error == nil {
                    self.friendImageView.image = UIImage(data: data!) ?? UIImage()
                }
            }
        }
        
        friendNameLabel.text = getUser.object(forKey: "name") as? String
        
        likeLabel.text = NSLocalizedString("She Said Yes!", comment: "")
        if let gender = currentuser?.object(forKey: "gender") as? Int {
            if gender == 1 {
                likeLabel.text = NSLocalizedString("He Said Yes!", comment: "")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBack(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func startChat(_ sender: AnyObject) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let pred = NSPredicate(format: "byUser = %@ AND toUser = %@ OR byUser = %@ AND toUser = %@", currentuser!, getUser, getUser,  currentuser!)
        let query = PFQuery(className: "Matches", predicate: pred)
        query.findObjectsInBackground { (objects, error) -> Void in
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if error == nil, let obj = objects?.last {
                self.dismiss(animated: false, completion: nil)
                self.delegate?.chatNow(room: obj, user: self.getUser)
            }
        }
    }
}
