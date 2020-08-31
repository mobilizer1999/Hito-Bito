//
//  LoginViewController.swift
//  Finder
//
//  Created by djay mac on 27/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var signUpBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let text = signUpBtn.titleLabel?.text
        let nsText = text! as NSString
        let range = nsText.range(of: NSLocalizedString("Register Now!", comment: ""))
        let attributedText = NSMutableAttributedString(string: signUpBtn.titleLabel?.text ?? "")
        attributedText.addAttributes([.foregroundColor : UIColor("#efb4d5")], range: range)
        signUpBtn.titleLabel?.attributedText = attributedText
        
        // disable push notifiction for this device
        if UIDevice.current.model != "iPhone Simulator" {
            let currentInstallation = PFInstallation.current()
            currentInstallation?.remove(forKey: "user")
            currentInstallation?.saveInBackground()
        }
    }
    
    @IBAction func loginAction(_ sender: Any) {
        guard let username = usernameTF.text, let password = passwordTF.text else {
            return
        }
        
        if username.isEmpty || password.isEmpty {
            let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("username/email is required.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        PFUser.logInWithUsername(inBackground: username, password: password) { (user, error) in
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if error == nil {
                if user != nil {
                    currentuser = user
                    if UIDevice.current.model != "iPhone Simulator" {
                        let currentInstallation = PFInstallation.current()
                        currentInstallation?["user"] = currentuser
                        currentInstallation?.saveInBackground()
                    }
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
            } else {
                
                if let errorString = error?.localizedDescription  {
                    let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: errorString, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
               
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
    
    @IBAction func forgotPasswordAction(_ sender: UIButton) {
        let alertController =
            UIAlertController(title: NSLocalizedString("Forgot Password", comment: ""),
                              message: NSLocalizedString("Input Email Address", comment: ""),
                              preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Email", comment: "")
            textField.textColor = .blue
            textField.clearButtonMode = .whileEditing
            textField.borderStyle = .roundedRect
        }
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: { (action) in
            if let namefield = alertController.textFields?.first, let name = namefield.text, !name.isEmpty {
                self.resetPassword(email: name)
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func resetPassword(email: String) {
        var emailLowercased = email.lowercased()
        emailLowercased = emailLowercased.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if emailLowercased.isEmpty {
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        PFUser.requestPasswordResetForEmail(inBackground: emailLowercased) { (success, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if let error = error {
                let alertController = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("Email request has been sent successfully! Check your email!", comment: ""), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
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
                
                if let username = fbuser?.object(forKey: "name") as? String{
                    currentuser?["fname"] = username // full name
                }
                
                if let gender = fbuser?.object(forKey: "gender") as? String{
                    if gender == "male"{
                        currentuser?["gender"] = 1
                        currentuser?["interested"] = 2
                    }else if gender == "female"{
                        currentuser?["gender"] = 2
                        currentuser?["interested"] = 1
                    }
                }
                
                if let id = fbuser?.object(forKey: "id") as? String{
      
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
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
