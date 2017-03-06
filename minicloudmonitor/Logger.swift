//
//  Logger.swift
//  minicloudmonitor
//
//  Created by Marc Plassmeier on 6/3/17.
//  Copyright © 2017 Marc Plassmeier. All rights reserved.
//

import Foundation

class Logger {
    

    let loggerNotificationKey = "LoggerNotification"

    static let sharedInstance = Logger()
    
    
    var log: String = ""
    
    
    func print(_ str: String) {
        log.append(str + "\n")
        NotificationCenter.default.post( name: Notification.Name(rawValue: loggerNotificationKey), object: self )
    }
    
    func clear() {
        log = ""
        NotificationCenter.default.post( name: Notification.Name(rawValue: loggerNotificationKey), object: self )
    }
}
