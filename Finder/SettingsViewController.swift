//
//  SettingsViewController.swift
//  Finder
//
//  Created by SuperDev on 28.05.2020.
//  Copyright © 2020 DJay. All rights reserved.
//

import UIKit
import DLRadioButton
import RangeSeekSlider

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var maleButton: DLRadioButton!
    @IBOutlet weak var femaleButton: DLRadioButton!
    @IBOutlet weak var bothGenderButton: DLRadioButton!
    @IBOutlet weak var ageLimitSlider: RangeSeekSlider!
    @IBOutlet weak var locationLimitSlider: RangeSeekSlider!

    override func viewDidLoad() {
        super.viewDidLoad()

        locationLimitSlider.delegate = self
        
        ageLimitSlider.selectedMinValue = currentuser?.object(forKey: "minAge") as? CGFloat ?? 0
        ageLimitSlider.selectedMaxValue = currentuser?.object(forKey: "maxAge") as? CGFloat ?? 0
        locationLimitSlider.selectedMinValue = currentuser?.object(forKey: "locationLimitMin") as? CGFloat ?? 0
        locationLimitSlider.selectedMaxValue = currentuser?.object(forKey: "locationLimit") as? CGFloat ?? 0
        
        if let interestedGender = currentuser?.object(forKey: "interested") as? Int {
            if interestedGender == 1 {
                maleButton.isSelected = true
            } else if interestedGender == 2 {
                femaleButton.isSelected = true
            } else if interestedGender == 3 {
                bothGenderButton.isSelected = true
            }
        }
    }
 
    @IBAction func cancelTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        if maleButton.isSelected {
            currentuser?["interested"] = 1
        } else if femaleButton.isSelected {
            currentuser?["interested"] = 2
        } else if bothGenderButton.isSelected {
            currentuser?["interested"] = 3
        }
        
        currentuser?["locationLimitMin"] = Int(locationLimitSlider.selectedMinValue)
        currentuser?["locationLimit"] = Int(locationLimitSlider.selectedMaxValue)
        currentuser?["minAge"] = Int(ageLimitSlider.selectedMinValue)
        currentuser?["maxAge"] = Int(ageLimitSlider.selectedMaxValue)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        currentuser?.saveInBackground { (done, error) -> Void in
             MBProgressHUD.hide(for: self.view, animated: true)
            if error == nil {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension SettingsViewController: RangeSeekSliderDelegate {
    func rangeSeekSlider(_ slider: RangeSeekSlider, stringForMinValue minValue: CGFloat) -> String? {
        return "\(Int(minValue)) km"
    }

    func rangeSeekSlider(_ slider: RangeSeekSlider, stringForMaxValue maxValue: CGFloat) -> String? {
        return "\(Int(maxValue)) km"
    }
}
