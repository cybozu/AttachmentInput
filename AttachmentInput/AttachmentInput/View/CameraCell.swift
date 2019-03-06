//
//  CameraCell.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/02/14.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol CameraCellDelegate: class {
    func didTakePicture(imageData: Data)
    var photoQuality: Float { get }
}

class CameraCell: UICollectionViewCell {
    @IBOutlet var cameraView: CameraView!
    @IBOutlet var takePhotoButton: UIButton!

    private var captureDoubleTap: Bool = false

    weak var delegate: CameraCellDelegate?

    @IBAction func takePhoto() {
        guard captureDoubleTap == false else {
            return
        }
        self.captureDoubleTap = true

        let photoQuality = NSNumber(value: self.delegate?.photoQuality ?? 1)
        let format: [String : Any] = [AVVideoCodecKey: AVVideoCodecJPEG, AVVideoCompressionPropertiesKey: [AVVideoQualityKey: photoQuality]]
        let settingsForMonitoring = AVCapturePhotoSettings(format: format)
        settingsForMonitoring.flashMode = .off
        CameraView.stillImageOutput?.capturePhoto(with: settingsForMonitoring, delegate: self)
    }
    
    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrame), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
        setShutterIconLayout()
    }
    
    @objc func keyboardDidChangeFrame() {
        setShutterIconLayout()
    }
    
    func setup() {
        cameraView.setup()
    }
    
    // Change the display position of the shutter icon according to the orientation of the terminal
    private func setShutterIconLayout() {
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation.isLandscape {
            self.takePhotoButton.contentHorizontalAlignment = .right
            self.takePhotoButton.contentVerticalAlignment = .center
            self.takePhotoButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 10)
        } else {
            self.takePhotoButton.contentHorizontalAlignment = .center
            self.takePhotoButton.contentVerticalAlignment = .bottom
            self.takePhotoButton.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 10, right: 0)
        }
    }
}

extension CameraCell: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let photoSampleBuffer = photoSampleBuffer {
            if let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
                self.delegate?.didTakePicture(imageData: photoData)
            }
        }
        self.captureDoubleTap = false
    }
}
