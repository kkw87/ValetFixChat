//
//  MessagePhoto.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/31/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import MessageKit

struct MessagePhoto : MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage {
        return UIImage(named: "placeHolder")!
    }
    
    var size: CGSize {
        return image?.size ?? CGSize.zero
    }
    
    init(image: UIImage) {
        self.image = image
    }
}
