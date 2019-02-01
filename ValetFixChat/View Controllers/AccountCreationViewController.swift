//
//  AccountCreationViewController.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 1/30/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import UIKit
import AccountKit

enum TextFieldType {
    case FirstNameLabel
    case LastNameLabel
}

let textFieldTags = [0 : TextFieldType.FirstNameLabel, 1 : TextFieldType.LastNameLabel]

class AccountCreationViewController: UIViewController {
    
    // MARK: - Storyboard
    struct Storyboard {
        static let MainScreenUnwindSegue = "MainScreen Unwind Segue"
    }
  
    // MARK: - Outlets
    @IBOutlet weak var firstNameLabel: UITextField! {
        didSet {
            firstNameLabel.roundLabelEdge()
            firstNameLabel.delegate = self
        }
    }
    @IBOutlet weak var lastNameLabel: UITextField! {
        didSet {
            lastNameLabel.roundLabelEdge()
            lastNameLabel.delegate = self
        }
    }
    @IBOutlet weak var continueButton: UIButton! {
        didSet {
            continueButton.roundButtonEdge()
        }
    }
    @IBOutlet weak var firstNameErrorLabel: UILabel! {
        didSet {
            firstNameErrorLabel.roundLabelEdge()
        }
    }
    
    @IBOutlet weak var lastNameErrorLabel: UILabel! {
        didSet {
            lastNameErrorLabel.roundLabelEdge()
        }
    }
    // MARK: - Constraints
    @IBOutlet weak var continueButtonDistanceToBottom: NSLayoutConstraint!
    @IBOutlet weak var nameInputDistanceToBottom: NSLayoutConstraint!
    
    // MARK: - Instance Variables
    
    var newUser : UserDetails?
    
    private var firstNameErrorLabelIsHidden = true {
        didSet {
            if firstNameErrorLabelIsHidden {
                firstNameErrorLabel.hideOver(duration: AnimationConstants.AnimationDurationForErrorTextDissapearance)
            } else {
                firstNameErrorLabel.showOver(duration: AnimationConstants.AnimationDurationForErrorTextAppearance)
            }
        }
    }
    
    private var lastNameErrorLabelIsHidden = true {
        didSet {
            if lastNameErrorLabelIsHidden {
                 lastNameErrorLabel.hideOver(duration: AnimationConstants.AnimationDurationForErrorTextDissapearance)
            } else {
                lastNameErrorLabel.showOver(duration: AnimationConstants.AnimationDurationForErrorTextAppearance)
            }
        }
    }
    
    private lazy var accountKit : AKFAccountKit = {
        let ak = AKFAccountKit(responseType: .accessToken)
        return ak
    }()
    
    private lazy var phoneNumberVerificationVC : AKFViewController & UIViewController = {
       let inputState = UUID().uuidString
        let vc = accountKit.viewControllerForPhoneLogin(with: nil, state: inputState)
        vc.delegate = self
        vc.uiManager = AKFSkinManager(skinType: .contemporary, primaryColor: UIColor.blue)
        return vc
    }()
    
    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboards)))
    }
    
    // MARK: - Outlet functions
    @IBAction func cancelAccountCreation(_ sender: Any) {
        performSegue(withIdentifier: Storyboard.MainScreenUnwindSegue, sender: nil)
    }
    @IBAction func phoneNumberVerification(_ sender: Any) {
        guard validateInput() else {
            return
        }
        
        present(phoneNumberVerificationVC as UIViewController, animated: true, completion: nil)
    }
    
    // MARK: - Input Validation
    private func validateInput() -> Bool {
        
        if firstNameLabel.text?.count == 0  {
            firstNameErrorLabelIsHidden = false
            return false
        }
        
        if lastNameLabel.text?.count == 0 {
            lastNameErrorLabelIsHidden = false
            return false
        }
        
        return true
    }
    
    // MARK: - Gesture Functions
    @objc func dismissKeyboards() {
        firstNameLabel.resignFirstResponder()
        lastNameLabel.resignFirstResponder()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AccountCreationViewController : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let currentTag = textFieldTags[textField.tag] else {
            return
        }
        
        switch currentTag {
        case .FirstNameLabel :
            firstNameErrorLabelIsHidden = true
        case .LastNameLabel :
            lastNameErrorLabelIsHidden = true
        }
        
        animateKeyboardAppearance()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

        animateForKeyboardDissapearance()
    }
}

// MARK: - AFKViewController Delegate
extension AccountCreationViewController : AKFViewControllerDelegate {
    
    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
        
        accountKit.requestAccount { [unowned self] (account, error) in
            
            guard let userPhoneNumber = account?.phoneNumber?.phoneNumber else {
                return
            }
            
            let fullUserName = "\(self.firstNameLabel.text!) \(self.lastNameLabel.text!)"
            
            self.newUser = UserDetails(userName : fullUserName, userPhoneNumber : userPhoneNumber)
            self.performSegue(withIdentifier: Storyboard.MainScreenUnwindSegue, sender: self)
        }
    }
}

// MARK: - Animation Constants
struct AnimationConstants {
    static let AnimationDurationForTextFieldAppearance : TimeInterval = 0.25
    static let AnimationDurationForTextFieldDissapearance :
        TimeInterval = 0.25
    
    static let AnimationDurationForErrorTextAppearance : TimeInterval = 0.25
    static let AnimationDurationForErrorTextDissapearance : TimeInterval = 0.25
    
    static let TextFieldConstraintOffset : CGFloat = 150
    static let ContinueButtonConstraintOffset : CGFloat = 280
}



// MARK: - Animation Functions
extension AccountCreationViewController {
    private func animateKeyboardAppearance() {
        UIView.animate(withDuration: AnimationConstants.AnimationDurationForTextFieldAppearance, delay: 0, options: .curveLinear, animations: {
            
            self.continueButtonDistanceToBottom.constant += AnimationConstants.ContinueButtonConstraintOffset
            self.nameInputDistanceToBottom.constant += AnimationConstants.TextFieldConstraintOffset
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func animateForKeyboardDissapearance() {
        UIView.animate(withDuration: AnimationConstants.AnimationDurationForTextFieldDissapearance, delay: 0, options: .curveLinear, animations: {
            
            self.continueButtonDistanceToBottom.constant -= AnimationConstants.ContinueButtonConstraintOffset
            self.nameInputDistanceToBottom.constant -= AnimationConstants.TextFieldConstraintOffset
            self.view.layoutIfNeeded()

        }, completion: nil)    }
}
