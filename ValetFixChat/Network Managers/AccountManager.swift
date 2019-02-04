//
//  AccountManager.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import Firebase

enum AccountCreationError : Error, CustomStringConvertible {
    
    case PhoneNumberExists
    case NetworkError
    
    var description: String {
        switch self {
        case .PhoneNumberExists :
            return "There is already an account associated with the phone number"
        case .NetworkError :
            return "There was an error creating your account, please try again"
        }
    }
}

enum AccountLoginError : Error, CustomStringConvertible {
    
    case PhoneNumberDoesNotExist
    case NetworkError
    
    var description: String {
        switch self {
        case .PhoneNumberDoesNotExist :
            return "There does not seem to be an account associated with this phone number"
        case .NetworkError :
            return "There was an error creating your account, please try again"
        }
    }
}

struct AccountManager {
    
    
    //Function used to create a new user on the firebase backend, if a user exists, it returns an error, else the user is created
    func createUserWith(details : UserDetails, completionHandler : @escaping (AccountCreationError?) -> Void) {
        let userPhoneNumber = details.userPhoneNumber
        
        FirebaseDatabase.UserDatabaseReference.observeSingleEvent(of: .value) { (snapshot) in
            
            //Check if the phone number already exists
            if snapshot.hasChild(userPhoneNumber) {
                completionHandler(AccountCreationError.PhoneNumberExists)
            } else {
   FirebaseDatabase.UserDatabaseReference.child(userPhoneNumber).child(UserKeys.UserNameKey).setValue(details.userName)
                FirebaseDatabase.UserDatabaseReference.child(userPhoneNumber).child(UserKeys.UserPhoneNumberKey).setValue(userPhoneNumber)
                
                completionHandler(nil)
            }
            
        }
        
    }
    
    func loginUserWith(phoneNumber : String, completionHandler : @escaping (AccountLoginError?) -> Void) {
        
        FirebaseDatabase.UserDatabaseReference.observeSingleEvent(of: .value) { (snapshot) in
            
            
            guard snapshot.hasChild(phoneNumber) else {
                completionHandler(AccountLoginError.PhoneNumberDoesNotExist)
                return
            }

            //If user does exist, return success
            completionHandler(nil)
            
        }
        
    }
    
}
