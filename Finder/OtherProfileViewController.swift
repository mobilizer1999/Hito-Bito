//
//  OtherProfileViewController.swift
//  Finder
//
//  Created by SuperDev on 02.06.2020.
//  Copyright © 2020 DJay. All rights reserved.
//

import UIKit

class OtherProfileViewController: UIViewController {
    
    @IBOutlet weak var profileTableView: UITableView!
    
    var user: PFUser?
    var userpics: [PFFileObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        if user == nil {
            return
        }
        
        registerCell()
        getPhotos(forKey: "pic1","pic2","pic3","pic4","pic5","pic6")
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func moreBtnTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Choose", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Report", style: .default, handler: { (alertAction) in
            let report = PFObject(className: "Report")
            report["byUser"] = currentuser
            report["ReportedUser"] = self.user
            report.saveInBackground { (success, error) -> Void in
                if error == nil {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func registerCell(){
        
        let ownProfileImageCell = UINib(nibName: "OwnProfileImageCell",
                            bundle: nil)
        self.profileTableView.register(ownProfileImageCell,
                                forCellReuseIdentifier: "OwnProfileImageCell")
        let ownProfilePhotosButtonCell = UINib(nibName: "ProfilePhotosButtonCell",
                            bundle: nil)
        self.profileTableView.register(ownProfilePhotosButtonCell,
                                forCellReuseIdentifier: "ProfilePhotosButtonCell")
        let ownProfileImagesCell = UINib(nibName: "ProfileImagesCell",
                            bundle: nil)
        self.profileTableView.register(ownProfileImagesCell,
                                forCellReuseIdentifier: "ProfileImagesCell")
    }
    
    func getPhotos(forKey:String...) {
        // get user  pics
        self.userpics.removeAll(keepingCapacity: false)
        for f in forKey {
            if let pic = user?.object(forKey: f) as? PFFileObject {
                self.userpics.append(pic)
            }
        }

        self.profileTableView.reloadData()
        self.view.layoutSubviews()
    }
}

extension OtherProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OwnProfileImageCell", for: indexPath) as! OwnProfileImageCell
            
            cell.initCell(user: user)
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfilePhotosButtonCell", for: indexPath) as! ProfilePhotosButtonCell
            return cell
        } else if indexPath.row == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileImagesCell", for: indexPath) as! ProfileImagesCell
            cell.initCell(photos: self.userpics, isMyProfile: false)
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return caculateHeightProfileCell(indexPath: indexPath)
    }
    
    func caculateHeightProfileCell(indexPath:IndexPath) -> CGFloat{
        let screenSize: CGRect = UIScreen.main.bounds
        if indexPath.row == 0 {
            return (UIScreen.main.bounds.size.width - 14) * 133 / 150 + 20
        } else if indexPath.row == 1 {
            return 66
        } else if indexPath.row == 2 {
            if userpics.count == 0 {
                let cellHeight = (screenSize.width - 3) * 1 / 3
                return cellHeight
            } else if userpics.count == 1 || userpics.count == 2 {
                let cellHeight = (screenSize.width - 3) * 2 / 3
                return cellHeight
            } else if userpics.count > 2 {
                return screenSize.width - 3
            }
        }
        
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
