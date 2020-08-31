//
//  EditProfileViewController.swift
//  Finder
//
//  Created by SuperDev on 27.05.2020.
//  Copyright © 2020 DJay. All rights reserved.
//

import UIKit
import DLRadioButton

class EditProfileViewController: UIViewController {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var maleButton: DLRadioButton!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var aboutText: UITextView!
    @IBOutlet weak var ageTF: UITextField!
    @IBOutlet weak var locationBtn: UIButton!
    var location: Location!
    
    var profileImageChanged:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        aboutText.layer.borderColor = UIColor(hex6: 0xc5c5c5).cgColor
        aboutText.layer.borderWidth = 0.5
        
        getImage(forKey: "dpLarge",imgView: profileImage)

        nameTF.text = currentuser?.object(forKey: "name") as? String
        aboutText.text = currentuser?.object(forKey: "about") as? String
        
        if let age = currentuser?.object(forKey: "age") as? Int {
            ageTF.text = String(format: "%ld", age)
        } else {
            ageTF.text = "99"
        }
        
        if let gender = currentuser?.object(forKey: "gender") as? Int {
            if gender == 1 {
                maleButton.isSelected = true
            } else {
                maleButton.otherButtons[0].isSelected = true
            }
        }
        
        if let locationStr = currentuser?.object(forKey: "locationText") as? String, !locationStr.isEmpty {
            locationBtn.setTitle(locationStr, for: .normal)
        }
        
    }
    
    @IBAction func locationTapped(_ sender: Any) {
        let alert = UIAlertController(style: .actionSheet, source: nil, title: NSLocalizedString("Pick Location", comment: ""), message: nil, tintColor: nil)
        
        alert.addLocationPicker { (location) in
            if let loc = location {
                self.location = loc
                self.locationBtn.setTitle(loc.address, for: .normal)
            }
        }
        
        alert.addAction(image: nil, title: NSLocalizedString("Cancel", comment: ""), color: nil, style: .cancel, isEnabled: true) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.show()
    }

    @IBAction func cancelTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func profiledpTapped(_ sender: Any) {
        let mediapicker = UIImagePickerController()
        mediapicker.allowsEditing = true
        mediapicker.delegate = self
        mediapicker.sourceType = .photoLibrary
        self.present(mediapicker, animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        if nameTF.text?.isEmpty ?? true {
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Name Cannnot be Empty", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        if ageTF.text?.isEmpty ?? true {
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Age Cannot be Empty", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        currentuser?["name"] = nameTF.text
        currentuser?["about"] = aboutText.text
        currentuser?["gender"] = maleButton.isSelected ? 1 : 2
        currentuser?["age"] = Int(ageTF.text ?? "0")
        
        if let location = self.location {
            currentuser?["location"] = PFGeoPoint(location: location.location)
            currentuser?["locationText"] = location.address
        }
            
        if profileImageChanged == true {
            let imageL = scaleImage(image: self.profileImage.image!, and: 320)
            let imageSmall = scaleImage(image: self.profileImage.image!, and: 60)
            let dataL = imageL.jpegData(compressionQuality: 0.7)
            let dataS = imageSmall.jpegData(compressionQuality: 0.7)
            currentuser?["dpLarge"] = PFFileObject(name: "image.jpg", data: dataL!)
            currentuser?["dpSmall"] = PFFileObject(name: "image.jpg", data: dataS!)
        }

        MBProgressHUD.showAdded(to: self.view, animated: true)
        currentuser?.saveInBackground(block: { (done, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if done, error == nil {
                self.navigationController?.popViewController(animated: true)
            }
        })
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pickedImg = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        profileImageChanged = true
        profileImage.image = pickedImg
        
         self.dismiss(animated: true, completion: nil)
    }
}

extension EditProfileViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let textlength = (textView.text as NSString).length + (text as NSString).length - range.length
        if text == "\n" {
            textView.resignFirstResponder()
        }
        return (textlength > 150) ? false : true
    }
}
