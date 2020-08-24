//
//  TappedBPMAnalyze.swift
//  BPM Analyzer
//
//  Created by 服部　翼 on 2020/07/15.
//  Copyright © 2020 服部　翼. All rights reserved.
//

import Foundation

class TappedAnalyzeBPM {
    
    private var timeData = [Float]()
    private var difData = [Float]()
    
    private var countTime: Float = 0
    private var timer: Timer?
    private var timerON = false
    private var bpm: Float = 0
    
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
    }
    
    @objc func timeUpdate() {
        countTime += 0.01
    }
    
    func tapped() -> Float {
        
        var ave: Float = 0
        
        if !timerON {
            timerON = true
            startTimer()
        }
        
        timeData.append(countTime)
        
        if timeData.count > 1 {
            difData.append(timeData[timeData.count - 1] - timeData[timeData.count - 2])
            
            
            for i in 0..<difData.count {
                ave = ave + difData[i]
            }
            
            ave = ave / Float(difData.count)
            bpm = 60 / ave
            
        }
        
        return bpm
    }
    
    func reset() {
        countTime = 0
        timer?.invalidate()
        timerON = false
        bpm = 0
        timeData.removeAll()
        difData.removeAll()
    }
    
}
