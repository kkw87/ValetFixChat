//
//  ChatViewController.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import UIKit
import Firebase
import MessageKit
import Photos
import MessageInputBar

class ChatViewController : MessagesViewController {
    
    // MARK: - User phone numbers
    var myPhoneNumber : String?
    var receiverPhoneNumber : String?
    
    // MARK: - Storyboard
    struct Storyboard {
        static let ChatCellIdentifier = "Chat Message Cell"
        static let CellNibFile = "MessageCell"
        static let GoBackToChatSelectionSegue = "Go Back To Chat Selection"
    }
    
    struct Constants {
        static let DefaultRowHeight : CGFloat = 120.0
        static let TextFieldHeightWithKeyboard : CGFloat = 368
        static let TextFieldHeightWithoutKeyboard : CGFloat = 50
        
        static let TextBarInputButtonWidth : CGFloat = 60
        static let TextBarInputButtonHeight : CGFloat = 30
        
        static let TextBarInputLeftStackViewWidth : CGFloat = 80
        static let TextBarInputBorderWidth : CGFloat = 0.2
    }
    
    
    // MARK: - Instance variables
    private lazy var networkManager : ChatNetworkManager = {
       let nm = ChatNetworkManager(myPhoneNumber: myPhoneNumber!, toPhoneNumber: receiverPhoneNumber!)
        nm.delegate = self
        return nm
    }()
    
    //Variable to determine whether or not media is being sent, if so, we disable the button in order to prevent the user from sending media again until the current download is finished.
    private var mediaBeingSent = false {
        didSet {
            if mediaBeingSent {
                self.messageInputBar.leftStackView.isUserInteractionEnabled = false
            } else {
                self.messageInputBar.leftStackView.isUserInteractionEnabled = true
            }
        }
    }
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        //Assign delegate functions to use MessageKit
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        setupInputBar()

    }
    
    // MARK: - Input Bar setup
    private func setupInputBar() {
        //messageInputBar.inputTextView.tintColor =
        
        //Setup camera button
        let cameraItem = InputBarButtonItem(type: .custom)
        cameraItem.image = UIImage(named: "Camera")
        cameraItem.addTarget(self, action: #selector(cameraPressed), for: .primaryActionTriggered)
        cameraItem.setSize(CGSize(width: Constants.TextBarInputButtonWidth, height: Constants.TextBarInputButtonHeight), animated: false)
        
        //Setup microphone button
        let micrphoneItem = InputBarButtonItem(type: .custom)
        micrphoneItem.image = UIImage(named: "Microphone")
        micrphoneItem.addTarget(self, action: #selector(microphonePressed), for: .primaryActionTriggered)
        micrphoneItem.setSize(CGSize(width: Constants.TextBarInputButtonWidth, height: Constants.TextBarInputButtonHeight), animated: false)
        
        //Setup message input bar label appearance
        messageInputBar.inputTextView.backgroundColor = UIColor.white
        messageInputBar.inputTextView.roundLabelEdge()
        messageInputBar.inputTextView.layer.borderColor = UIColor.black.cgColor
        messageInputBar.inputTextView.layer.borderWidth = Constants.TextBarInputBorderWidth
        
    
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: Constants.TextBarInputLeftStackViewWidth, animated: false)
        messageInputBar.setStackViewItems([cameraItem, micrphoneItem], forStack: .left, animated: false)
        
        
    }
    
    // MARK: - Navigation
    @IBAction func goBackToSelection(_ sender: Any) {
        performSegue(withIdentifier: Storyboard.GoBackToChatSelectionSegue, sender: nil)
    }
    
    // MARK: - Image Selection
    @objc func cameraPressed() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - Audio Recording
    @objc func microphonePressed() {
        print("microphone pressed")
    }
}

extension ChatViewController : MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //Send the text message after send button is pressed through the network manager
        networkManager.sendTextMessage(message: text)
        
        //Clear the input bar again
        inputBar.inputTextView.text = ""
    }
}

extension ChatViewController : MessagesDataSource {
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return networkManager.currentMessages[indexPath.section]
    }
    
    func currentSender() -> Sender {
        return Sender(id: myPhoneNumber!, displayName: networkManager.displayName)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return networkManager.currentMessages.count
    }
    
    
}



extension ChatViewController : MessagesDisplayDelegate, MessagesLayoutDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.image = UIImage(named: "DefaultProfileImage")
        avatarView.backgroundColor = UIColor.clear
    }
}

extension ChatViewController : ChatNetworkManagerDelegate {
    
    func displayTitleWith(name: String) {
        self.navigationItem.title = name
    }
    
    func messagesUpdated() {
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }
    
    func imageDownloadComplete() {
        mediaBeingSent = false 
    }

}

extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
     
        if let image = info[.originalImage] as? UIImage {
            networkManager.sendImageMessage(image: image)
        }
        
        mediaBeingSent = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
