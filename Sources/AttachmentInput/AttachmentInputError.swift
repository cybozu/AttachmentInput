//
//  AttachmentInputError.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/07/12.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation

public enum AttachmentInputError: Error {
    case overLimitSize
    case compressVideoFailed
    case compressImageFailed
    case thumbnailLoadFailed
    case propertiesLoadFailed
}

extension AttachmentInputError {
    public var debugDescription: String {
        switch self {
        case .overLimitSize:
            return "Attachment size exceeds the allowable limit."
        case .compressVideoFailed:
            return "Unable to compress video."
        case .compressImageFailed:
            return "Unable to compress image."
        case .thumbnailLoadFailed:
            return "Unable to load thumbnail image."
        case .propertiesLoadFailed:
            return "Unable to load photo properties."
        }
    }
}
