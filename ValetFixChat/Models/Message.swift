//
//  Message.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import MessageKit

struct Message : MessageType{
    
    let senderID : String
    let senderDisplayName : String
    let receiverID : String
    let content : MessageKind
    let timeStamp : Date
    let messageID : String
    
    var image : UIImage?
    var imageURL : URL?
    
    //Audio

    init(withText : String, senderID : String, senderDisplayName : String, messageID : String, receiverID : String, timeStamp : Date) {
        self.senderID = senderID
        self.messageID = messageID
        self.timeStamp = timeStamp
        self.receiverID = receiverID
        self.content = MessageKind.text(withText)
        self.senderDisplayName = senderDisplayName
    }
    
    init(photo: UIImage, senderID : String, senderDisplayName : String, messageID : String, receiverID : String, timeStamp : Date) {
        self.senderID = senderID
        self.messageID = messageID
        self.timeStamp = timeStamp
        self.content = MessageKind.photo(MessagePhoto(image: photo))
        self.receiverID = receiverID
        self.senderDisplayName = senderDisplayName
    }

    var sender: Sender {
        return Sender(id: senderID, displayName: senderDisplayName)
    }

    var messageId: String {
        return self.messageID
    }

    var sentDate: Date {
        return timeStamp
    }

    var kind: MessageKind {
        return content
    }

}
