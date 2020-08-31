//
//  ProfilePhotosButtonCell.swift
//  Finder
//
//  Created by Ying Yu on 5/22/20.
//  Copyright © 2020 DJay. All rights reserved.
//

import UIKit
import FontAwesome_swift
import UIColor_Hex_Swift

class ProfilePhotosButtonCell: UITableViewCell {

    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var bgView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.imgIcon.image = UIImage.fontAwesomeIcon(name: .user, style: .solid, textColor: UIColor("#8f0049"), size: CGSize(width: 25, height: 25))
        
        bgView.layer.shadowRadius = 2
        bgView.layer.shadowOpacity = 0.5
        bgView.layer.shadowColor = UIColor("#c4c4c4").cgColor
        bgView.layer.shadowOffset = CGSize(width: 0, height: 5.0)
        bgView.generateOuterShadow()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
