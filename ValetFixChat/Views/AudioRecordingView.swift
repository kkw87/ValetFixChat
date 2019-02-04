//
//  AudioRecordingView.swift
//  ValetFixChat
//
//  Created by Kevin Wang on 2/2/19.
//  Copyright © 2019 Kevin Wang. All rights reserved.
//

import UIKit
import RecordButton

protocol AudioRecordingViewDelegate {
    func recordButtonPressed()
    func recordButtonStopped()
}

class AudioRecordingView: UIView {
    
    // MARK: - Constants
    struct Constants {
        static let RecordButtonWidth : CGFloat = 40
        static let RecordButtonHeight : CGFloat = 40
        static let TimerTimeInterval : CGFloat = 0.05
    }
    
    // MARK: - Instance Variables

    var delegate : AudioRecordingViewDelegate?
    private var recordButton : RecordButton!
    private var progressTimer : Timer!
    private var progress : CGFloat = 0
    private var audioRecordingLength : CGFloat = 10
    private var audioRecordingLengthTimeInterval : TimeInterval {
        return Double(audioRecordingLength / 100)
    }
    
    private var isRecording : Bool = false
    
    // MARK: - Init
    
    convenience init(maxRecordingTime : CGFloat, withFrame : CGRect) {
        self.init(frame: withFrame)
        audioRecordingLength = maxRecordingTime
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        recordButton = RecordButton(frame: CGRect(x: 0, y: 0, width: Constants.RecordButtonWidth, height: Constants.RecordButtonHeight))
        recordButton.addTarget(self, action: #selector(startRecording), for: .touchDown)
        recordButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        recordButton.progressColor = UIColor.red
        recordButton.buttonColor = UIColor.red
        recordButton.closeWhenFinished = false
        
        addSubview(recordButton)
        recordButton.center = self.center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Start recording functions
    @objc func startRecording() {
        isRecording = true
        
        delegate?.recordButtonPressed()
        progressTimer = Timer.scheduledTimer(timeInterval: audioRecordingLengthTimeInterval, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    
    // MARK: - Stop recording
    @objc func stopRecording() {
        
        delegate?.recordButtonStopped()


        if isRecording {
            progressTimer.invalidate()
            progress = 0
            isRecording = false
        }
    }
    
    // MARK: - Recording button progress
    @objc private func updateProgress() {
        
        progress = progress + (CGFloat(audioRecordingLengthTimeInterval) / audioRecordingLength)
        recordButton.setProgress(progress)
        
        if progress >= 1 {
            progressTimer.invalidate()
        }
    }
    
}
