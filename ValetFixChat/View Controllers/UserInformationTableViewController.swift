//
//  UserInformationTableViewController.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import UIKit
import Firebase

class UserInformationTableViewController: UITableViewController {

    // MARK: - Instance Variables
    var userPhoneNumber : String?
    
    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var phoneNumberLabel: UILabel!
    
    // MARK: - VC Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Check if we have the users phone number from log in, if we do, we fetch their information from firebase
        if userPhoneNumber != nil {
            pullUserInformation(fromNumber: userPhoneNumber!)
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK: - Network functions
    
    //Fetch user name and from number from firebase 
    private func pullUserInformation(fromNumber : String) {
        FirebaseDatabase.UserDatabaseReference.child(fromNumber).observeSingleEvent(of: .value) {[weak self] (data) in
            
            guard let dataDictionary = data.value as? [String : Any] else {
                return
            }
            
            if let userName = dataDictionary[UserKeys.UserNameKey] as? String {
                DispatchQueue.main.async {
                    self?.nameLabel.text = userName
                }
            }
            
            if let phoneNumber = dataDictionary[UserKeys.UserPhoneNumberKey] as? String {
                DispatchQueue.main.async {
                    self?.phoneNumberLabel.text = phoneNumber
                }
            }
            
        }
    }

    // MARK: - Table view data source


    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
