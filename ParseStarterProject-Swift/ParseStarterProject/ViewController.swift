/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import UIKit
import Parse

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var `switch`: UISwitch!
    
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var riderLabel: UILabel!
    
    
    @IBOutlet weak var toggleSignUpButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    var signUpState = true
    
    @IBAction func signUp(sender: AnyObject) {
        
        if username.text == "" || password.text == "" {
            
            displayAlert("Missing Field(s)", message: "Both username and password are required")
        } else {
    
            if signUpState {
            
                let user = PFUser()
                user.username = username.text
                user.password = password.text

                user["isDriver"] = `switch`.on
                
                user.signUpInBackgroundWithBlock({ (success, error) in
                    
                    if let error = error {
                        if let errorString = error.userInfo["error"] as? String {
                            
                            self.displayAlert("Sign Up Failed!", message: errorString)
                        }
                        
                    } else {
                        
                        if self.`switch`.on == true {
                            
                            self.performSegueWithIdentifier("logInDriver", sender: self)
                        } else {
                            
                            self.performSegueWithIdentifier("logInRider", sender: self)
                        }
                    }
                })
                
            } else {
            
                PFUser.logInWithUsernameInBackground(username.text!, password: password.text!, block: { (user, error) in
                    
                    if let user = user {
                        
                        if user["isDriver"]! as! Bool == true {
                            
                            self.performSegueWithIdentifier("logInDriver", sender: self)
                        } else {
                            
                            self.performSegueWithIdentifier("logInRider", sender: self)
                        }
                        
                    } else {
                        
                        if let errorString = error?.userInfo["error"] as? String {
                            
                            self.displayAlert("Log In Failed!", message: errorString)
                        }
                        
                    }
                })
            
            }

        }
    }
    
    @IBAction func toggleSignUp(sender: AnyObject) {
        
        if signUpState {
            
            signUpButton.setTitle("Log In", forState: .Normal)
            toggleSignUpButton.setTitle("Sign Up", forState: .Normal)
            signUpState = false
            riderLabel.alpha = 0
            driverLabel.alpha = 0
            `switch`.alpha = 0
            
        } else {
            
            signUpButton.setTitle("Sign Up", forState: .Normal)
            toggleSignUpButton.setTitle("Log In", forState: .Normal)
            signUpState = true
            riderLabel.alpha = 1
            driverLabel.alpha = 1
            `switch`.alpha = 1
            
        }
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //PFUser.logOut()
        
        self.username.delegate = self
        self.password.delegate = self
       
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.DismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if PFUser.currentUser()?.objectId != nil {
            
            if PFUser.currentUser()?["isDriver"]! as! Bool == true {
                
                self.performSegueWithIdentifier("logInDriver", sender: self)
            } else {
                
                self.performSegueWithIdentifier("logInRider", sender: self)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func DismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    func displayAlert(title: String, message: String) {
        
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: title , message: message , preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction((UIAlertAction(title: "OK", style: .Default, handler: { (action) in
                self.dismissViewControllerAnimated(true, completion: nil)
            })))
            
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            // Fallback on earlier versions
        }
    }
    

    
}
