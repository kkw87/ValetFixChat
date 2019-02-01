//
//  UIView+Extensions.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/29/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import UIKit

struct UIViewExtensionConstants {
    static let CornerRadiusForButton : CGFloat = 25
    static let CornerRadiusForLabel : CGFloat = 10
}

extension UIView {
    func roundButtonEdge() {
        self.layer.cornerRadius = UIViewExtensionConstants.CornerRadiusForButton
        self.layer.masksToBounds = true 
    }
    
    func roundLabelEdge() {
        self.layer.cornerRadius = UIViewExtensionConstants.CornerRadiusForLabel
        self.layer.masksToBounds = true 
    }
    
    func makeCircle() {
        self.layer.cornerRadius = self.frame.size.height / 2;
        self.layer.masksToBounds = true;
    }
    
    func hideOver(duration : TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            self.alpha = 0
        }, completion: nil)
    }
    
    func showOver(duration : TimeInterval) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: {
            self.alpha = 1
        }, completion: nil)
    }
}
