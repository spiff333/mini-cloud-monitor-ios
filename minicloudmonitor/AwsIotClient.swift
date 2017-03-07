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
    
    var connectionStatus: AWSIoTMQTTStatus = .disconnected
    
    var iotDataManager: AWSIoTDataManager!
    var iotData: AWSIoTData!
    var iotManager: AWSIoTManager!
    var iot: AWSIoT!
    
    let NotificationKey = "net.plassmeier.mqtt-notification"

    var logger = Logger.sharedInstance

    
    static let sharedInstance = AwsIotClient()

    func connect() {
        let defaults = UserDefaults.standard
        
        // check that all parameters are set
        if (!defaults.bool(forKey: "settingsComplete")) {
            self.logger.print("⚠️ AWS IoT Connection settings not complete!")
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
            self.connectionStatus = status

            switch(status) {
            case .connecting:
                self.logger.print("🔌 Service connecting...")
                
            case .connected:
                let uuid = UUID().uuidString;
                let defaults = UserDefaults.standard
                let certificateId = defaults.string( forKey: "certificateId")
                
                self.logger.print("🔌 Connected\nCertificate:\(certificateId!)\nClient ID:\n\(uuid)")
                
            case .disconnected:
                self.logger.print("🔌 Service disconnected.")
                
            case .connectionRefused:
                self.logger.print("🔌 Connection Refused.")
                
            case .connectionError:
                self.logger.print("🔌 Connection Error.")
                
            case .protocolError:
                self.logger.print("🔌 Protocol Error.")
                
            default:
                self.logger.print("🔌 Unknown State:\n\(status.rawValue)")
                
            }

            NotificationCenter.default.post( name: Notification.Name(rawValue: self.NotificationKey), object: self )
        }

        let certificateId = UserDefaults.standard.string( forKey: "certificateId" )

        iotDataManager.connect( withClientId: UUID().uuidString, cleanSession:true, certificateId:certificateId!, statusCallback: mqttEventCallback)
    }
    
    

    func disconnect() {
        self.logger.print("🔌 Service disconnecting...")
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            self.iotDataManager.disconnect();
        }
    }


    
    func publishToTopic(message: String) {
        if (connectionStatus == .connected) {
            iotDataManager.publishString(message, onTopic:iotTopicName, qoS:.messageDeliveryAttemptedAtMostOnce)
            logger.print("Mqtt -> \(message)")
        }
    }
    


    //
    // Create certificate and store the certificateID in NSUserDefaults
    //
    func createCertificateAndConnect() {
        self.logger.print("\n🔑 Creating Keys & Certificate.")

        let csrDictionary = [ "commonName":CertificateSigningRequestCommonName, "countryName":CertificateSigningRequestCountryName, "organizationName":CertificateSigningRequestOrganizationName, "organizationalUnitName":CertificateSigningRequestOrganizationalUnitName ]

        self.iotManager.createKeysAndCertificate(fromCsr: csrDictionary, callback: {  (response ) -> Void in
            if (response != nil)
            {
                let defaults = UserDefaults.standard

                defaults.set(response?.certificateId, forKey:"certificateId")
                defaults.set(response?.certificateArn, forKey:"certificateArn")
                self.logger.print("🔑 Keys & Certificate: [\(response)]")

                self.logger.print("\n📎 Attaching IoT Policy.")
                let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
                attachPrincipalPolicyRequest?.policyName = self.policyName
                attachPrincipalPolicyRequest?.principal = response?.certificateArn
                //
                // Attach the policy to the certificate
                //
                self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest!).continueWith (block: { (task) -> AnyObject? in
                    if let error = task.error {
                        self.logger.print("📎 Policy error: [\(error)]")
                    }

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
                self.logger.print("🔑 Keys & Certificate: Unable to create Keys and/or Certificate. Please check settings.")
            }
        } )

    }
    
}
