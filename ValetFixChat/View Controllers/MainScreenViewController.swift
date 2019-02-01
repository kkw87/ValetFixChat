//
//  MainScreenViewController.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/29/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import UIKit
import AccountKit
import SVProgressHUD

class MainScreenViewController: UIViewController {
    
    // MARK: - Constants
    struct Storyboard {
        static let SignUpSegue = "Sign Up Segue"
        static let LoginSegue = "Log In Segue"
        
        static let ChatSegue = "Chat Segue"
        
        static let AccountCreationAlertTitle = "We couldn't make your account"
        static let AccountCreationAlertDefaultButtonTitle = "Continue"
    }
    
    
    // MARK: - Outlets
    @IBOutlet weak var signUpButton: UIButton! {
        didSet {
            signUpButton.roundButtonEdge()
        }
    }
    
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.roundButtonEdge()
            loginButton.layer.borderWidth = 2
            loginButton.layer.borderColor = UIColor.white.cgColor
        }
    }
    
    // MARK: - Instance Variables
    private var accountKit : AKFAccountKit!
    
    private lazy var phoneNumberVerificationVC : AKFViewController & UIViewController = {
        let inputState = UUID().uuidString
        let vc = accountKit.viewControllerForPhoneLogin(with: nil, state: inputState)
        vc.delegate = self
        vc.uiManager = AKFSkinManager(skinType: .contemporary, primaryColor: UIColor.blue)
        return vc
    }()
    
    private let accountManager = AccountManager()
    private var userPhoneNumber : String?
    
    // MARK: - VC lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if accountKit == nil {
            accountKit = AKFAccountKit(responseType: .accessToken)
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if accountKit.currentAccessToken != nil {
            
            //Segue directly to chat
            //Get phone number, log user in
        }
        
    }
    
    // MARK: - Login Functions

    
    @IBAction func login(_ sender: Any) {
        // TODO: - REMOVE AUTO LOGIN
        self.userPhoneNumber = "3478049088"
        
        self.performSegue(withIdentifier: Storyboard.ChatSegue, sender: self)
        //self.present(phoneNumberVerificationVC, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case Storyboard.ChatSegue :
            
            guard let destinationTabVC = segue.destination as? UITabBarController else {
                break
            }
            
            if let chatVC = destinationTabVC.viewControllers?[0] as? ChatSelectionTableViewController {
                chatVC.userPhoneNumber = userPhoneNumber
            }
            
            if let userInformationVC = destinationTabVC.viewControllers?[1] as? UserInformationTableViewController {
                userInformationVC.userPhoneNumber = userPhoneNumber

            }
            break
        default :
            break
        }
        
    }
 
    @IBAction func unwindFromAccountCreation(segue : UIStoryboardSegue) {
        
        guard let accountCreationVC = segue.source as? AccountCreationViewController else {
            return
        }
        
        if let newUser = accountCreationVC.newUser {
            SVProgressHUD.show()

            accountManager.createUserWith(details: newUser) {[unowned self] (error) in

                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
      
                guard error == nil else {
                    
                    let errorAlertVC = self.createErrorAlertVC(withMessage: error!.description)
                    
                    //Wait until view controller presentations are finished before displaying error to user
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self.present(errorAlertVC, animated: true, completion: nil)
                    })

                    return
                }
                
                self.userPhoneNumber = newUser.userPhoneNumber
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.performSegue(withIdentifier: Storyboard.ChatSegue, sender: self)
                })
            }
        }
    }
    
    // MARK: - Error Display Helper functions
    private func createErrorAlertVC(withMessage : String) -> UIAlertController {
        let errorAlertVC = UIAlertController(title: Storyboard.AccountCreationAlertTitle, message: withMessage, preferredStyle: .alert)
        let completionAction = UIAlertAction(title: Storyboard.AccountCreationAlertDefaultButtonTitle, style: .cancel, handler: nil)
        errorAlertVC.addAction(completionAction)
        return errorAlertVC
    }

}

extension MainScreenViewController : AKFViewControllerDelegate {
    
    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {

        accountKit.requestAccount { [unowned self] (account, error) in
            guard let phoneNumber = account?.phoneNumber?.phoneNumber else {
                return
            }
            
            SVProgressHUD.show()
            
            self.accountManager.loginUserWith(phoneNumber: phoneNumber, completionHandler: { (error) in
                
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
                
                guard error == nil else {
                    let errorAlertVC = self.createErrorAlertVC(withMessage: error!.description)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self.present(errorAlertVC, animated: true, completion: nil)
                    })
                    
                    return
                }
                
                self.userPhoneNumber = phoneNumber
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.performSegue(withIdentifier: Storyboard.ChatSegue, sender: self)
                })
            })
            
        }
    }
}
