//
//  ChatSelectionNetworkManager.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import Firebase

protocol ChatSelectionViewModelDelegate {
    func conversationsUpdated()
}

class ChatSelectionNetworkManager {
    
    // Constants
    struct Constants {
        static let DefaultDateFormat = "MM/dd/yy"
    }
    
    // MARK: - Instance Variables
    private(set) var currentChats : [Message] = []
    private var latestMessageMapping : [String : Message] = [:]
    private var myPhoneNumber : String
    private var chatUserName : String?
    
    var delegate : ChatSelectionViewModelDelegate?
    private lazy var dateFormatter : DateFormatter = {
       let df = DateFormatter()
        df.dateFormat = Constants.DefaultDateFormat
       return df
    }()
    
    // MARK: - Init
    init(delegate : ChatSelectionViewModelDelegate, userPhoneNumber : String) {
        self.delegate = delegate
        self.myPhoneNumber = userPhoneNumber
        beginConversationObservation()
    }
    
    // MARK: - Firebase chat functions
    //Check to see if the phone number of the other user exists, if so, process to chat, else, return false to show that the user does not currently exist
    func shouldStartConversation(withReceiverPhoneNumber : String, completionHandler : @escaping (Bool) -> Void) {
        
        FirebaseDatabase.UserDatabaseReference.observeSingleEvent(of: .value) { (data) in
            if data.hasChild(withReceiverPhoneNumber) {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
        
    }
    
    private func beginConversationObservation() {
        
        //Observe for new conversations being added
        FirebaseDatabase.ConversationDatabaseReference.child(myPhoneNumber).observe(.childAdded) { (data) in
            
            let messageID = data.key
            
            FirebaseDatabase.MessageDatabaseReference.child(messageID).observeSingleEvent(of: .value, with: {[unowned self] (data) in
                guard let values = data.value as? [String : Any] else {
                    return
                }
                
                let dateString = values[MessageKeys.MessageTimeKey] as! String
                
                let messageTime = self.dateFormatter.date(from: dateString)!
                let senderID = values[MessageKeys.MessageSenderKey] as! String
                let senderDisplayName = values[MessageKeys.MessageSenderDisplayNameKey] as! String
                let messageID = data.key
                let receiverID = values[MessageKeys.MessageReceiverKey] as! String
                let newMessage : Message
                
                if let _ = values[MessageKeys.MessageImageURLKey] as? String {

                    newMessage = Message(withText: "[Photo]", senderID: senderID, senderDisplayName: senderDisplayName, messageID: messageID, receiverID: receiverID, timeStamp: messageTime)

                } else  {
                    let messageText = values[MessageKeys.MessageBodyKey] as! String
                    newMessage = Message(withText: messageText, senderID: senderID, senderDisplayName: senderDisplayName, messageID: messageID, receiverID: receiverID, timeStamp: messageTime)
                }
                
                // TODO: - Also check for audio file
                
                //Filter out the latest message to show in the conversation screen, we only want to show one chat group for both user, so we check to see if we are the receiver , if we are, just update the current conversation listing 

                if newMessage.receiverID == self.myPhoneNumber {
                    self.latestMessageMapping[newMessage.senderID] = newMessage
                } else {
                    self.latestMessageMapping[newMessage.receiverID] = newMessage

                }
                
                //Set the conversation list to the values of the latest message mapping
                self.currentChats = Array(self.latestMessageMapping.values)
                
                self.currentChats.sort {
                    $0.timeStamp > $1.timeStamp
                }
                
                self.delegate?.conversationsUpdated()
                
            })
        }
    }
    
    
}
