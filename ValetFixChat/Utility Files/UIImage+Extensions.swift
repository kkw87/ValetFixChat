//
//  UIImageView+Extensions.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 2/3/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImage {
    
    static func getImageWith(urlString : String) -> UIImage? {
        if let requestedImage = imageCache.object(forKey: urlString as NSString) {
            return requestedImage
        } else {
            return nil
        }
    }
    
    static func storeInCache(imageToStore : UIImage, named : String) {
        imageCache.setObject(imageToStore, forKey: named as! NSString)
    }
    
    
}
