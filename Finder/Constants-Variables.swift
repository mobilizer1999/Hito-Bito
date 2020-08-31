//
//  Constants-Variables.swift
//  Finder
//
//  Created by djay mac on 27/01/15.
//  Copyright (c) 2015 DJay. All rights reserved.
//

import UIKit

let phonewidth = UIScreen.main.bounds.width
let phoneheight = UIScreen.main.bounds.height

let storyb = UIStoryboard(name: "Main", bundle: nil)

var currentuser = PFUser.current()
let userpf = PFUser()
var matchedPf = PFUser()
var justSignedUp = false

func scaleImage(imagename:String, and newSize:CGSize)->UIImage {
    let image = UIImage(named: imagename)
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image?.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
    let newImg = UIGraphicsGetImageFromCurrentImageContext()
    return newImg ?? UIImage()
}









