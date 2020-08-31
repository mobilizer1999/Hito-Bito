//
//  MainViewController.swift
//  Finder
//
//  Created by djay mac on 27/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit
import CoreLocation
import Social
import SideMenu

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    enum TabItemType: Int {
        case profile
        case matchlist
        case findmatches
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var matchesTableView: UITableView!
    @IBOutlet weak var bottomCenterView: UIView!
    @IBOutlet weak var btnMenu: UIButton!
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var bottomProfileImageView: UIImageView!
    
    // for find matches
    @IBOutlet weak var findMatchesView: UIView!
    @IBOutlet weak var noUsersView: UIView!
    @IBOutlet weak var usersfoundlabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    var frontCardView:CardView?
    var backCardView:CardView?
    var searchRipples: LNBRippleEffect?
    var usersFound:NSMutableArray = []
    var usersArray:NSMutableArray = []
    var findMatchesQuery: PFQuery<PFObject>?
    
    var userpics:[PFFileObject] = []
    var photobuttonclicked:Int! // which button clickd
    var rooms = [PFObject]()
    var users = [PFUser]()
    var tabItemType: TabItemType = .profile
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if PFUser.current() == nil || !(PFUser.current()?.isAuthenticated ?? false) {
            self.performSegue(withIdentifier: "login", sender: self)
        }

        bottomView.layer.cornerRadius = 20
        bottomView.layer.shadowRadius = 4.0
        bottomView.layer.shadowOpacity = 0.5
        bottomView.layer.shadowColor = UIColor.lightGray.cgColor
        bottomView.layer.shadowOffset = CGSize.zero
        bottomView.generateOuterShadow()
        
        bottomCenterView.layer.cornerRadius = 45
        bottomCenterView.layer.shadowRadius = 2
        bottomCenterView.layer.shadowOpacity = 0.5
        bottomCenterView.layer.shadowColor = UIColor.lightGray.cgColor
        bottomCenterView.layer.shadowOffset = CGSize(width: 0, height: 5.0)
        bottomCenterView.generateOuterShadow()
    
        registerCell()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let pic = currentuser?.object(forKey: "dpSmall") as? PFFileObject {
            pic.getDataInBackground { (data, error) in
                if error == nil && data != nil {
                    self.bottomProfileImageView.image = UIImage(data: data!)
                }
            }
        } else {
            self.bottomProfileImageView.image = UIImage(named: "AppIcon")
        }
        
        getPhotos(forKey: "pic1","pic2","pic3","pic4","pic5","pic6")
        
        if let currentUser = PFUser.current(),
            currentUser.isAuthenticated,
            currentuser?["location"] == nil {
            startLocation()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "displayMessage"), object: nil, queue: nil, using: displayPushMessage)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "displayMessage"), object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "logout" {
            showTabBarContent(.profile)
        } else {
            guard let sideMenuNavigationController = segue.destination as? SideMenuNavigationController else { return }
            sideMenuNavigationController.settings.presentationStyle.onTopShadowOpacity = 1.0
        }
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
        self.profileTableView.delegate = self
        self.profileTableView.dataSource = self
    }
    
    @objc func displayPushMessage (notification: Notification) -> Void {
        if self.tabItemType == .matchlist {
            loadMatchData()
        }
        let notificationDict = notification.userInfo! as NSDictionary
        
        if let aps = notificationDict.object(forKey: "aps") as? NSDictionary {
            let messageText = aps.object(forKey: "alert") as! String
            
            let alert = UIAlertController(title: NSLocalizedString("New Message", comment: ""), message: messageText, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: UIAlertAction.Style.default, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func startLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        guard let location = locationManager.location else {
            return
        }
        
        getLocation(location: location)
    }
    
    func getLocation(location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            var locationStr = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
            if error == nil,
                let placemark = placemarks?.first,
                let administrativeArea = placemark.administrativeArea {

                if let locality = placemark.locality {
                    locationStr = String(format: "%@, %@", locality, administrativeArea)
                } else {
                    locationStr = administrativeArea
                }
            }
            
            currentuser?["location"] = PFGeoPoint(location: location)
            currentuser?["locationText"] = locationStr
            currentuser?.saveInBackground(block: { (done, error) in
                if done, error == nil {
                    self.profileTableView.reloadData()
                }
            })
        })
    }
 
    func loadMatchData() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        rooms = [PFObject]()
        users = [PFUser]()
        
        self.matchesTableView.reloadData()
        
        let pred = NSPredicate(format: "byUser = %@ OR toUser = %@", currentuser!, currentuser!)
        
        let query = PFQuery(className: "Matches", predicate: pred)
        query.order(byDescending: "updatedAt")
        query.whereKey("liked", equalTo: true)
        query.whereKey("likedback", equalTo: true)
        
        query.findObjectsInBackground(block: { (results, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if error == nil{
                self.rooms = results!
                
                for room in self.rooms {
                    let user1 = room.object(forKey: "byUser") as! PFUser
                    let user2 = room.object(forKey: "toUser") as! PFUser
                    
                    if user1.objectId != currentuser?.objectId {
                        self.users.append(user1)
                    } else if user2.objectId != currentuser?.objectId {
                        self.users.append(user2)
                    }
                }
                
                self.matchesTableView.reloadData()
            }
        })
    }
    
    func frontCardFrame() -> CGRect {
        var frame: CGRect = .zero
        frame.origin.x = phonewidth / 22
        frame.origin.y = 5
        frame.size.width = phonewidth - frame.origin.x * 2
        frame.size.height = yesButton.frame.origin.y - frame.origin.y - 10
        return frame
    }
    
    func backCardFrame() -> CGRect {
        var frame: CGRect = .zero
        frame.origin.x = phonewidth / 22
        frame.origin.y = 10
        frame.size.width = phonewidth - frame.origin.x * 2
        frame.size.height = yesButton.frame.origin.y - frame.origin.y - 5
        return frame
    }
    
    func stopFindMatches() {
        self.findMatchesQuery?.cancel()
        
        self.noUsersView.isHidden = false
        self.frontCardView?.removeFromSuperview()
        self.backCardView?.removeFromSuperview()
        self.usersFound.removeAllObjects()
        self.usersArray.removeAllObjects()
    }
    
    func startFindMatches() {
        if searchRipples == nil {
            print(searchButton.frame)
            searchRipples = LNBRippleEffect(image: UIImage(named: "find"), frame: searchButton.frame, color: UIColor(hexString: "#8F0049"), target: nil, id: self)
            searchRipples?.setRippleColor(UIColor(hex6: 0x8F0049))
            searchRipples?.setRippleTrailColor(UIColor(hex8: 0x8F004980))
            noUsersView.addSubview(searchRipples!)
        }
                
        self.searchButton.isHidden = true
        
        findUsers { (array) in
            self.usersFound.addObjects(from: array as [AnyObject])
            self.usersArray.addObjects(from: array as [AnyObject])
            
            self.searchRipples?.removeFromSuperview()
            self.searchRipples = nil
            
            if self.usersFound.count > 1 {
                self.noUsersView.isHidden = true
                self.frontCardView = self.popUserView(frame: self.frontCardFrame())
                self.findMatchesView.addSubview(self.frontCardView!)
                self.frontCardView?.button.addTarget(self, action: #selector(self.viewUser(_:)), for: .touchUpInside)
                self.backCardView = self.popUserView(frame: self.backCardFrame())
                self.findMatchesView.insertSubview(self.backCardView!, belowSubview: self.frontCardView!)
                
                self.backCardView?.isUserInteractionEnabled = false
            } else if self.usersFound.count == 1 {
                self.noUsersView.isHidden = true
                self.frontCardView = self.popUserView(frame: self.frontCardFrame())
                self.frontCardView?.button.addTarget(self, action: #selector(self.viewUser(_:)), for: .touchUpInside)
                self.findMatchesView.addSubview(self.frontCardView!)
            } else {
                self.usersfoundlabel.text = NSLocalizedString("No users Found 😓", comment: "")
                self.noUsersView.isHidden = false
                self.searchButton.isHidden = false
            }
        }
    }
    
    func updateMatch(liked: Bool, for user: PFUser) {
        // send push
        if liked {
            let pushQuery = PFInstallation.query()
            pushQuery?.whereKey("user", equalTo: user)
            
            let push = PFPush()
            push.setQuery(pushQuery as? PFQuery<PFInstallation>)
            
            let fromUser: String = (currentuser?.username ?? "") as String
            let pushMessageText = "You've got chat request from \(fromUser). Find nearest users"
            let pushDict = ["alert": pushMessageText,
                            "sound": "notification.caf",
                            "Type": "ChatRquest"]
                
            push.setData(pushDict)
            push.sendInBackground(block: nil)
        }
            
        // update Matches database in server
        let pred = NSPredicate(format: "byUser = %@ AND toUser = %@ OR byUser = %@ AND toUser = %@", currentuser!, user, user, currentuser!)
        let query = PFQuery(className: "Matches", predicate: pred)
        query.findObjectsInBackground(block: { (objects, error) in
            if error != nil {
                return
            }
            
            guard let objects = objects  else {
                return
            }
            
            if let updateObj = objects.first {
                if let byUser = updateObj.object(forKey: "byUser") as? PFUser, byUser.objectId == currentuser?.objectId {
                    currentuser?.addUniqueObject(user.objectId!, forKey: "viewedUsers")
                    currentuser?.saveInBackground()
                } else if let toUser = updateObj.object(forKey: "toUser") as? PFObject, toUser.objectId == currentuser?.objectId {
                    if updateObj.object(forKey: "liked") as! Bool == true && liked == true {
                        self.showMatchFound(forUser: user)
                    }
                    updateObj["likedback"] = liked
                    updateObj.saveInBackground()

                    currentuser?.addUniqueObject(user.objectId!, forKey: "viewedUsers")
                    currentuser?.saveInBackground()
                }
            } else {
                let match = PFObject(className: "Matches")
                match["byUser"] = currentuser
                match["toUser"] = user
                match["liked"] = liked
                match.saveInBackground()
                
                currentuser?.addUniqueObject(user.objectId!, forKey: "viewedUsers")
                currentuser?.saveInBackground()
            }
        })
    }

    @objc func viewUser(_ sender: UIButton) {
        self.showuserprofile()
    }
    
    func showuserprofile() {
        guard let user = self.usersArray.firstObject as? PFUser else {
            return
        }
        
        let otherprofilevc = storyb.instantiateViewController(withIdentifier: "otherprofilevc") as! OtherProfileViewController
        otherprofilevc.user = user
        self.navigationController?.pushViewController(otherprofilevc, animated: true)
    }
    
    func findUsers(fn: @escaping(NSMutableArray) -> ()) { // find all the users
        guard let currentuser = currentuser else {
            return
        }
        
        usersfoundlabel.text = "Searching... "
        
        let limitlocation = currentuser.object(forKey: "locationLimit") as! Double
        let minage = currentuser.object(forKey: "minAge") as! Int
        let maxage = currentuser.object(forKey: "maxAge") as! Int
        let interested = currentuser.object(forKey: "interested") as! Int
        
        let ageArray = [] as NSMutableArray
        for age in minage...maxage {
            ageArray.add(age)
        }
        
        self.findMatchesQuery = PFUser.query()
        self.findMatchesQuery?.whereKey("objectId", notEqualTo: currentuser.objectId!)
        if let viewd = currentuser.object(forKey: "viewedUsers") as? NSArray {
            self.findMatchesQuery?.whereKey("objectId", notContainedIn: viewd as [AnyObject])
        }
        if let usergeo = currentuser.object(forKey: "location") as? PFGeoPoint {
            self.findMatchesQuery?.whereKey("location", nearGeoPoint: usergeo, withinKilometers: limitlocation)
        }

        self.findMatchesQuery?.whereKey("age", containedIn: ageArray as [AnyObject])
        self.findMatchesQuery?.whereKey("gender", equalTo: interested)
        self.findMatchesQuery?.whereKeyExists("dpLarge")
        
        self.findMatchesQuery?.findObjectsInBackground(block: { (objects, error ) in
            if error == nil {
                self.usersArray.removeAllObjects()
                self.usersFound.removeAllObjects()
                let array:NSMutableArray = NSMutableArray(array: objects ?? [])
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    fn(array)
                }
            }
        })
    }
    
    func popUserView(frame: CGRect) -> CardView? {
        if usersFound.count == 0 {
            return nil
        } else {
            let options:MDCSwipeToChooseViewOptions = MDCSwipeToChooseViewOptions()
            options.delegate = self
            options.threshold = 160.0
            options.likedText = NSLocalizedString("Chat", comment: "")
            options.nopeText = NSLocalizedString("Skip", comment: "")
            options.onPan = { (state:MDCPanState!) in
                if state.thresholdRatio == 1.0 && state.direction == .left {
                        
                }
            }
            let _user = self.usersFound[0] as! PFUser
            let userView = CardView(frame: frame, user: _user, options: options)
            
            
            self.usersFound.removeObject(at: 0)
            
            return userView;
        }
    }

    func getPhotos(forKey:String...) {
        // get user  pics
        self.userpics.removeAll(keepingCapacity: false)
        for f in forKey {
            if let pic = currentuser?.object(forKey: f) as? PFFileObject {
                self.userpics.append(pic)
            }
        }

        self.profileTableView.reloadData()
        self.view.layoutSubviews()
    }
    
    func showTabBarContent(_ tabItemType: TabItemType) {
        if tabItemType == self.tabItemType {
            return
        }
        
        self.tabItemType = tabItemType
        
        self.stopFindMatches()
        if (tabItemType == .profile) {
            self.titleLabel.text = "PROFILE"
            self.btnEdit.isHidden = false
            self.profileTableView.isHidden = false
            self.matchesTableView.isHidden = true
            self.findMatchesView.isHidden = true
        } else if (tabItemType == .matchlist) {
            self.titleLabel.text = "Match Result"
            self.btnEdit.isHidden = true
            self.matchesTableView.isHidden = false
            self.profileTableView.isHidden = true
            self.findMatchesView.isHidden = true
            
            loadMatchData()
        } else {
            self.titleLabel.text = "DISCOVERY"
            self.btnEdit.isHidden = true
            self.findMatchesView.isHidden = false
            self.matchesTableView.isHidden = true
            self.profileTableView.isHidden = true
            
            startFindMatches()
        }
    }
    
    func showMatchFound(forUser: PFUser) {
        let matchvc = storyb.instantiateViewController(withIdentifier: "matchfoundvc") as! MatchFoundViewController
        matchvc.getUser = forUser
        matchvc.delegate = self
        self.navigationController?.present(matchvc, animated: false, completion: nil)
    }
    
    @IBAction func didTapProfile(_ sender: AnyObject) {
        showTabBarContent(.profile)
    }
    
    @IBAction func didTapFindMatch(_ sender: AnyObject) {
        showTabBarContent(.findmatches)
    }
    
    @IBAction func didTapMatchedList(_ sender: AnyObject) {
        showTabBarContent(.matchlist)
    }
    
    @IBAction func searchTapped(_ sender: AnyObject) {
        self.startFindMatches()
    }
    
    @IBAction func yesButton(_ sender: AnyObject) {
        self.frontCardView?.mdc_swipe(MDCSwipeDirection.right)
    }
    
    @IBAction func noButton(_ sender: AnyObject) {
        self.frontCardView?.mdc_swipe(.left)
    }
    
    @IBAction func infoPressed(_ sender: AnyObject) {
        self.showuserprofile()
    }
    
    //MARK: TableView Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.profileTableView {
            return 3;
        } else if tableView == self.matchesTableView {
            if rooms.count > 0 {
                return rooms.count
            }
            return 1
        }
        
        return 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.profileTableView {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "OwnProfileImageCell", for: indexPath) as! OwnProfileImageCell
                
                cell.initCell(user: currentuser)
                return cell
            } else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProfilePhotosButtonCell", for: indexPath) as! ProfilePhotosButtonCell
                return cell
            } else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileImagesCell", for: indexPath) as! ProfileImagesCell
                cell.delegate = self
                cell.initCell(photos: self.userpics)
                
                return cell
            }
        } else if tableView == self.matchesTableView {
            if rooms.count == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "nochatcell", for: indexPath)
                cell.selectionStyle = .none
                return cell
                
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "chatcell", for: indexPath) as! ChatViewCell
                cell.selectionStyle = .none
                
                let targetObject = rooms[indexPath.row] as PFObject
                let targetUser = users[indexPath.row] as PFUser
                
                cell.timeAgo.text = String(format: "%@", (targetObject.updatedAt as NSDate?)?.formattedAsTimeAgo() ?? NSLocalizedString("Just", comment: ""));
                cell.backgroundColor = UIColor.clear
                
                cell.timeAgo.textColor = colorText
                cell.nameUser.textColor = colorText
                cell.lastMessage.textColor = colorText
                
                
                let userget = PFUser.query()
                userget?.whereKey("objectId", equalTo: targetUser.objectId!)
                
                userget?.findObjectsInBackground(block: { (objects, error) in
                    if error == nil{
                        if let fUser = objects?.last as? PFUser {
                            cell.nameUser.text = fUser.object(forKey: "name") as? String
                            if let pica = fUser.object(forKey: "dpLarge") as? PFFileObject {
                                
                                pica.getDataInBackground { (data, error) in
                                    if error == nil{
                                        cell.userdp.image = UIImage(data: data!)
                                        cell.userdp.layer.borderColor = colorText.cgColor
                                    }
                                }
                                
                            }
                            
                        }
                    }
                })
                
                
                let getlastmsg = PFQuery(className: "Messages")
                getlastmsg.whereKey("match", equalTo: targetObject)
                getlastmsg.order(byDescending: "createdAt")
                getlastmsg.limit = 1
                getlastmsg.findObjectsInBackground(block: { (objects, error ) in
                    if error == nil{
                        if let msg = objects?.last {
                            cell.lastMessage.text = msg.object(forKey: "content") as? String
                        }
                        if objects?.count == 0 {
                            cell.lastMessage.text = ""
                        }
                    }
                })
                
                return cell
            }
        }
        
        return UITableViewCell()
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.profileTableView {
            return caculateHeightProfileCell(indexPath: indexPath)
        } else if tableView == self.matchesTableView {
            if rooms.count == 0 {
                return 334
            }
            return 104
        }
        
        return 0
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
        
        if tableView == self.matchesTableView {
            if rooms.count > 0 {
                
                let messagesVC = storyb.instantiateViewController(withIdentifier: "messagesvc") as! ChatMessagesViewController
                
                let user = users[indexPath.row] as PFUser
                let targetObject = rooms[indexPath.row] as PFObject
                messagesVC.room = targetObject
                messagesVC.incomingUser = user
                messagesVC.hidesBottomBarWhenPushed = true
                
                self.navigationController?.pushViewController(messagesVC, animated: true)
            }
        }
    }

}


extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height
    }
}


public extension UIView {
    static func fromNib<T>(withOwner: Any? = nil, options: [UINib.OptionsKey : Any]? = nil) -> T where T: UIView
    {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: "\(self)", bundle: bundle)

        guard let view = nib.instantiate(withOwner: withOwner, options: options).first as? T else {
            fatalError("Could not load view from nib file.")
        }
        return view
    }
}

extension MainViewController: ProfileImagesCellDelegate {
    func photoButtonTapped(_ index: Int) {
        photobuttonclicked = index
        let mediapicker = UIImagePickerController()
        mediapicker.allowsEditing = true
        mediapicker.delegate = self
        mediapicker.sourceType = .photoLibrary
        self.present(mediapicker, animated: true, completion: nil)
    }
}

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pickedImg = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        let picFieldName = String(format: "pic%d", photobuttonclicked + 1)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        let imageL = scaleImage(image: pickedImg, and: 320)
        let dataL = imageL.jpegData(compressionQuality: 0.7)
        currentuser?[picFieldName] = PFFileObject(name: "image.jpg", data: dataL!)
        currentuser?.saveInBackground(block: { (done, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if done, error == nil {
                self.getPhotos(forKey: "pic1","pic2","pic3","pic4","pic5","pic6")
                self.profileTableView.reloadData()
            }
        })
        
        self.dismiss(animated: true, completion: nil)
   }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        guard let location = locationManager.location else {
            return
        }
        
        getLocation(location: location)
        locationManager.stopUpdatingLocation()
    }
}

extension MainViewController: MatchFoundViewControllerDelegate {
    func chatNow(room: PFObject, user: PFUser) {
        let messagesVC = storyb.instantiateViewController(withIdentifier: "messagesvc") as! ChatMessagesViewController
        messagesVC.room = room
        messagesVC.incomingUser = user
        self.navigationController?.pushViewController(messagesVC, animated: true)
    }
}

extension MainViewController: MDCSwipeToChooseDelegate {
    func view(_ view: UIView!, shouldBeChosenWith direction: MDCSwipeDirection) -> Bool {
        return true
    }
    
    func view(_ view: UIView!, wasChosenWith direction: MDCSwipeDirection) {
        
        if self.usersArray.count == 0 {
            return
        }

        let user = self.usersArray.firstObject as! PFUser
        self.usersArray.removeObject(at: 0)
        
        if direction == .left  {
            self.updateMatch(liked: false, for: user)
        } else {
            self.updateMatch(liked: true, for: user)
        }
        
        self.frontCardView = self.backCardView
        self.frontCardView?.frame = self.frontCardFrame()
        self.frontCardView?.button.addTarget(self, action: #selector(self.viewUser(_:)), for: .touchUpInside)
        self.frontCardView?.isUserInteractionEnabled = true
        if self.usersFound.count > 0 {
            self.backCardView = self.popUserView(frame: self.backCardFrame())
            self.findMatchesView.insertSubview(self.backCardView!, belowSubview: self.frontCardView!)
            self.backCardView?.isUserInteractionEnabled = false
        }
        
        if self.usersArray.count == 0 {
            self.searchRipples?.removeFromSuperview()
            self.searchRipples = nil
            
            self.usersfoundlabel.text = NSLocalizedString("No users Found 😓", comment: "")
            self.noUsersView.isHidden = false
            self.searchButton.isHidden = false
        }
    }
}
