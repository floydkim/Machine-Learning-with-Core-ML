//
//  VideoCapture.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 29/11/2017.
//  Copyright © 2017 Josh Newnham. All rights reserved.
//

import UIKit
import AVFoundation

public protocol VideoCaptureDelegate: class {
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer:CVPixelBuffer?, timestamp:CMTime)
}

/**
 Class used to faciliate accessing each frame of the camera using the AVFoundation framework (and presenting
 the frames on a preview view)
 https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput
 */
public class VideoCapture : NSObject{
    
    public weak var delegate: VideoCaptureDelegate?
    
    /**
     Frames Per Second; used to throttle capture rate
     */
    public var fps = 15
    
    var lastTimestamp = CMTime()
    
    let captureSession = AVCaptureSession()
    let sessionQueue = DispatchQueue(label: "sessing queue")
    
    override init() {
        super.init()
        
    }
    
    func initCamera() -> Bool{
        captureSession.beginConfiguration()
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("ERROR: no video devices available")
            return false
        }
        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("ERROR: could not create AVCaptureDeviceInput")
            return false
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        let settings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        videoOutput.videoSettings = settings
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        captureSession.commitConfiguration()
        
        return true
    }
    
    /**
     Start capturing frames
     This is a blocking call which can take some time, therefore you should perform session setup off
     the main queue to avoid blocking it.
     */
    public func asyncStartCapturing(completion: (() -> Void)? = nil){
        if !self.captureSession.isRunning {
            self.captureSession.startRunning()
        }
        
        if let completion = completion {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    /**
     Stop capturing frames
     */
    public func asyncStopCapturing(completion: (() -> Void)? = nil){
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
        
        if let completion = completion {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension VideoCapture : AVCaptureVideoDataOutputSampleBufferDelegate{
    
    /**
     Called when a new video frame was written
     */
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let delegate = self.delegate else {
            print("no delegate")
            return
        }
        
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let elapsedTime = timestamp - lastTimestamp
        if elapsedTime >= CMTimeMake(1, Int32(fps)) {
            print(timestamp.value)
            lastTimestamp = timestamp
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            delegate.onFrameCaptured(videoCapture: self, pixelBuffer: imageBuffer, timestamp: timestamp)
        }
    }
}

