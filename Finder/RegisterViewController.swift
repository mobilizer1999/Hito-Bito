//
//  RegisterViewController.swift
//  Finder
//
//  Created by djay mac on 27/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit
import DLRadioButton

class RegisterViewController: UIViewController {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var fullnameTF: UITextField!
    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var maleBtn: DLRadioButton!
    
    var alertError: String = ""
    var profileImageChanged = false
      
    override func viewDidLoad() {
        super.viewDidLoad()

        let text = loginBtn.titleLabel?.text
        let nsText = text! as NSString
        let range = nsText.range(of: NSLocalizedString("Login", comment: ""))
        let attributedText = NSMutableAttributedString(string: loginBtn.titleLabel?.text ?? "")
        attributedText.addAttributes([.foregroundColor : UIColor("#efb4d5")], range: range)
        loginBtn.titleLabel?.attributedText = attributedText
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signUpAction(_ sender: Any) {
        if self.checkSignup() == true {
            self.createUser()
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: alertError, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func photoAction(_ sender: Any) {
        let mediapicker = UIImagePickerController()
        mediapicker.allowsEditing = true
        mediapicker.delegate = self
        mediapicker.sourceType = .photoLibrary
        self.present(mediapicker, animated: true, completion: nil)
    }
    
     @IBAction func loginFb(_ sender: Any) {
         MBProgressHUD.showAdded(to: self.view, animated: true)
         let permissions = ["public_profile", "email", "user_about_me", "user_friends"]
         
         PFFacebookUtils.logInInBackground(withPublishPermissions: permissions) { (fbuser, error) in
             MBProgressHUD.hide(for: self.view, animated: true)
             if error == nil {
                 if fbuser == nil {
                     
                 } else if fbuser?.isNew ?? false {
                     NSLog("User signed up and logged in through Facebook!")
                     justSignedUp = true
                     currentuser = fbuser
                     self.createFbUser()
                 } else if fbuser != nil {
                     NSLog("User logged in through Facebook!")
                     currentuser = fbuser
                     if UIDevice.current.model != "iPhone Simulator" {
                         let currentInstallation = PFInstallation.current()
                         currentInstallation?["user"] = currentuser
                         currentInstallation?.saveInBackground()
                     }
                     
                     self.navigationController?.dismiss(animated: true, completion: nil)
                 }
             } else {
                 if let errorString = error?.localizedDescription{
                    let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorString, preferredStyle: .alert)
                     alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
                     self.present(alertController, animated: true, completion: nil)
                 }
             }
         }

     }
     
    
     func createFbUser() {
         
        FBRequestConnection.start(withGraphPath: "/me?fields=picture,first_name,name,birthday,gender") { (connection, result, error) in
             
            let fbuser = result as? NSDictionary
            if error == nil{
                if let useremail = fbuser?.object(forKey: "email") as? String {
                    currentuser?.email = useremail
                }
                 
                if let username = fbuser?.object(forKey: "name") as? String {
                    currentuser?["fname"] = username // full name
                }
                 
                if let gender = fbuser?.object(forKey: "gender") as? String {
                    if gender == "male" {
                        currentuser?["gender"] = 1
                        currentuser?["interested"] = 2
                    } else if gender == "female" {
                         currentuser?["gender"] = 2
                         currentuser?["interested"] = 1
                     }
                 }
                 
                 if let id = fbuser?.object(forKey: "id") as? String {
       
                     let url = NSURL(string: "https://graph.facebook.com/\(id)/picture?width=640&height=640")!
                     let data = NSData(contentsOf: url as URL)
                     let image = UIImage(data: data! as Data)
                     let imageL = scaleImage(image: image!, and: 320) // save 640x640 image
                     let imageS = scaleImage(image: image!, and: 60)
                     let dataL = imageL.jpegData(compressionQuality: 0.9)
                     let dataS = imageS.jpegData(compressionQuality: 0.9)
                     currentuser?["dpLarge"] = PFFileObject(name: "dpLarge.jpg", data: dataL!)
                     currentuser?["dpSmall"] = PFFileObject(name: "dpSmall.jpg", data: dataS!)
                     if let firstname = fbuser?.value(forKey: "first_name") as? String
                     {
                         currentuser?["name"] = firstname
                         
                     }
                  
                     currentuser?["fbId"] = id
                     
                     currentuser?["about"] = aboutme
                     currentuser?["age"] = 18
                     currentuser?["minAge"] = 18
                     currentuser?["maxAge"] = 60
                     currentuser?["locationLimit"] = 500
                     MBProgressHUD.showAdded(to: self.view, animated: true)
                     currentuser?.saveInBackground(block: { (done, error) in
                         MBProgressHUD.hide(for: self.view, animated: true)
                         if error == nil{
                             if UIDevice.current.model != "iPhone Simulator" {
                                 let currentInstallation = PFInstallation.current()
                                 currentInstallation?["user"] = currentuser
                                 currentInstallation?.saveInBackground()
                             }
                 
                             self.navigationController?.dismiss(animated: true, completion: nil)
                         }
                     })
                     
                 }
             }
         }
     }
    
    func checkSignup()-> Bool {
        if (usernameTF.text?.isEmpty ?? true) || (emailTF.text?.isEmpty ?? true) || (passwordTF.text?.isEmpty ??  true) {
            
            alertError = "Oops! Text is empty"
            return false
        } else if (usernameTF.text?.count ?? 0) < 4 {

            alertError = "Username should be more than 3"
            return false
        } else if (passwordTF.text?.count ?? 0) < 3 {
    
            alertError = "Password should be more than 5"
            return false
        } else if !maleBtn.isSelected, !maleBtn.otherButtons[0].isSelected {
            
            alertError = "Gender should be selected"
            return false
        }
        return true
    }
    
    
    func createUser() {
        userpf.username = usernameTF.text
        userpf.password = passwordTF.text
        userpf.email = emailTF.text

        userpf["fname"] = fullnameTF.text
        
        let firstname = fullnameTF.text?.components(separatedBy: " ") //fullnameTF.text.componentsSeparatedByString(" ")
        userpf["name"] = (firstname?[0] ?? "") as String
        userpf["about"] = aboutme
        userpf["age"] = 18
        userpf["minAge"] = 18
        userpf["maxAge"] = 60
        userpf["locationLimit"] = 500
        userpf["gender"] = maleBtn.isSelected ? 1 : 2
        userpf["interested"] = 2
        
        if profileImageChanged, let image = self.profileImage.image {
            let imageL = scaleImage(image: image, and: 320)
            let imageSmall = scaleImage(image: image, and: 60)
            let dataL = imageL.jpegData(compressionQuality: 0.7)
            let dataS = imageSmall.jpegData(compressionQuality: 0.7)
            userpf["dpLarge"] = PFFileObject(name: "image.jpg", data: dataL!)
            userpf["dpSmall"] = PFFileObject(name: "image.jpg", data: dataS!)
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        userpf.signUpInBackground {
            (succeeded, error) -> Void in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            if error == nil {
                justSignedUp = true
                currentuser = userpf
                if UIDevice.current.model != "iPhone Simulator" {
                    let currentInstallation = PFInstallation.current()
                    currentInstallation?["user"] = currentuser
                    currentInstallation?.saveInBackground()
                }
                self.navigationController?.dismiss(animated: true, completion: nil)
            } else {
                if let errorString = error?.localizedDescription {
                    let alertController = UIAlertController(title: "Error", message: errorString, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }    
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pickedImg = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        profileImage.image = pickedImg
        profileImageChanged = true
        
        self.dismiss(animated: true, completion: nil)
    }
}
