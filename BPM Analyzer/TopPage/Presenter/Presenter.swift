//
//  MediaPickerPresenter.swift
//  BPM Analyzer
//
//  Created by 服部　翼 on 2020/07/05.
//  Copyright © 2020 服部　翼. All rights reserved.
//

import MediaPlayer
import PromiseKit

class Presenter {
    
    private var analyzeBPM = AnalyzeBPMManager()
    private var tappedAnalyzeBPM = TappedAnalyzeBPM()
    let player = MPMusicPlayerController.applicationMusicPlayer
    var musicTitle = ""
    
    private var count = 0
    var bar = 0

    private var timer: Timer?
    private var timeinterval: TimeInterval!
    
    var touchesSlider = false
    
    func play() {
        player.play()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updatePlaybackTime), userInfo: nil, repeats: true)
    }
    
    @objc private func updatePlaybackTime() {
        if !touchesSlider {
            NotificationCenter.default.post(name: NSNotification.Name("updatePlaybackTime"), object: nil, userInfo: ["playBackTime": player.currentPlaybackTime])
        }
    }
    
    func stop() {
        player.pause()
        timerInvalidate()
    }
    
    func playBackState() -> MPMusicPlaybackState {
        return player.playbackState
    }
    
    func totalTime() -> Float {
        return Float(analyzeBPM.totalTime())
    }
    
    func totalTimeStrings() -> String {
        let totalTime = clockTimeConversion(time: analyzeBPM.totalTime())
        return "-\(totalTime)"
    }
    
    func timeintervalString() -> (playTime: String, finishTime: String) {
        let playTime = clockTimeConversion(time: player.currentPlaybackTime)
        let endTime = "-" + clockTimeConversion(time: analyzeBPM.totalTime() - player.currentPlaybackTime)
        return (playTime: playTime, finishTime: endTime)
    }
    
    func movingSliderTime(value: Float) -> (playTime: String, finishTime: String) {
        let moveingPositionTime = clockTimeConversion(time: Double(value))
        let endTime = "-" + clockTimeConversion(time: analyzeBPM.totalTime() - Double(value))
        return (playTime: moveingPositionTime, finishTime: endTime)
    }
    
    private func clockTimeConversion<T> (time: T) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.second, .minute]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: time as! TimeInterval) ?? ""
    }

    func timerInvalidate() {
        if let timer = timer {
            timer.invalidate()
        }
    }
    
    
    func searchBPM(mediaItemCollection: MPMediaItemCollection, completion: @escaping(String) -> Void) {
        
        let item = mediaItemCollection.items[0]
        if let assetURL: URL = item.assetURL {
            do {
                let musicURL = try AVAudioPlayer(contentsOf: assetURL)
                guard let url = musicURL.url else {return}
                firstly {
                    self.analyzeBPM.loadAudioData(fileURL: url)
                }.then {
                    self.analyzeBPM.calculateFrameVolume()
                }.then {
                    self.analyzeBPM.caculateDiffVolume()
                }.done {
                    completion(String(self.analyzeBPM.searchTempo()))
                }.catch { (error) in
                    print(error.localizedDescription)
                }
            } catch {
                print("Error")
                return
            }
        }
    }
    
    func returnMusicTitle(mediaItemCollection: MPMediaItemCollection) -> String {
        let item = mediaItemCollection.items[0]
        musicTitle = item.title ?? ""
        return musicTitle
    }
    
    
    
}


extension Presenter {
    
    func tappedCount() -> Int {
        if count == 4 {
            count = 1
            bar += 1
        } else {
            count += 1
        }
        return count
    }
    
    func tappedCountButton() -> Int {
        return Int(roundf(tappedAnalyzeBPM.tapped()))
    }
    
    func tappedRestButton() {
        bar = 0
        count = 0
        tappedAnalyzeBPM.reset()
    }
}
