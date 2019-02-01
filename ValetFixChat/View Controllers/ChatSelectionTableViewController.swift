//
//  ChatSelectionTableViewController.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import UIKit

class ChatSelectionTableViewController: UITableViewController {
    
    // MARK: - Storyboard
    struct Storyboard {
        static let ChatSegue = "Chat Segue"
        static let ConversationCellIdentifier = "Conversation Cell"
        
        static let GoBackToChatSelectionSegue = "Go Back To Chat Selection"
    }
    
    struct Constants {    
        static let NewConversationErrorAlertTitle = "There was a problem"
        static let NewConversationErrorAlertBody = "Chat could not be established with the given number."
        
        static let NewConversationAlertTitle = "Find a person to chat with"
        static let NewConversationAlertBody = "Enter the number of the person you wish to chat with"
        
        static let NewConversationAlertStartChatButtonText = "Start"
        static let NewConversationAlertCancelButtonText = "Cancel"
        
        static let PhoneNumberLength = 6
        static let TableViewCellHeight : CGFloat = 80
    }
    
    // MARK: - Instance Variables
    var userPhoneNumber : String?
    
    //Receiver Phone number, we will start a new chat to this number
    private var toPhoneNumber : String?
    
    //The name of the user we are chatting with to display in chat
    private var toUserName : String?
    
    private var startChatAction : UIAlertAction?
    
    private lazy var chatSelectionNM : ChatSelectionNetworkManager = {
       let nm = ChatSelectionNetworkManager(delegate: self, userPhoneNumber: userPhoneNumber!)
        return nm
    }()
    
    
    // MARK: - VC Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Chat Message Composition functions
    @IBAction func composeNewMessage(_ sender: Any) {
        let newConversationAlertVC = createNewChatVC()
        present(newConversationAlertVC, animated: true, completion: nil)
    }
    
    
    // MARK: - New Conversation Alert Functions
    private func createNewChatVC() -> UIAlertController {
        
        let newConversationAlertVC = UIAlertController(title: Constants.NewConversationAlertTitle, message: Constants.NewConversationAlertBody, preferredStyle: .alert)
        newConversationAlertVC.addTextField { (textField) in
            textField.delegate = self
            textField.placeholder = "4441234"
        }
        let cancelAction = UIAlertAction(title: Constants.NewConversationAlertCancelButtonText, style: .cancel, handler: nil)
        
        let continueAction = UIAlertAction(title: Constants.NewConversationAlertStartChatButtonText, style: .default) { [unowned self] (action) in
            
            
            if let toPhoneNumber = newConversationAlertVC.textFields?.first?.text {
                
                //Check to see if the person you wish to chat with exists on the server
                self.chatSelectionNM.shouldStartConversation(withReceiverPhoneNumber: toPhoneNumber, completionHandler: { (numberExists) in
                    if numberExists {
                        self.toPhoneNumber = toPhoneNumber
                        self.performSegue(withIdentifier: Storyboard.ChatSegue, sender: self)
                    } else {
                        let errorVC = self.createErrorAlert()
                        self.present(errorVC, animated: true, completion: nil)
                    }
                })
            }
        }
        continueAction.isEnabled = false
        startChatAction = continueAction
        newConversationAlertVC.addAction(cancelAction)
        newConversationAlertVC.addAction(continueAction)
        return newConversationAlertVC
        
    }
    
    private func createErrorAlert() -> UIAlertController {
        let errorAlertVC = UIAlertController(title: Constants.NewConversationErrorAlertTitle, message: Constants.NewConversationErrorAlertBody, preferredStyle: .alert)
        errorAlertVC.addAction(UIAlertAction(title: Constants.NewConversationAlertCancelButtonText, style: .cancel, handler: nil))
        return errorAlertVC
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return chatSelectionNM.currentChats.count
    }
    
    // MARK: - Tableview Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let message = chatSelectionNM.currentChats[indexPath.row]
        
        //Check to make sure we arent sending messages to our own number. 
        self.toPhoneNumber = message.receiverID == userPhoneNumber! ? message.senderID : message.receiverID
        performSegue(withIdentifier: Storyboard.ChatSegue, sender: self)

    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.TableViewCellHeight
    }

    // MARK: - TableView Cell Registration
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.ConversationCellIdentifier, for: indexPath) as! ChatSelectionTableViewCell

        let message = chatSelectionNM.currentChats[indexPath.row]
        cell.userPhoneNumber = userPhoneNumber
        
        cell.message = message 

        return cell
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case Storyboard.ChatSegue :
            
            if let chatVC = (segue.destination as? UINavigationController)?.currentviewController() as? ChatViewController {
                
                chatVC.myPhoneNumber = userPhoneNumber
                chatVC.receiverPhoneNumber = toPhoneNumber
            }
        default :
            break
        }
    }
    
    @IBAction func unwindBackToChatSelection(segue : UIStoryboardSegue) {
    
    }
 

}

extension ChatSelectionTableViewController : ChatSelectionViewModelDelegate {
    func conversationsUpdated() {
        self.tableView.reloadData()
    }
}

extension ChatSelectionTableViewController : UITextFieldDelegate {
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, text.count == Constants.PhoneNumberLength {
            startChatAction?.isEnabled = true
        }
        return true
    }
    
}
