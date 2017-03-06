//
//  MainViewController.swift
//  minicloudmonitor
//
//  Created by Marc Plassmeier on 3/3/17.
//  Copyright © 2017 Marc Plassmeier. All rights reserved.
//

import UIKit
import AWSIoT

class MainViewController: UIViewController {

    let awsIotClient = AwsIotClient()

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var cloudImageView: UIButton!

    var lastHueValue: CGFloat = 0.0
    var logger = Logger.sharedInstance
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: self.view)
            
            let x = self.view.bounds.maxX / 2.0 - currentPoint.x
            let y = self.view.bounds.maxY - currentPoint.y
            
            let r = sqrt(x * x + y * y)
            
            
            // TODO remove magic numbers
            if ( r > 60.0 && r < 230.0 ) {
                let rainbowRange: CGFloat = 0.84
                let hue = rainbowRange - (r-60.0) / (230.0-60.0) * rainbowRange
                
                // reduce state changes
                if ( abs(lastHueValue-hue) >= 0.025 ) {
                    cloudImageView.tintColor = UIColor(hue: hue, saturation: 1.0, brightness: 0.9, alpha: 1.0)
                    lastHueValue = hue

                    awsIotClient.publishToTopic(message: "{\"colour\": \"\(cloudImageView.tintColor.toHex()!)\"}");
                }

                return
            }
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.curveEaseOut], animations: { self.cloudImageView.tintColor = UIColor.white }, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        awsIotClient.connect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

