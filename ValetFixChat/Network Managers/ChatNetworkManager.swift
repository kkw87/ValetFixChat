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
    
    // MARK: - Constants
    struct Constants {
        static let DefaultDateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        static let DefaultImageCompression : CGFloat = 0.2
    }
    
    // MARK: - Instance variables
    //Message storage
    private(set) var currentMessages : [Message] = []
    
    //Current users phone number
    private let myPhoneNumber : String
    
    //Phone number of user to send messages to
    private let toPhoneNumber : String
    
    //Default URL session used for file downloads
    private let downloadSession = URLSession(configuration: .default)
    
    //The name of the sending user
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
        
        
        //Pull the current users display name from Firebase and set the displayName variable, this is later used for messageKit cells
        retrieveUserName(withID: myPhoneNumber)
        //We call this function to retrieve the user name of the user we are chatting with, this is displayed in the navigation item title
        retrieveUserName(withID : toPhoneNumber)
        
        //Retrieve current user messages
        retrieveNewMessages()
        
    }
    
    // MARK: - Message sending functions
    func retrieveNewMessages() {
        
        FirebaseDatabase.ConversationDatabaseReference.child(myPhoneNumber).observe(.childAdded) { (data) in
            
            //Save the message ID number
            let messageID = data.key
            
            FirebaseDatabase.MessageDatabaseReference.child(messageID).observeSingleEvent(of: .value, with: { (data) in
                
                
                guard let messageValues = data.value as? [String : Any] else {
                    return
                }
                
                //Check for toNumber equality, the sender or receiver must equal toNumber
                
                let senderID = messageValues[MessageKeys.MessageSenderKey] as! String
                let senderDisplayName = messageValues[MessageKeys.MessageSenderDisplayNameKey] as! String
                let receiverKey = messageValues[MessageKeys.MessageReceiverKey] as! String
                let messageTime = self.dateFormatter.date(from: messageValues[MessageKeys.MessageTimeKey] as! String)!
                
                let chatPartnerID = receiverKey == self.myPhoneNumber ? senderID : receiverKey
                
                //Make sure that the message corresponds to the clicked user, otherwise we ignore it
                guard chatPartnerID == self.toPhoneNumber else {
                    return 
                }
                
                // Check for a valid image URL, if we found one, then we will process an image message
                if let imageDownloadString = messageValues[MessageKeys.MessageImageURLKey] as? String {
                    
                    self.downloadImage(fromURL: imageDownloadString, completionHandler: { (downloadedImage) in
                        guard let messageImage = downloadedImage else {
                            return
                        }
                        
                        let newImessage = Message(withMessageContent: MessageContent.Image(messageImage), senderID: senderID, senderDisplayName: senderDisplayName, messageID: messageID, receiverID: receiverKey, timeStamp: messageTime)
                        
                        self.currentMessages.append(newImessage)
                        self.currentMessages.sort {
                            $0.sentDate < $1.sentDate
                        }
                        
                        DispatchQueue.main.async {
                            self.delegate?.messagesUpdated()
                            
                        }
                        
                    })
                    
                } else {
                    //Otherwise, we check for either an audio message or a string message
                    let messageContent : MessageContent
                    
                    //Found a audio message
                    if let audioMessageDownloadString = messageValues[MessageKeys.MessageAudioURLKey] as? String, let audioDownloadURL = URL(string: audioMessageDownloadString) {
                        
                        messageContent = MessageContent.Audio(audioDownloadURL)
                        //Otherwise, we have a text message, so we force unwrap it
                        
                    } else {
                        //Process a string message
                        let textMessage = messageValues[MessageKeys.MessageBodyKey] as! String
                        messageContent = MessageContent.Text(textMessage)
                    }
                    
                    let newMessage = Message(withMessageContent: messageContent, senderID: senderID, senderDisplayName: senderDisplayName, messageID: messageID, receiverID: receiverKey, timeStamp: messageTime)
                    
                    //Add in the new message and sort it by the timestamp
                    self.currentMessages.append(newMessage)
                    self.currentMessages.sort {
                        $0.sentDate < $1.sentDate
                    }
                    
                    //Let the delegate know that we updated the current messages
                    self.delegate?.messagesUpdated()
                }
                
            })
            
        }
    }
    
    func sendImageMessage(image : UIImage) {
        
        //Give the image a unique name to be stored on firebase
        let imageName = UUID().uuidString
        //Set image metadata
        let imageMetadata = StorageMetadata()
        imageMetadata.contentType = "image/jpeg"
        
        let imageReference = FirebaseDatabase.ImageStorageReference.child(imageName)
        
        //Convert image to data in order to store on firebase
        if let imageData = image.jpegData(compressionQuality: Constants.DefaultImageCompression) {
            
            imageReference.putData(imageData, metadata: imageMetadata) { (data, error) in
                
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
                    
                    self.uploadMessageWith(values: valueDictionary)
                    
                })
                
            }
            
            
        }
    }
    
    //Function for sending messages with audio content
    func sendAudioMessage(audioURL : URL) {
        
        //Provide the audio file with a unique name
        let audioFileServerName = "\(UUID().uuidString).m4a"
        //Provide meta data for firebase
        let audioMetaData = StorageMetadata()
        audioMetaData.contentType = "audio/m4a"
        
        let audioReference = FirebaseDatabase.AudioStorageReference.child(audioFileServerName)
        
        audioReference.putFile(from: audioURL, metadata: audioMetaData) { (data, error) in
            
            guard error == nil else {
                print("Error uploading audio clip : \(error!.localizedDescription)")
                return
            }
            
            audioReference.downloadURL(completion: { (downloadURL, error) in
                guard error == nil else {
                    print("Unable to retrieve audio url : \(error!.localizedDescription)")
                    return
                }
                
                let urlString = downloadURL?.absoluteString
                let currentTime = self.dateFormatter.string(from: Date())
                
                let valueDictionary = [MessageKeys.MessageAudioURLKey : urlString,
                                       MessageKeys.MessageReceiverKey : self.toPhoneNumber,
                                       MessageKeys.MessageSenderKey : self.myPhoneNumber,
                                       MessageKeys.MessageTimeKey : currentTime,
                                       MessageKeys.MessageSenderDisplayNameKey : self.displayName
                ]
                
                self.uploadMessageWith(values: valueDictionary)
            })
            
        }
        
        
        
    }
    
    //Function for sending messages with String content
    func sendTextMessage(message : String) {
        
        let currentTime = dateFormatter.string(from: Date())
        
        let valueDictionary = [MessageKeys.MessageBodyKey : message,
                               MessageKeys.MessageReceiverKey : toPhoneNumber,
                               MessageKeys.MessageSenderKey : myPhoneNumber,
                               MessageKeys.MessageTimeKey : currentTime,
                               MessageKeys.MessageSenderDisplayNameKey : displayName
        ]
        
        self.uploadMessageWith(values: valueDictionary)
    }
    
    // MARK: - Retrieve user helper function
    
    private func retrieveUserName(withID : String) {
        FirebaseDatabase.UserDatabaseReference.child(withID).observe(.value) { (data) in
            guard let userData = data.value as? [String : Any] else {
                return
            }
            
            if let userName = userData[UserKeys.UserNameKey] as? String {
                
                if withID == self.myPhoneNumber {
                    self.displayName = userName
                } else {
                    self.delegate?.displayTitleWith(name: userName)
                }
            }
        }
    }
    
    // MARK: - Media download functions
    private func downloadImage(fromURL : String, completionHandler : @escaping (UIImage?) -> Void) {
        
        //First we check if the image is saved in the cache, if so, we return the cached image
        if let cachedImage = UIImage.getImageWith(urlString: fromURL) {
            completionHandler(cachedImage)
            //Else, the image is not cached and we make a data task on the global queue to fetch the image
        } else if let downloadURL = URL(string: fromURL) {
            let mediaTask = downloadSession.dataTask(with: downloadURL) { (mediaData, urlResponse, error) in
                
                guard error == nil else {
                    print("Error downloading image message : \(error!.localizedDescription)")
                    completionHandler(nil)
                    return
                }
                
                if let serverResponse = urlResponse as? HTTPURLResponse, serverResponse.statusCode == 200, mediaData != nil, let downloadedImage = UIImage(data: mediaData!) {
                    //We downloaded the image, we store it in the cache before running the completion handler
                    UIImage.storeInCache(imageToStore: downloadedImage, named: fromURL)
                    completionHandler(downloadedImage)
                } else {
                    print("There was a server response error retrieving message image. ")
                    completionHandler(nil)
                }
                
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                mediaTask.resume()
            }
        } else {
            completionHandler(nil)
        }
        
    }
    
    // MARK: - Message upload helper
    private func uploadMessageWith(values : [String : String?]) {
        
        //Save the actual message with provided values
        FirebaseDatabase.MessageDatabaseReference.childByAutoId().updateChildValues(values, withCompletionBlock: { (error, data) in
            
            guard error == nil else {
                print("Unable to upload message : \(error!.localizedDescription)")
                return
            }
            //Update conversation by sender
            FirebaseDatabase.ConversationDatabaseReference.child(self.myPhoneNumber).updateChildValues([data.key! : 1])
            //Update conversations by receiver
            FirebaseDatabase.ConversationDatabaseReference.child(self.toPhoneNumber).updateChildValues([data.key! : 1])
            
        })
    }
}
