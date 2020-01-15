//
//  AuthorizationStatusModel.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/10/24.
//  Copyright © 2018 Cybozu. All rights reserved.
//

import Foundation
import RxSwift
import Photos

class ImagePickerAuthorization {
    private let videoDisableSubject = BehaviorSubject<Bool>(value: true)
    private let photoDisableSubject = BehaviorSubject<Bool>(value: true)
    
    let videoDisable: Observable<Bool>
    var videoDisableValue: Bool {
        return self.videoDisableSubject.value(true)
    }
    let photoDisable: Observable<Bool>
    var photoDisableValue: Bool {
        return self.photoDisableSubject.value(true)
    }
    
    init() {
        self.videoDisable = self.videoDisableSubject.asObservable()
        self.photoDisable = self.photoDisableSubject.asObservable()
    }

    func checkAuthorizationStatus() {
        checkVideoAuthorizationStatus()
        checkPhotoAuthorizationStatus()
    }

    private var isSimulator: Bool {
        #if (!arch(i386) && !arch(x86_64))
        return false
        #else
        return true
        #endif
    }

    private func checkVideoAuthorizationStatus() {
        if self.isSimulator {
            // In case of simulator Always disable
            self.videoDisableSubject.onNext(true)
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch (status) {
        case .authorized:
            self.videoDisableSubject.onNext(false)
        case .denied, .restricted:
            self.videoDisableSubject.onNext(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                self.videoDisableSubject.onNext(!granted)
            })
        @unknown default:
            fatalError()
        }
    }
    
    private func checkPhotoAuthorizationStatus() {
        // You can use imagePicker without permission if iOS 11 or higher
        if #available(iOS 11.0, *) {
            self.photoDisableSubject.onNext(false)
            return
        }
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch (status) {
        case .authorized:
            self.photoDisableSubject.onNext(false)
        case .denied, .restricted:
            self.photoDisableSubject.onNext(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                self.photoDisableSubject.onNext((status != .authorized))
            })
        @unknown default:
            fatalError()
        }
    }
}
