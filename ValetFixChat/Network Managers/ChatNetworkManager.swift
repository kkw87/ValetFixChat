//
//  ChatNetworkManager.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/31/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MessageKit

protocol ChatNetworkManagerDelegate {
    func messagesUpdated()
    func displayTitleWith(name : String)
    func imageDownloadComplete()
}

class ChatNetworkManager {
    
    struct Constants {
        static let DefaultDateFormat = "MM/dd/yy"
        static let DefaultImageCompression : CGFloat = 0.2
    }

    // MARK: - Instance variables
    private(set) var currentMessages : [Message] = []
    private let myPhoneNumber : String
    private let toPhoneNumber : String
    private(set) var displayName : String
    private lazy var dateFormatter : DateFormatter = {
       let df = DateFormatter()
        df.dateFormat = Constants.DefaultDateFormat
        return df
    }()
    var delegate : ChatNetworkManagerDelegate?
    
    // MARK: - Init
    init(myPhoneNumber : String, toPhoneNumber : String) {
        self.myPhoneNumber = myPhoneNumber
        self.toPhoneNumber = toPhoneNumber
        displayName = ""
        FirebaseDatabase.UserDatabaseReference.child(self.myPhoneNumber).observe(.value) { (data) in
            if let userData = data.value as? [String : Any] {
                self.displayName = userData[UserKeys.UserNameKey] as! String
            }
        }
        retrieveNewMessages()
        retrieveUserName(withID : toPhoneNumber)
    }
    
    // MARK: - Message sending functions
    func retrieveNewMessages() {
        FirebaseDatabase.ConversationDatabaseReference.child(myPhoneNumber).observe(.childAdded) { (data) in
            
            let messageID = data.key
            
            FirebaseDatabase.MessageDatabaseReference.child(messageID).observeSingleEvent(of: .value, with: { (data) in
                
                
                guard let messageValues = data.value as? [String : Any] else {
                    return
                }
                                
                let senderID = messageValues[MessageKeys.MessageSenderKey] as! String
                let senderDisplayName = messageValues[MessageKeys.MessageSenderDisplayNameKey] as! String
                let receiverKey = messageValues[MessageKeys.MessageReceiverKey] as! String
                let messageTime = self.dateFormatter.date(from: messageValues[MessageKeys.MessageTimeKey] as! String)!
                
                // TODO:- Also check for audio
                if let imageDownloadString = messageValues[MessageKeys.MessageImageURLKey] as? String, let downloadURL = URL(string: imageDownloadString) {
                    self.downloadImage(fromURL: downloadURL, completionHandler: { (downloadedImage) in
                        guard let messageImage = downloadedImage else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            let newImageMessage = Message(photo: messageImage, senderID: senderID, senderDisplayName: senderDisplayName, messageID: data.key, receiverID: receiverKey, timeStamp: messageTime)
                            self.currentMessages.append(newImageMessage)
                            self.delegate?.messagesUpdated()
                            self.delegate?.imageDownloadComplete()
                        }
                    })
                    
                } else if let textMessage = messageValues[MessageKeys.MessageBodyKey] as? String {
                    let newTextMessage = Message(withText: textMessage, senderID: senderID, senderDisplayName: senderDisplayName, messageID: data.key, receiverID: receiverKey, timeStamp: messageTime)
                    self.currentMessages.append(newTextMessage)
                }
                
                self.currentMessages.sort {
                    $0.timeStamp < $1.timeStamp
                }
                
                self.delegate?.messagesUpdated()
            })

        }
    }
    
    func sendImageMessage(image : UIImage) {
        
        let imageName = NSUUID().uuidString
        let imageMetadata = StorageMetadata()
        imageMetadata.contentType = "image/jpeg"
        
        let imageReference = FirebaseDatabase.ImageStorageReference.child(imageName)
        
        if let imageData = image.jpegData(compressionQuality: Constants.DefaultImageCompression) {
            let uploadTask = imageReference.putData(imageData, metadata: imageMetadata) { (data, error) in
                
                guard error == nil else {
                    print("Error uploading image : \(error!.localizedDescription)")
                    return
                }
                
                imageReference.downloadURL(completion: { (downloadURL, error) in
                    
                    guard error == nil else {
                        print("Unable to retrieve download url : \(error!.localizedDescription)")
                        return
                    }
                    
                    //Get the download URL from the uploaded image
                    let urlString = downloadURL?.absoluteString
                    
                    //Set the current time of the message being sent
                    let currentTime = self.dateFormatter.string(from: Date())
                    
                    let valueDictionary = [MessageKeys.MessageImageURLKey : urlString,
                                           MessageKeys.MessageReceiverKey : self.toPhoneNumber,
                                           MessageKeys.MessageSenderKey : self.myPhoneNumber,
                                           MessageKeys.MessageTimeKey : currentTime,
                                           MessageKeys.MessageSenderDisplayNameKey : self.displayName
                                            ]
                    
                    FirebaseDatabase.MessageDatabaseReference.childByAutoId().updateChildValues(valueDictionary, withCompletionBlock: { (error, data) in
                        
                        guard error == nil else {
                            print("Unable to upload image message : \(error!.localizedDescription)")
                            return
                        }
                        //Update conversation by sender
                        FirebaseDatabase.ConversationDatabaseReference.child(self.myPhoneNumber).updateChildValues([data.key! : 1])
                        //Update conversations by receiver
                        FirebaseDatabase.ConversationDatabaseReference.child(self.toPhoneNumber).updateChildValues([data.key! : 1])
                        
                    })

                })
                
            }
            
            
        }
        //Upload the image to firebase
        //Get the URL
        //Save the URL to the message
    }
    
    func sendTextMessage(message : String) {
        
        let currentTime = dateFormatter.string(from: Date())
        
        let valueDictionary = [MessageKeys.MessageBodyKey : message,
                               MessageKeys.MessageReceiverKey : toPhoneNumber,
                               MessageKeys.MessageSenderKey : myPhoneNumber,
                               MessageKeys.MessageTimeKey : currentTime,
                               MessageKeys.MessageSenderDisplayNameKey : displayName
                               ]
        
        FirebaseDatabase.MessageDatabaseReference.childByAutoId().updateChildValues(valueDictionary) { (error, data) in

            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            //Update conversation by sender
            FirebaseDatabase.ConversationDatabaseReference.child(self.myPhoneNumber).updateChildValues([data.key! : 1])
            
            //Update conversations by receiver
            FirebaseDatabase.ConversationDatabaseReference.child(self.toPhoneNumber).updateChildValues([data.key! : 1])
        }
    }
    
    func retrieveUserName(withID : String) {
        FirebaseDatabase.UserDatabaseReference.child(withID).observe(.value) { (data) in
            guard let userData = data.value as? [String : Any] else {
                return
            }
            
            if let userName = userData[UserKeys.UserNameKey] as? String {
                self.delegate?.displayTitleWith(name: userName)
            }
        }
    }
    
    // MARK: - Image download functions
    private func downloadImage(fromURL : URL, completionHandler : @escaping (UIImage?) -> Void) {
        
        //Check if image exists in the cache
        
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: fromURL) { (imageData, urlResponse, error) in
            
            guard error == nil else {
                print("Error downloading image message : \(error!.localizedDescription)")
                return
            }
            
            if let serverResponse = urlResponse as? HTTPURLResponse, serverResponse.statusCode == 200, imageData != nil {
                let image = UIImage(data: imageData!)
                //Store image in cache
                completionHandler(image)
            } else {
                print("There was a server response error retrieving message image. ")
            }
            
        }

        DispatchQueue.global(qos: .userInitiated).async {
            dataTask.resume()
        }
        
    }
}
