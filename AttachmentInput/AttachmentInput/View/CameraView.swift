//
//  CameraView.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/02/16.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

// Generate AVCaptureVideoPreviewLayer and display it on the full screen
class CameraView: UIView {
    override func awakeFromNib() {
        self.setupDesign()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        
        // postpone heavy processing to first display the keyboard
        DispatchQueue.main.async {
            if CameraView.videoPreviewLayer == nil {
                CameraView.initcamera()
            }
            self.setup()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let preview = CameraView.videoPreviewLayer {
            preview.frame = self.bounds
        }
    }

    @objc func keyboardDidChangeFrame() {
        CameraView.onOrientationChanged()
    }

    func setup() {
        if let session = CameraView.session {
            if session.sessionPreset != AVCaptureSession.Preset.photo {
                session.sessionPreset = AVCaptureSession.Preset.photo
            }
            if !session.isRunning {
                session.startRunning()
            }
        }
        if CameraView.videoPreviewLayer?.superlayer != self.layer, let videoPreviewLayer = CameraView.videoPreviewLayer {
            videoPreviewLayer.removeFromSuperlayer()
            self.layer.addSublayer(videoPreviewLayer)
        }
    }
    
    private func setupDesign() {
        self.backgroundColor = UIColor.black
    }
}

extension CameraView {
    static private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    static private var session: AVCaptureSession?
    static var stillImageOutput: AVCapturePhotoOutput?

    static private func getAVCaputureVideoOrientation() -> AVCaptureVideoOrientation {
        let deviceOrientation = UIDevice.current.orientation
        let orientation: AVCaptureVideoOrientation
        if deviceOrientation.isLandscape {
            if deviceOrientation == UIDeviceOrientation.landscapeLeft {
                orientation = AVCaptureVideoOrientation.landscapeRight
            } else {
                orientation = AVCaptureVideoOrientation.landscapeLeft
            }
        } else {
            orientation = AVCaptureVideoOrientation.portrait
        }
        return orientation
    }
    
    static private func onOrientationChanged() {
        let orientation = CameraView.getAVCaputureVideoOrientation()
        if let connection = CameraView.stillImageOutput?.connection(with: AVMediaType.video), let videoPreview = CameraView.videoPreviewLayer {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = orientation
                videoPreview.connection?.videoOrientation = orientation
            }
        }
    }
    
    // Initialization of the camera. When using the camera for the first time,
    // a permission dialog will appear.
    static private func initcamera() {
        if let input = CameraView.createInput() {
            let session = CameraView.createSession()
            if session.canAddInput(input) {
                session.addInput(input)
                if let output = CameraView.createOutput(session: session) {
                    CameraView.stillImageOutput = output
                    CameraView.videoPreviewLayer = createPreviewLayer(session: session)
                    CameraView.session = session
                }
            }
        }
    }
    
    static private func createInput() -> AVCaptureDeviceInput? {
        var input: AVCaptureDeviceInput? = nil
        do {
            if let backCamera = AVCaptureDevice.default(for: AVMediaType.video) {
                input = try AVCaptureDeviceInput(device: backCamera)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return input
    }
    
    static private func createSession() -> AVCaptureSession {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        return session
    }
    
    static private func createOutput(session: AVCaptureSession) -> AVCapturePhotoOutput? {
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            return output
        }
        return nil
    }
    
    static private func createPreviewLayer(session: AVCaptureSession) -> AVCaptureVideoPreviewLayer {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        videoPreviewLayer.connection?.videoOrientation = getAVCaputureVideoOrientation()
        return videoPreviewLayer
    }
}
