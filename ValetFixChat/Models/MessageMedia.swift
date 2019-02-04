//
//  MessagePhoto.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/31/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import MessageKit

//Class used to store message content, MediaItem protocol used by messageKit to layout the cell
class MessageMedia : MediaItem {
    //We use URL as audio file URL
    var url: URL?
    
    //We use the image to determine if the image is an image cell 
    var image: UIImage?
    
    var placeholderImage: UIImage {
        return UIImage(named: "placeHolder")!
    }
    
    var size: CGSize {
        if url == nil {
            return image?.size ?? CGSize.zero

        } else {
            return CGSize(width: 100, height: 100)
        }
    }
    
    init(photo : UIImage) {
        self.image = photo
    }
    
    init(mediaURL : URL) {
        self.url = mediaURL
        self.image = UIImage(named: "audio")
    }
}
