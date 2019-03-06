//
//  AttachmentInput.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/09/04.
//  Copyright © 2018 Cybozu. All rights reserved.
//
import UIKit

public class AttachmentInput {
    public static let defaultCongiguration = AttachmentInputConfiguration()
    private let attachmentInputView: AttachmentInputView
    
    public var view: UIView {
        get {
            self.attachmentInputView.initializeIfNeed()
            return self.attachmentInputView
        }
    }
    
    public var delegate: AttachmentInputDelegate? {
        get {
            return self.attachmentInputView.delegate
        }
        set {
            self.attachmentInputView.delegate = newValue
        }
    }

    public init (configuration: AttachmentInputConfiguration = AttachmentInput.defaultCongiguration) {
        self.attachmentInputView = AttachmentInputView.createAttachmentInputView(configuration: configuration)
    }
    
    public func removeFile(identifier: String) {
        self.attachmentInputView.removeFile(identifier: identifier)
    }
}
