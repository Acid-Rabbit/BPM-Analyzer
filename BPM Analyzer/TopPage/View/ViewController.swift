//
//  ViewController.swift
//  BPM Analyzer
//
//  Created by 服部　翼 on 2020/07/04.
//  Copyright © 2020 服部　翼. All rights reserved.
//

import UIKit
import MediaPlayer
import IBAnimatable
import MarqueeLabel
import NVActivityIndicatorView
import FontAwesome_swift
import LTMorphingLabel

class ViewController: UIViewController {
    
    private var presenter = Presenter()
    private var animator = UIViewPropertyAnimator()
    lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    lazy var heavyFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    
    @IBOutlet weak var indicatorView: NVActivityIndicatorView!
    @IBOutlet weak var bpmCountLabel: LTMorphingLabel!
    @IBOutlet weak var musicTitleLabel: UILabel!
    @IBOutlet weak var barLabel: UILabel!
    
    @IBOutlet weak var countButton: AnimatableButton!
    @IBOutlet weak var selectorButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var playerViewOpenButton: UIButton!
    
    @IBOutlet weak var musicPlayerItemView: UIView!
    @IBOutlet weak var musicPlayerItemViewHeight: NSLayoutConstraint!
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var playTimeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("test")
        musicPlayerItemViewHeight.constant = 0
        
        bpmCountLabel.morphingEffect = .evaporate
        
        selectorButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        selectorButton.setTitle(.fontAwesomeIcon(name: .listUl), for: .normal)
        
        resetButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        resetButton.setTitle(.fontAwesomeIcon(name: .redo), for: .normal)
        
        playPauseButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 25, style: .solid)
        playPauseButton.setTitle(.fontAwesomeIcon(name: .play), for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playTimeBindToSlider(notidication:)), name: NSNotification.Name("updatePlaybackTime"), object: nil)
        playTimeSlider.addTarget(self, action: #selector(onSliderValueChanged(slider:event:)), for: .valueChanged)
        
    }
    
    @IBAction func tappedListButton(_ sender: Any) {
        feedbackGenerator.impactOccurred()
        let picker = MPMediaPickerController()
        picker.delegate = self
        picker.allowsPickingMultipleItems = false
        self.present(picker, animated: true, completion: nil)
    }
    
    
    @IBAction func tappedResetButton(_ sender: Any) {
        feedbackGenerator.impactOccurred()
        presenter.tappedRestButton()
        
        if presenter.playBackState() == .playing {
            barLabel.text = "#Bar: 0"
            bpmCountLabel.text = "0"
        } else {
            barLabel.text = "#Bar: 0"
            bpmCountLabel.text = "0"
            musicTitleLabel.text = "Beats Per Minute"
        }
    }
    
    @IBAction func touchDownCountButton(_ sender: Any) {
        animator.stopAnimation(true)
        countButton.backgroundColor = MyColor.highlightCountButtonColor
    }
    
    
    @IBAction func touchUpCountButton(_ sender: Any) {
        bpmCountLabel.text = "\(presenter.tappedCountButton())"
        
        if presenter.tappedCount() == 1 {
            heavyFeedbackGenerator.impactOccurred()
            barLabel.text = "#Bar: \(presenter.bar)"
        }
        
        animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut, animations: {
            self.countButton.backgroundColor = MyColor.baseColor
        })
        animator.startAnimation()
    }
    
    @IBAction func tappedPlayPauseButton(_ sender: Any) {
        
        switch presenter.playBackState() {
        case .paused, .stopped:
            musicTitleLabel.text = presenter.musicTitle
            playPauseButton.setTitle(.fontAwesomeIcon(name: .pause), for: .normal)
            presenter.play()
            print("stop")
        case .playing:
            playPauseButton.setTitle(.fontAwesomeIcon(name: .play), for: .normal)
            presenter.stop()
        default: break
        }
    }
    
    
    @IBAction func tappedHiddenPlayerButon(_ sender: Any) {
        
        if musicPlayerItemViewHeight.constant == 120 {
            playerViewOpenButton.setImage(UIImage(systemName: "arrowtriangle.up.fill"), for: .normal)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.musicPlayerItemViewHeight.constant = 0
                self.view.layoutIfNeeded()
            })
        } else {
            playerViewOpenButton.setImage(UIImage(systemName: "arrowtriangle.down.fill"), for: .normal)
            
            UIView.animate(withDuration: 0.3) {
                self.musicPlayerItemViewHeight.constant = 120
                self.view.layoutIfNeeded()
            }
        }
    }
    
    
    @objc func onSliderValueChanged(slider: UISlider, event: UIEvent) {
        
        startTimeLabel.text = presenter.movingSliderTime(value: slider.value).playTime
        endTimeLabel.text = presenter.movingSliderTime(value: slider.value).finishTime
        
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began, .moved:
                presenter.touchesSlider = true
            case .ended, .cancelled:
                presenter.player.currentPlaybackTime = TimeInterval(slider.value)
                presenter.touchesSlider = false
            default: break
            }
        }
    }
    
    @objc private func playTimeBindToSlider(notidication: Notification) {
        if let playbackTime = notidication.userInfo?["playBackTime"] as? TimeInterval {
            print(playTimeSlider.value, presenter.totalTime())
            if playTimeSlider.value >= presenter.totalTime() {
                presenter.stop()
                playTimeSlider.setValue(0, animated: true)
                playPauseButton.setTitle(.fontAwesomeIcon(name: .play), for: .normal)
                startTimeLabel.text = "00:00"
                endTimeLabel.text = presenter.totalTimeStrings()
            } else {
                playTimeSlider.setValue(Float(playbackTime), animated: true)
                self.startTimeLabel.text = presenter.timeintervalString().playTime
                self.endTimeLabel.text = presenter.timeintervalString().finishTime
            }
        }
    }
}

extension ViewController: MPMediaPickerControllerDelegate {
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        startAnimation()
        
        self.presenter.player.setQueue(with: mediaItemCollection)
        presenter.tappedRestButton()
        presenter.stop()
        presenter.timerInvalidate()
        
        playTimeSlider.setValue(0, animated: true)
        
        barLabel.text = "#Bar: 0"
        startTimeLabel.text = "00:00"
        endTimeLabel.text = "-00:00"
        musicTitleLabel.text = self.presenter.returnMusicTitle(mediaItemCollection: mediaItemCollection)
        
        playPauseButton.setTitle(.fontAwesomeIcon(name: .play), for: .normal)
        playerViewOpenButton.isHidden = false
        dismiss(animated: true, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: 0.3) {
                self.musicPlayerItemViewHeight.constant = 120
                self.view.layoutIfNeeded()
            }
        }
        
        DispatchQueue.global().async {
            self.presenter.searchBPM(mediaItemCollection: mediaItemCollection) { (bpm) in
                self.bpmCountLabel.text = bpm
                self.endTimeLabel.text = self.presenter.totalTimeStrings()
                self.playTimeSlider.maximumValue = self.presenter.totalTime()
                self.stopAnimation()
            }
        }
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension ViewController {
    
    private func startAnimation() {
        indicatorView.startAnimating()
        
        resetButton.isEnabled = false
        resetButton.alpha = 0.5
        selectorButton.isEnabled = false
        selectorButton.alpha = 0.5
        countButton.isEnabled = false
        countButton.alpha = 0.5
        playerViewOpenButton.isEnabled = false
        playPauseButton.isEnabled = false
        playPauseButton.alpha = 0.5
        playTimeSlider.isEnabled = false
    }
    
    private func stopAnimation() {
        indicatorView.stopAnimating()
        
        resetButton.isEnabled = true
        resetButton.alpha = 1.0
        selectorButton.isEnabled = true
        selectorButton.alpha = 1.0
        countButton.isEnabled = true
        countButton.alpha = 1.0
        playerViewOpenButton.isEnabled = true
        playPauseButton.isEnabled = true
        playPauseButton.alpha = 1.0
        playTimeSlider.isEnabled = true
    }
}
