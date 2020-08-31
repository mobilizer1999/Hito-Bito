//
//  ImageFunc.swift
//  Finder
//
//  Created by djay mac on 27/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit


func scaleImage(image:UIImage, and newSize:CGFloat)->UIImage{
    UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize, height: newSize), false, 0.0)
    image.draw(in: CGRect(x: 0, y: 0, width: newSize, height: newSize))
    let newImg = UIGraphicsGetImageFromCurrentImageContext()
    return newImg ??  UIImage()
}


func getImage(forKey:String,imgView:UIImageView) {
    // get user  pics
    if let pic = currentuser?.object(forKey: forKey) as? PFFileObject {
        pic.getDataInBackground { (data, error) in
            if error == nil && data != nil{
                imgView.image = UIImage(data: data!)
            }
        }
     
    }
}









