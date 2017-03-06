//
//  SettingsViewController.swift
//  minicloudmonitor
//
//  Created by Marc Plassmeier on 5/3/17.
//  Copyright © 2017 Marc Plassmeier. All rights reserved.
//

import UIKit
import AWSIoT


class SettingsViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var regionTextField: UITextField!
    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var policyTextField: UITextField!
    @IBOutlet weak var cognitoTextField: UITextField!
    
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var stepper: UIStepper!
    
    var changesMade: Bool = false
    
    var logger = Logger.sharedInstance


    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard

        regionTextField.delegate = self
        stepper.stepValue = 1.0
        stepper.minimumValue = 0.0
        //stepper.maximumValue = Double(AWSRegionType.count-1)
        stepper.maximumValue = Double(awsRegions.count-1)
        stepper.value = Double(defaults.integer(forKey: "awsRegion"))
        //regionTextField.text = AWSRegionType(rawValue: Int(stepper.value))!.description
        regionTextField.text = awsRegions[AWSRegionType(rawValue: Int(stepper.value))!]
        
        topicTextField.delegate = self
        topicTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        topicTextField.text = defaults.string(forKey: "iotTopicName") ?? ""
        
        cognitoTextField.delegate = self
        cognitoTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        cognitoTextField.text = defaults.string(forKey: "cognitoIdentityPoolId") ?? ""
        
        policyTextField.delegate = self
        policyTextField.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        policyTextField.text = defaults.string(forKey: "policyName") ?? ""
        
        logTextView.resignFirstResponder()
        logTextView.text = logger.log

        NotificationCenter.default.addObserver(self, selector: #selector(updateLogTextView), name: NSNotification.Name(rawValue: logger.loggerNotificationKey), object: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    func textFieldDidChange(textField: UITextField) {
        changesMade = true
        print("changes made")
    }
    
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        if (changesMade) {
            storeSettings()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func selectRegion(_ sender: UIStepper) {
        //regionTextField.text = AWSRegionType(rawValue: Int(stepper.value))!.description
        regionTextField.text = awsRegions[AWSRegionType(rawValue: Int(stepper.value))!]
        changesMade = true
    }
    
    func updateLogTextView() {
        logTextView.text = logger.log
    }
    
    func storeSettings() {
        let defaults = UserDefaults.standard
        
        defaults.set(Int(stepper.value), forKey: "awsRegion")
        defaults.set(topicTextField.text, forKey: "iotTopicName")
        defaults.set(policyTextField.text, forKey: "policyName")
        defaults.set(cognitoTextField.text, forKey: "cognitoIdentityPoolId")
        
        defaults.set(!(regionTextField.text!.isEmpty || topicTextField.text!.isEmpty || policyTextField.text!.isEmpty || cognitoTextField.text!.isEmpty), forKey: "settingsComplete")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
