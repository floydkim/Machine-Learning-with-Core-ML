//
//  ViewController.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 16/12/2017.
//  Copyright © 2017 Method. All rights reserved.
//

import UIKit
import CoreVideo
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var previewView: CapturePreviewView!
    @IBOutlet weak var classifiedLabel: UILabel!
    
    let videoCapture : VideoCapture = VideoCapture()
    let context = CIContext()
    // let model = Inceptionv3()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        videoCapture.delegate = self
        
        if self.videoCapture.initCamera() {
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
            
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            self.videoCapture.asyncStartCapturing()
        } else {
            fatalError("Failed to init VideoCapture")
        }
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(videoCapture: VideoCapture,
                         pixelBuffer:CVPixelBuffer?,
                         timestamp:CMTime){
        guard let pixelBuffer = pixelBuffer else { return }
        
        guard let scaledPixelBuffer = CIImage(cvImageBuffer: pixelBuffer)
            .resize(size: CGSize(width: 299, height: 299))
            .toPixelBuffer(context: context) else { return }
    }
}

