//
//  FIrebaseDatabase.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

struct FirebaseDatabase {
    static let UserDatabaseReference = Database.database().reference().child("users")
    static let MessageDatabaseReference = Database.database().reference().child("messages")
    static let ConversationDatabaseReference = Database.database().reference().child("conversations")
    
    static let ImageStorageReference = Storage.storage().reference().child("message_images")
    
    static let AudioStorageReference = Storage.storage().reference().child("message_audio_clips")
}

struct UserKeys {
    static let UserNameKey = "user_name"
    static let UserPhoneNumberKey = "user_phone_number"
}

struct MessageKeys {
    static let MessageSenderKey = "senderID"
    static let MessageSenderDisplayNameKey = "sender_name"
    static let MessageReceiverKey = "receiverID"
    static let MessageBodyKey = "body"
    static let MessageTimeKey = "time_stamp"
    static let MessageImageURLKey = "image_url"
}
