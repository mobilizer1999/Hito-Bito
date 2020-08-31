//
//  ChatMessagesViewController.swift
//  2OneApp
//
//  Created by djay mac on 06/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit
import MediaPlayer

class ChatMessagesViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var titleLabel: UILabel!

    var room:PFObject!
    var incomingUser:PFUser!
    var users = [PFUser]()
    
    var messages = [JSQMessage]()
    var messageObjects = [PFObject]()
    
    var outgoingBubbleImage:JSQMessagesBubbleImage!
    var incomingBubbleImage:JSQMessagesBubbleImage!
    
    var selfAvatar:JSQMessagesAvatarImage!
    var incomingAvatar:JSQMessagesAvatarImage!
    
    var selfUsername:NSString!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navigationBar = self.navigationBar {
            var topPadding: CGFloat = 20
            if #available(iOS 11.0, *) {
                if let window = UIApplication.shared.keyWindow {
                    topPadding = window.safeAreaInsets.top
                }
            }
            self.view.addSubview(navigationBar)
            navigationBar.translatesAutoresizingMaskIntoConstraints = false
            let leadingConstraint = NSLayoutConstraint(item: navigationBar, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 0.0)
            let trailingConstraint = NSLayoutConstraint(item: navigationBar, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
            let topConstraint = NSLayoutConstraint(item: navigationBar, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0.0)
            let heightConstraint = NSLayoutConstraint(item: navigationBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: topPadding + 65)
            self.view.addConstraints([leadingConstraint, trailingConstraint, topConstraint])
            navigationBar.addConstraint(heightConstraint)
            
            self.topContentAdditionalInset = 65
        }
        
        try! incomingUser.fetchIfNeeded()
        
        selfUsername = currentuser?.object(forKey: "name") as? NSString
        let incomingUsername = incomingUser.object(forKey: "name") as!NSString

        self.senderId = currentuser?.objectId
        self.senderDisplayName = currentuser?.username
        
        self.titleLabel.text = incomingUsername as String
        
        if let userimage = currentuser?.object(forKey: "dpSmall") as? PFFileObject {
            
            userimage.getDataInBackground { (data, error) in
                if error == nil{
                    self.selfAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: data!), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                }
            }
            
        } else {
            selfAvatar = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: selfUsername.substring(with: NSMakeRange(0, 2)), backgroundColor: UIColor.black, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        }
        
        
        if let inuserimage = incomingUser.object(forKey: "dpSmall") as? PFFileObject {
            inuserimage.getDataInBackground { (data, error) in
                if error == nil{
                    self.incomingAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: data!), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
                }
            }
            
        } else {
            incomingAvatar = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: incomingUsername.substring(with: NSMakeRange(0, 2)), backgroundColor: UIColor.black, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 14), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        }
     
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImage = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(hex6: 0x94c2e4))
        incomingBubbleImage = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor(hex6: 0xf5f5f5))
        
        loadMessages()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(loadMessages), name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "reloadMessages"), object: nil)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {

        let picker = UIImagePickerController()
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    override func didPressSendButton1(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName name: String!, date: Date!) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    override func didPressSendButton2(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName name: String!, date: Date!) {
        let picker = UIImagePickerController()
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func backBtnTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func barButtonPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: NSLocalizedString("Choose one", comment: ""), message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Unmatch and Block", comment: ""), style: .default, handler: { (alertAction) in
            self.blockUser()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("View Profile", comment: ""), style: .default, handler: { (alertAction) in
            self.showUserProfile()
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func blockUser() {
        let byUser = room.object(forKey:"byUser") as? PFObject
        let toUser = room.object(forKey:"toUser") as? PFObject
        if byUser?.objectId == currentuser?.objectId {
            room["liked"] = false
            
            room.saveInBackground { (done, error) in
                if error == nil{
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
            
          
        } else if toUser?.objectId == currentuser?.objectId {
            room["likedback"] = false
            room.saveInBackground { (done, error) in
                if error == nil{
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
            
        }
        
        
        let query = PFQuery(className: "Messages")
        query.whereKey("match", equalTo: self.room!)
        query.findObjectsInBackground(block: { (objs, error) in
            if error == nil{
                
                for obj in (objs ?? []) as [PFObject] {
                    let ob = obj
                    ob.deleteInBackground()
                }
            
            }
        })
    }
    
    func showUserProfile() {
        let otherprofilevc = storyb.instantiateViewController(withIdentifier: "otherprofilevc") as! OtherProfileViewController
        otherprofilevc.user = self.incomingUser
        otherprofilevc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(otherprofilevc, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pic:UIImage = info[UIImagePickerController.InfoKey.originalImage] as!UIImage
        self.sendMessage(text: "[sent a photo]", pic: pic)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - LOAD MESSAGES
    @objc func loadMessages(){
        
        var lastMessage:JSQMessage? = nil
        
        if messages.last != nil {
            lastMessage = messages.last
        }
        
        
        let messageQuery = PFQuery(className: "Messages")
        messageQuery.whereKey("match", equalTo: room!)
        messageQuery.order(byAscending: "createdAt")
        messageQuery.limit = 500
        messageQuery.includeKey("user")
        
        if lastMessage != nil, let lastMessageDate = lastMessage?.date {
            messageQuery.whereKey("createdAt", greaterThan: lastMessageDate)
        }
        
        messageQuery.findObjectsInBackground(block: { (results, error) in
            if error == nil, let messages = results {
                for message in messages{
                    self.messageObjects.append(message)
                    self.addMessage(object: message)
                }
                
                if results?.count != 0 {
                    self.finishReceivingMessage()
                }
            }
        })
       
    }
    
    //-------------------------------------------------------------------------------------------------------------------------------------------------
    func addMessage(object:PFObject) {
        let user = object["user"] as!PFUser
        self.users.append(user)
        
        
        if let photo = object.object(forKey: "image") as? PFFileObject {
            let mediaItem :JSQPhotoMediaItem = JSQPhotoMediaItem(image: nil)
            mediaItem.appliesMediaViewMaskAsOutgoing = (user.objectId == self.senderId)
            let chatMessage = JSQMessage(senderId: user.objectId, senderDisplayName: user.username, date: object.createdAt, media: mediaItem)
            self.messages.append(chatMessage!)
            
            photo.getDataInBackground { (dpdata, error) -> Void in
                    if error == nil {
                        mediaItem.image = UIImage(data: dpdata!)
                        self.collectionView.reloadData()
                    }
                }
        } else {
            let chatMessage = JSQMessage(senderId: user.objectId, senderDisplayName: user.username, date: object.createdAt, text: object["content"] as? String)
            self.messages.append(chatMessage!)
        }
        
        
        
    }
    
    
    // MARK: - SEND MESSAGES
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if text.isEmpty {
            return
        }
        
        self.sendMessage(text: text, pic: nil)
        self.finishSendingMessage()
    }
 
    func sendMessage(text:String,pic:UIImage?) {
        
        var picf: PFFileObject!
        let message = PFObject(className: "Messages")
        if pic != nil {
            picf = PFFileObject(name: "image.jpg", data: pic!.jpegData(compressionQuality: 0.8)!)
            picf.saveInBackground { (done, error) in
                if error == nil{
                
                }
            }
            message["image"] = picf
        }
        
        message["content"] = text
        message["match"] = room
        message["user"] = currentuser
        
        let pushText = "\(selfUsername ?? ""): \(text)"
        message.saveInBackground { (success, error) -> Void in
            if error == nil {
                self.loadMessages()
                
                let pushQuery = PFInstallation.query()
                pushQuery?.whereKey("user", equalTo: self.incomingUser!)
                
                let push = PFPush()
                push.setQuery(pushQuery as? PFQuery<PFInstallation>)
                
                let pushDict = ["alert":pushText,"badge":"increment","sound":"notification.caf"]
                
                push.setData(pushDict)
                push.sendInBackground(block: nil)
                self.room["lastUpdate"] = NSDate()
                self.room.saveInBackground(block: nil)
            }
        }
    }
    
    // MARK: - DELEGATE METHODS
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.row]
               
        if message.senderId == self.senderId {
            return outgoingBubbleImage
        }

        return incomingBubbleImage
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        
        if message.senderId == self.senderId {
          
            return selfAvatar
        } else {
           
            return incomingAvatar
        }
    }
 
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.item % 1 == 0 {
            let message = messages[indexPath.item]
            
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? JSQMessagesCollectionViewCell
            
            //super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as? JSQMessagesCollectionViewCell
        cell?.avatarImageView.layer.borderWidth = 0.1
        cell?.avatarImageView.layer.masksToBounds = true
        let message = messages[indexPath.row]
        
        // run if only TextView is available
        if let textmessage = cell?.textView {
            if message.senderId == self.senderId {
                textmessage.textColor = .white
            } else {
                textmessage.textColor = .black
            }
            
            cell?.avatarImageView.layer.cornerRadius = 15
            textmessage.layer.masksToBounds = true
            textmessage.backgroundColor = UIColor.clear
        }
        
        return cell ?? UICollectionViewCell()
    }

    // MARK: - DATASOURCE
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         return messages.count
    }
   
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let object = self.messageObjects[indexPath.row] as PFObject
        if let photo = object.object(forKey: "image") as? PFFileObject {

            photo.getDataInBackground { (dpdata, error) -> Void in
                if error == nil && dpdata != nil {
                    self.inputToolbar.contentView.textView.resignFirstResponder()
                    
                    let imageInfo = JTSImageInfo()
                    imageInfo.image = UIImage(data: dpdata!)
                    imageInfo.referenceRect = CGRect(x: phonewidth / 2, y: phoneheight / 2, width: 0, height: 0)
                    imageInfo.referenceView = self.view
                    imageInfo.referenceContentMode = .scaleAspectFit
                    imageInfo.referenceCornerRadius = 10
                    let imgvc = JTSImageViewController(imageInfo: imageInfo, mode: .image, backgroundStyle: .blurred)
                    imgvc?.modalPresentationStyle = .custom
                    imgvc?.show(from: self, transition: .fromOriginalPosition)
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
    }


}
