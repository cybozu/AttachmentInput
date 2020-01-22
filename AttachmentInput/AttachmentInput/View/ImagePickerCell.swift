//
//  ImagePickerCell.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/02/14.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import AVFoundation
import MobileCoreServices

protocol ImagePickerCellDelegate: class {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    var videoQuality: UIImagePickerController.QualityType { get }
}

class ImagePickerCell: UICollectionViewCell {
    @IBOutlet var cameraButtonView: UIView!
    @IBOutlet var cameraButtonIcon: UIImageView!
    @IBOutlet var cameraButtonLabel: UILabel!
    @IBOutlet var photoLibraryButtonView: UIView!
    @IBOutlet var photoLibraryButtonIcon: UIImageView!
    @IBOutlet var photoLibraryButtonLabel: UILabel!

    private var imagePickerAuthorization = ImagePickerAuthorization()
    private var initialized = false
    private let disposeBag = DisposeBag()
    weak var delegate: ImagePickerCellDelegate?

    @IBAction func tapCamera() {
        if self.imagePickerAuthorization.videoDisableValue {
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        if let videoQuality = self.delegate?.videoQuality {
            picker.videoQuality = videoQuality
        }
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        self.getTopViewController()?.present(picker, animated: true)
    }

    @IBAction func tapPhotoLibrary() {
        if self.imagePickerAuthorization.photoDisableValue {
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        if let videoQuality = self.delegate?.videoQuality {
            picker.videoQuality = videoQuality
        }
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        self.getTopViewController()?.present(picker, animated: true)
    }

    private func getTopViewController() -> UIViewController? {
        if var topViewControlelr = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topViewControlelr.presentedViewController {
                topViewControlelr = presentedViewController
            }
            return topViewControlelr
        }
        return nil
    }

    func setup() {
        initializeIfNeed()
    }

    override func awakeFromNib() {
        setupText()
        setupDesign()
    }
    
    private func initializeIfNeed() {
        guard !self.initialized else {
            return
        }
        self.initialized = true
        self.imagePickerAuthorization.checkAuthorizationStatus()
        self.imagePickerAuthorization.videoDisable.subscribe(onNext: { [weak self] disable in
            DispatchQueue.main.async {
                self?.setupDesignForCameraButton(disable: disable)
            }
        }).disposed(by: self.disposeBag)
        
        self.imagePickerAuthorization.photoDisable.subscribe(onNext: { [weak self] disable in
            DispatchQueue.main.async {
                self?.setupDesignForPhotosButton(disable: disable)
            }
        }).disposed(by: self.disposeBag)

    }

    private func setupText() {
        self.cameraButtonLabel.text = String(format: NSLocalizedString("Camera", comment: ""))
        self.photoLibraryButtonLabel.text = String(format: NSLocalizedString("Photos", comment: ""))
    }

    private func setupDesign() {
        self.cameraButtonView.backgroundColor = AttachmentInputColor.white
        self.cameraButtonLabel.textColor = AttachmentInputColor.primaryColor
        self.cameraButtonLabel.font = AttachmentInputFont.body2
        self.photoLibraryButtonView.backgroundColor = AttachmentInputColor.white
        self.photoLibraryButtonLabel.textColor = AttachmentInputColor.primaryColor
        self.photoLibraryButtonLabel.font = AttachmentInputFont.body2
        self.setupDesignForCameraButton(disable: true)
        self.setupDesignForPhotosButton(disable: true)
    }
    
    private func setupDesignForCameraButton(disable: Bool) {
        if disable {
            self.cameraButtonIcon.tintColor = AttachmentInputColor.borderGray
            self.cameraButtonLabel.textColor = AttachmentInputColor.borderGray
            self.cameraButtonIcon.alpha = 0.5
            self.cameraButtonLabel.alpha = 0.5
        } else {
            self.cameraButtonIcon.tintColor = AttachmentInputColor.primaryColor
            self.cameraButtonLabel.textColor = AttachmentInputColor.primaryColor
            self.cameraButtonIcon.alpha = 1
            self.cameraButtonLabel.alpha = 1
        }
    }
    
    private func setupDesignForPhotosButton(disable: Bool) {
        if disable {
            self.photoLibraryButtonIcon.tintColor = AttachmentInputColor.borderGray
            self.photoLibraryButtonLabel.textColor = AttachmentInputColor.borderGray
            self.photoLibraryButtonIcon.alpha = 0.5
            self.photoLibraryButtonLabel.alpha = 0.5
        } else {
            self.photoLibraryButtonIcon.tintColor = AttachmentInputColor.primaryColor
            self.photoLibraryButtonLabel.textColor = AttachmentInputColor.primaryColor
            self.photoLibraryButtonIcon.alpha = 1
            self.photoLibraryButtonLabel.alpha = 1
        }
    }
}


extension ImagePickerCell: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        self.delegate?.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.delegate?.imagePickerControllerDidCancel(picker)
    }
}
