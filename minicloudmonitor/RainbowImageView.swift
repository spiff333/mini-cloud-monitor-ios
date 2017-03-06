//
//  RainbowImageView.swift
//  minicloudmonitor
//
//  Created by Marc Plassmeier on 5/3/17.
//  Copyright © 2017 Marc Plassmeier. All rights reserved.
//

import UIKit

class RainbowImageView: UIImageView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    // TODO remove magic number
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if (point.y > 460) {
            return self
        }
        return nil
    }

}
