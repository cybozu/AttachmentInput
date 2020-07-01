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
    
    let videoDisable: Observable<Bool>
    var videoDisableValue: Bool {
        return self.videoDisableSubject.value(true)
    }
    
    init() {
        self.videoDisable = self.videoDisableSubject.asObservable()
    }

    func checkAuthorizationStatus() {
        checkVideoAuthorizationStatus()
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
}
