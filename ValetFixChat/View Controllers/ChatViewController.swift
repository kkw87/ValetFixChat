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
import AMPopTip

class ChatViewController : MessagesViewController {
    
    // MARK: - User phone numbers
    
    //Current user's phone number
    var myPhoneNumber : String?
    
    //Phone number to send messages to
    var receiverPhoneNumber : String?
    
    // MARK: - Storyboard
    struct Storyboard {
        static let ChatCellIdentifier = "Chat Message Cell"
        static let CellNibFile = "MessageCell"
        static let GoBackToChatSelectionSegue = "Go Back To Chat Selection"
    }
    
    // MARK: - Constants
    struct Constants {
        //We use these constants to size and create the left bar button items in the stack view(the camera and micrphone)
        static let TextBarInputButtonWidth : CGFloat = 60
        static let TextBarInputButtonHeight : CGFloat = 30
        
        //We use these constants to size the stack view in the message input bar where the camera and micrphone bar button items go
        static let TextBarInputLeftStackViewWidth : CGFloat = 80
        static let TextBarInputBorderWidth : CGFloat = 0.2
    }
    
    
    // MARK: - Instance variables
    
    //AVPlayer to play user audio clips
    private var avPlayer : AVPlayer!
    
    //We use the ChatNetworkManager to send messages to firebase, convert the messages to the proper format, and used to store all the message files
    private lazy var chatNetworkManager : ChatNetworkManager = {
        let nm = ChatNetworkManager(myPhoneNumber: myPhoneNumber!, toPhoneNumber: receiverPhoneNumber!)
        nm.delegate = self
        return nm
    }()
    
    // The popup view that will show up after the user clicks on the microphone icon
    private lazy var audioRecorderPopUp : PopTip = {
        
        //Popup view configuration
        let popUp = PopTip()
        popUp.bubbleColor = UIColor.popUpBackgroundColor
        popUp.borderWidth = 0
        popUp.shouldDismissOnTap = false
        popUp.shouldDismissOnTapOutside = true
        
        popUp.dismissHandler = { [unowned self] _ in
            self.mediaBeingSent = false
        }
        
        return popUp
    }()
    
    //The audio recorder view that contains the red recording button, this will be encapsulated in the audioRecorderPopUp view
    private lazy var audioRecorderView : AudioRecordingView = {
        let aV = AudioRecordingView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        aV.delegate = self
        return aV
    }()
    
    //The audio recorder object that works in conjunction with the audioRecorderView. This will record audio once the red record button is pressed and if successful, will return the URL to the audio message
    private lazy var audioRecorder : AudioRecorder = {
        let aR = AudioRecorder()
        aR.delegate = self
        return aR
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
        //Assign delegate functions to use MessageKit and configure the messageCollectionView
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        setupInputBar()
        
    }

    
    // MARK: - Input Bar setup
    private func setupInputBar() {
        
        //Setup camera button
        let cameraItem = InputBarButtonItem(type: .custom)
        cameraItem.image = UIImage(named: "Camera")
        cameraItem.addTarget(self, action: #selector(cameraPressed), for: .primaryActionTriggered)
        cameraItem.setSize(CGSize(width: Constants.TextBarInputButtonWidth, height: Constants.TextBarInputButtonHeight), animated: false)
        
        //Setup microphone button
        let micrphoneItem = InputBarButtonItem(type: .custom)
        micrphoneItem.image = UIImage(named: "Microphone")
        micrphoneItem.addTarget(self, action: #selector(microphonePressed(sender:)), for: .primaryActionTriggered)
        micrphoneItem.setSize(CGSize(width: Constants.TextBarInputButtonWidth, height: Constants.TextBarInputButtonHeight), animated: false)
        
        //Setup message input bar label appearance
        messageInputBar.inputTextView.backgroundColor = UIColor.white
        messageInputBar.inputTextView.roundLabelEdge()
        messageInputBar.inputTextView.layer.borderColor = UIColor.black.cgColor
        messageInputBar.inputTextView.layer.borderWidth = Constants.TextBarInputBorderWidth
        
        //Setup the left stack view in which micrphone and camera buttons will be placed
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: Constants.TextBarInputLeftStackViewWidth, animated: false)
        messageInputBar.setStackViewItems([cameraItem, micrphoneItem], forStack: .left, animated: false)
    }
    
    // MARK: - Navigation
    //Allow the user to go back to chat selection, we unwind back since we are not in the same navigation controller
    @IBAction func goBackToSelection(_ sender: Any) {
        performSegue(withIdentifier: Storyboard.GoBackToChatSelectionSegue, sender: nil)
    }
    
    // MARK: - Image Selection
    @objc func cameraPressed() {
        
        //Present the image picker controller
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - Audio Recording
    @objc func microphonePressed(sender : InputBarButtonItem) {
        
        //We set this to true in order to stop the user from sending more messages or photos until the current photo or audio message is successfully sent
        mediaBeingSent = true
        
        //Show the audiorecorderpop up view that encapsulates the recorder view
        audioRecorderPopUp.show(customView: audioRecorderView, direction: .none, in:  messageInputBar, from: messageInputBar.leftStackView.convert(sender.frame, to: messageInputBar))
        
        
        audioRecorderPopUp.dismissHandler = { [unowned self] _ in
            self.mediaBeingSent = false
        }
    }
    
    // MARK: - Audio Playback
    private func playAudioFrom(url : URL) {
        avPlayer = AVPlayer(url: url)
        avPlayer.volume = 1.0
        avPlayer.play()
    }
    
    // MARK: - Gesture Functions
    @objc func messageInputBarTapped() {
        audioRecorderPopUp.hide()
    }
    
}

// MARK: - MessageCell Delegate
extension ChatViewController : MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        
        guard let cellIndexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let selectedMessage = chatNetworkManager.currentMessages[cellIndexPath.section]
        switch selectedMessage.kind {
        case .video(let mediaItem) :
            playAudioFrom(url: mediaItem.url!)
        default : break
        }
        
    }
}


// MARK: - Input bar delegate 
extension ChatViewController : MessageInputBarDelegate {
    
    //Once the user finishes typing a message and hit sends, we send the message through the chatnetworkmanager and clear the input.
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //Send the text message after send button is pressed through the network manager
        chatNetworkManager.sendTextMessage(message: text)
        
        //Clear the input bar again
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
    }
}

// MARK: - Message Datasource
extension ChatViewController : MessagesDataSource {
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return chatNetworkManager.currentMessages[indexPath.section]
    }
    
    func currentSender() -> Sender {
        return Sender(id: myPhoneNumber!, displayName: chatNetworkManager.displayName)
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return chatNetworkManager.currentMessages.count
    }
    
    
}



// MARK: - MessageDisplay Delegate, MessagesLayout Delegate
extension ChatViewController : MessagesDisplayDelegate, MessagesLayoutDelegate {
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        //Since we are not supporting user profile images, we use a blank default image for the avatar
        avatarView.image = UIImage(named: "DefaultProfileImage")
        avatarView.backgroundColor = UIColor.clear
    }
    
}

// MARK: - ChatNetworkManager Delegate
extension ChatViewController : ChatNetworkManagerDelegate {
    
    //We set the title for the navigation item to the user we are chatting with.
    func displayTitleWith(name: String) {
        self.navigationItem.title = name
    }
    
    //The message collection has changed, we tell the messagesCollectionView to update itself 
    func messagesUpdated() {
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }
    
    func imageDownloadComplete() {
        mediaBeingSent = false 
    }
    
}

// MARK: - Image Picker Controller Delegate
extension ChatViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            chatNetworkManager.sendImageMessage(image: image)
        }
        
        //Set the image flag to true while the image is uploaded to firebase
        mediaBeingSent = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - AudioRecordingView Delegate
extension ChatViewController : AudioRecordingViewDelegate {
    func recordButtonPressed() {
        audioRecorder.startRecording()
    }
    
    //The recording was stopped
    func recordButtonStopped()
    {   //Hide the recording popup since the recording was stopped
        audioRecorderPopUp.hide()
        
        //Check if we have successfully recording an audio file
        if let audioFileURL = audioRecorder.recordingFinished() {
            //Send the audio file with the URL
            chatNetworkManager.sendAudioMessage(audioURL: audioFileURL)
            
        }
        
    }
}

// MARK: - AudioRecorder Delegate
extension ChatViewController : AudioRecorderDelegate {
    //We were unable to successfully finish recording, tell the audrioRecorderView to stop the animations
    func unableToRecordMessage() {
        audioRecorderView.stopRecording()
    }
}
