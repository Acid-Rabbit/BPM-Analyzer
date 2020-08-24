//
//  ProgressBar.swift
//  BPM Analyzer
//
//  Created by 服部　翼 on 2020/07/10.
//  Copyright © 2020 服部　翼. All rights reserved.
//

import UIKit

class ProgressBar: UIView {
    
    private let shapeLayer = CAShapeLayer()
    
    override func draw(_ rect: CGRect) {
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY),
                                        radius: 90,
                                        startAngle: -CGFloat.pi / 2,
                                        endAngle: 2 * CGFloat.pi,
                                        clockwise: true)
        
        shapeLayer.path = circularPath.cgPath
        
        shapeLayer.strokeColor = MyColor.boarderColor.cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .round
        
        shapeLayer.strokeEnd = 1
        self.layer.addSublayer(shapeLayer)
    }
    
    
    func startAnimation() {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.duration = 0.5
        basicAnimation.fromValue = 0
        basicAnimation.toValue = 1
        
        basicAnimation.fillMode = .forwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "urSoBasic")
    }
}
