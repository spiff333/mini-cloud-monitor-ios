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
    
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var changesMade: Bool = false
    
    var logger = Logger.sharedInstance
    let awsIotClient = AwsIotClient.sharedInstance


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
        logTextView.clipsToBounds = true
        logTextView.layer.cornerRadius = 5.0
        logTextView.text = logger.log

        // Logger notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateLogTextView), name: NSNotification.Name(rawValue: logger.NotificationKey), object: nil)
        
        // AWS IoT Client notifications
        NotificationCenter.default.addObserver(self, selector: #selector(updateConnectButton), name: NSNotification.Name(rawValue: awsIotClient.NotificationKey), object: nil)
        
        updateConnectButton()
    }
    
    func animateTextField(textField: UITextField, up: Bool)
    {
        let movementDistance:CGFloat = -130
        let movementDuration: Double = 0.3
        
        var movement:CGFloat = 0
        if up {
            movement = movementDistance
        } else {
            movement = -movementDistance
        }
        UIView.beginAnimations("animateTextField", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.animateTextField(textField: textField, up:true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.animateTextField(textField: textField, up:false)
    }
    
    func textFieldDidChange(textField: UITextField) {
        changesMade = true
        print("changes made")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    func updateConnectButton() {
        switch(awsIotClient.connectionStatus) {
        case .connecting:
            self.connectButton.setTitle("Connecting", for: .normal)
            activityIndicator.startAnimating()
            connectButton.isEnabled = false
            
        case .connected:
            self.connectButton.setTitle("Disconnect", for: .normal)
            activityIndicator.stopAnimating()
            connectButton.isEnabled = true
            
        default:
            self.connectButton.setTitle("Connect", for: .normal)
            activityIndicator.stopAnimating()
            connectButton.isEnabled = true
        }
    }
    
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        storeSettings()
        if (awsIotClient.connectionStatus != .connected) {
            awsIotClient.connect()
        } else {
            // there is no MQTT notification status for disconnecting
            connectButton.setTitle("Connecting", for: .normal)
            connectButton.isEnabled = false
            activityIndicator.startAnimating()

            awsIotClient.disconnect()
        }
        updateConnectButton()
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
        DispatchQueue.main.async {
            self.logTextView.text = self.logger.log
        }
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
