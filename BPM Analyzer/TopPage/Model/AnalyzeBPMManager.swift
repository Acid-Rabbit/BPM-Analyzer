//
//  AnalyzeBPMManager.swift
//  BPM Analyzer
//
//  Created by 服部　翼 on 2020/07/05.
//  Copyright © 2020 服部　翼. All rights reserved.
//

import MediaPlayer
import AVFoundation
import PromiseKit

enum AudioError: Error {
    case loadError
    case frameVolumeError
    case caculateDiffVolumeError
    
    var localizedDescription: String {
        switch self {
        case .loadError: return "Error: LoadAudioData"
        case .frameVolumeError: return "Error: calculateFrameVolume"
        case .caculateDiffVolumeError: return "Error: caculateDiffVolume"
        }
    }
}

class AnalyzeBPMManager {
    
    private var audioFile: AVAudioFile?
    private var pcmBuffer: AVAudioPCMBuffer!
    
    private var samplingRate: Double?
    private var nChannel: Int?
    private var nframe: Int?
    
    private let frameLength = 512
    private var vols:[Double] = []
    
    private var diffs:[Double] = []
    
    private var errorBPM = -1
    
    //オーディオのバイナリデータを格納するためのbuffer, マルチチャンネルに対応するため、二次元配列になっています。
    var buffer:[[Float]]! = Array<Array<Float>>()
    
    func totalTime() -> Double {
        guard let length = audioFile?.length,
            let sampleRate = audioFile?.fileFormat.sampleRate else {return 0}
        return Double(length) / sampleRate
    }
    
    
    
    // MARK: - オーディオデータ読み込み
    func loadAudioData(fileURL: URL) -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()
        let error = AudioError.loadError
        
        do {
            audioFile = try AVAudioFile(forReading: fileURL)
            samplingRate = audioFile?.fileFormat.sampleRate
            nChannel = Int(audioFile?.fileFormat.channelCount ?? 0) //チャンネル数？
        } catch {
            print("Catch Error: Loading audio file failed.")
        }
        
        guard let audioFile = audioFile, let nChannel = nChannel else {
            resolver.reject(error)
            return promise
        }
        
        //オーディオの長さ（多分）
        nframe = Int(audioFile.length)
        
        guard let nframe = nframe else {
            resolver.reject(error)
            return promise
        }
        
        pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(nframe))
        
        guard let floatChannelData = pcmBuffer.floatChannelData else {
            resolver.reject(error)
            return promise
        }
        
        do {
            try audioFile.read(into: pcmBuffer)
            buffer.removeAll()
            for i in 0 ..< nChannel {
                let buf:[Float] = Array(UnsafeMutableBufferPointer(start: floatChannelData[i], count: nframe))
                buffer.append(buf)
            }
        } catch {
            print("Catch Error: Loading audio file failed.")
        }
        
        resolver.fulfill(Void())
        return promise
    }
    
    
    // MARK: - 音楽のBPMを調べる
    func calculateFrameVolume() -> Promise<Void> {
        
        let (promise, resolver) = Promise<Void>.pending()
        
        // フレームの数
        let frame = nframe! / frameLength
        vols.removeAll()
        
        for i in 0 ..< frame {
            var vol: Double = 0
            for j in 0 ..< frameLength {
                let idx = i * frameLength + j
                let sound = Double(buffer[0][idx])
                vol += pow(sound, 2)
            }
            let vol2 = sqrt((1.0 / Double(frameLength)) * vol)
            vols.append(vol2)
        }
        
        resolver.fulfill(Void())
        return promise
    }
    
    //隣り合うフレームの音量の増加分を求める
    func caculateDiffVolume() -> Promise<Void> {
        
        let (promise, resolver) = Promise<Void>.pending()
        
        // フレームの数
        let n = nframe! / frameLength
        
        diffs.removeAll()
        
        for i in 0 ..< n - 1 {
            let value = vols[i] - vols[ i + 1]
            let diff = value > 0 ? value : 0
            diffs.append(diff)
        }
        diffs.append(0)
        
        resolver.fulfill(Void())
        return promise
    }
    
    //どのテンポがマッチするかを求める
    func searchTempo() -> Int {
        // 最大最小テンポ
        let minBPM = 60
        let maxBPM = 240
        
        // フレームの数
        let n = nframe! / frameLength
        
        let s = samplingRate! / Double(frameLength)
        
        var a: [Double] = []
        var b: [Double] = []
        var r: [Double] = []
        
        for bpm in minBPM ... maxBPM {
            var aSum: Double = 0
            var bSum: Double = 0
            let f = Double(bpm) / Double(60)
            for i in 0 ..< n {
                aSum += diffs[i] * cos(2.0 * Double.pi * f * Double(i) / s)
                bSum += diffs[i] * sin(2.0 * Double.pi * f * Double(i) / s)
            }
            let aTMP = aSum / Double(n)
            let bTMP = bSum / Double(n)
            a.append(aTMP)
            b.append(bTMP)
            r.append(sqrt(pow(aTMP, 2) + pow(bTMP, 2)))
        }
        
        var maxIndex = errorBPM
        
        // 一番マッチするインデックスを求める
        var dy:Double = 0
        for i in 1 ..< (maxBPM - minBPM + 1) {
            let dyPre = dy
            dy = r[i] - r[i - 1]
            if dyPre > 0 && dy <= 0 {
                if maxIndex < 0 || r[i - 1] > r[maxIndex] {
                    maxIndex = i - 1
                }
            }
        }
        
        if maxIndex < 0 {
            return errorBPM
        }
        
        return maxIndex + minBPM
    }
}
