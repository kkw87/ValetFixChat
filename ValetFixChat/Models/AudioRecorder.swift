//
//  AudioRecorder.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 2/2/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import Foundation
import AVFoundation

//MARK: - AudioRecorderDelegate declarations
protocol AudioRecorderDelegate {
    func unableToRecordMessage()
}

class AudioRecorder : NSObject {
    
    //MARK: - Instance variables
    private let recordingSession = AVAudioSession.sharedInstance()
    private var audioRecording : AVAudioRecorder!
    private var audioRecordingURL : URL?
    
    var delegate : AudioRecorderDelegate?
    
    // MARK: - Audio Recording setup

    func startRecording() {
    
        audioRecordingURL = nil
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission {(recordingAllowed) in
                
                
                if recordingAllowed {
                    
                    self.recordAudio()
                    
                } else {
                    self.delegate?.unableToRecordMessage()
                }
            }
            
        } catch {
            delegate?.unableToRecordMessage()
        }
    }
    
    // MARK: - Audio recording completed functions
    func recordingFinished() -> URL? {
        
        if audioRecording != nil {
            audioRecording.stop()
            audioRecording = nil
        }
    
        
        return audioRecordingURL
    }

    // MARK: - Audio recording functions
    private func recordAudio() {
        let audioFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("\(UUID().uuidString).m4a")
        let audioSettings = [AVFormatIDKey : Int(kAudioFormatMPEG4AAC), AVSampleRateKey : 12000, AVNumberOfChannelsKey : 1, AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue]
        
        do {
            
            audioRecording = try AVAudioRecorder(url: audioFileURL, settings: audioSettings)
            audioRecording.delegate = self
            audioRecording.record()
            audioRecordingURL = audioFileURL
            
        } catch {
            delegate?.unableToRecordMessage()
        }
        
    }
}

extension AudioRecorder : AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            audioRecordingURL = nil
            audioRecording.stop()
            audioRecording = nil
            delegate?.unableToRecordMessage()
        }
    }
}
