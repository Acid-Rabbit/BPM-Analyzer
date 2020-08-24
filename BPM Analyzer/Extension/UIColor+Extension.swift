//
//  UIColor+Extension.swift
//  BPM Analyzer
//
//  Created by 服部　翼 on 2020/07/07.
//  Copyright © 2020 服部　翼. All rights reserved.
//

import Foundation
import UIKit

struct MyColor {
    static let baseColor = UIColor(hex: "211F27")
    static let boarderColor = UIColor(hex: "50E0D2")
    static let buttonColor = UIColor(hex: "B0BEC9")
    
    static let highlightCountButtonColor = UIColor(hex: "3e3a4a", alpha: 0.6)
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let v = Int("000000" + hex, radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
}
