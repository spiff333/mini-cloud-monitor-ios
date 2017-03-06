//
//  AwsIotClient.swift
//  minicloudmonitor
//
//  Created by Marc Plassmeier on 4/3/17.
//  Copyright © 2017 Marc Plassmeier. All rights reserved.
//

import Foundation
import AWSIoT

class AwsIotClient {
    
    var awsRegion: AWSRegionType!
    var iotTopicName: String!
    var cognitoIdentityPoolId: String!
    var policyName: String!
    
    var connected = false
    
    var iotDataManager: AWSIoTDataManager!
    var iotData: AWSIoTData!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    
    var logger = Logger.sharedInstance

    
    func connect() {
        let defaults = UserDefaults.standard
        
        // check that all parameters are set
        if (!defaults.bool(forKey: "settingsComplete")) {
            return
        }

        awsRegion = AWSRegionType(rawValue: defaults.integer(forKey: "awsRegion"))
        iotTopicName = defaults.string(forKey: "iotTopicName")
        cognitoIdentityPoolId = defaults.string(forKey: "cognitoIdentityPoolId")
        policyName = defaults.string(forKey: "policyName")

        // setup aws credential provider, configuration and managers
        let credentialProvider = AWSCognitoCredentialsProvider( regionType: awsRegion, identityPoolId: cognitoIdentityPoolId )
        let configuration = AWSServiceConfiguration( region: awsRegion, credentialsProvider: credentialProvider )
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
        
        iotDataManager = AWSIoTDataManager.default()
        iotData = AWSIoTData.default()

        // try to connect if certificateId is set in UserDefaults
        let certificateId = defaults.string( forKey: "certificateId" )

        if (certificateId != nil) {
            connectIoT()
        } else {
            createCertificateAndConnect()
        }
    }
    
    
    func connectIoT() {

        func mqttEventCallback( _ status: AWSIoTMQTTStatus )
        {
            DispatchQueue.main.async {
                self.logger.print("connection status = \(status.rawValue)\n")
                switch(status)
                {
                case .connecting:
                    self.logger.print("Connecting...")
                    
                case .connected:
                    self.connected = true
                    
                    let uuid = UUID().uuidString;
                    let defaults = UserDefaults.standard
                    let certificateId = defaults.string( forKey: "certificateId")
                    
                    self.logger.print("Connected\nUsing certificate:\n\(certificateId!)\n\n\nClient ID:\n\(uuid)")
                    
                case .disconnected:
                    self.connected = false
                    self.logger.print("Disconnected")
                    
                case .connectionRefused:
                    self.connected = false
                    self.logger.print("Connection Refused")
                    
                case .connectionError:
                    self.connected = false
                    self.logger.print("Connection Error")
                    
                case .protocolError:
                    self.connected = false
                    self.logger.print("Protocol Error")

                default:
                    self.logger.print("Unknown State: \(status.rawValue)")
                    
                }
                NotificationCenter.default.post( name: Notification.Name(rawValue: "connectionStatusChanged"), object: self )
            }
        }

        let certificateId = UserDefaults.standard.string( forKey: "certificateId" )

        iotDataManager.connect( withClientId: UUID().uuidString, cleanSession:true, certificateId:certificateId!, statusCallback: mqttEventCallback)
    }
    
    

    func disconnect() {
        self.logger.print("Disconnecting...\n")

        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.iotDataManager.disconnect();
            self.connected = false
        }
    }
    
    

    func isConnected() -> Bool {
        return connected
    }


    
    func publishToTopic(message: String) {
        if (connected) {
            iotDataManager.publishString(message, onTopic:iotTopicName, qoS:.messageDeliveryAttemptedAtMostOnce)
            logger.print("Published to topic: \(message)")
        }
    }
    


    //
    // Create certificate and store the certificateID in NSUserDefaults
    //
    func createCertificateAndConnect() {
        self.logger.print("Creating new keys and certificate...\n")

        let csrDictionary = [ "commonName":CertificateSigningRequestCommonName, "countryName":CertificateSigningRequestCountryName, "organizationName":CertificateSigningRequestOrganizationName, "organizationalUnitName":CertificateSigningRequestOrganizationalUnitName ]
        
        self.iotManager.createKeysAndCertificate(fromCsr: csrDictionary, callback: {  (response ) -> Void in
            if (response != nil)
            {
                let defaults = UserDefaults.standard

                defaults.set(response?.certificateId, forKey:"certificateId")
                defaults.set(response?.certificateArn, forKey:"certificateArn")

                self.logger.print("response: [\(response)]\n")

                
                let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
                attachPrincipalPolicyRequest?.policyName = self.policyName
                attachPrincipalPolicyRequest?.principal = response?.certificateArn
                //
                // Attach the policy to the certificate
                //
                self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest!).continueWith (block: { (task) -> AnyObject? in
                    if let error = task.error {
                        self.logger.print("failed: [\(error)]\n")
                    }
                    self.logger.print("result: [\(task.result)]\n")

                    //
                    // Connect to the AWS IoT platform
                    //
                    if (task.error == nil)
                    {
                        DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                            self.connectIoT()
                        })
                    }
                    return nil
                })
            }
            else
            {
                self.logger.print("Unable to create keys and/or certificate, check settings\n")
            }
        } )

    }
    
}
