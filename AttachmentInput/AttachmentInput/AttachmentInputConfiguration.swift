//
//  AttachmentInputConfiguration.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/09/06.
//  Copyright © 2018 Cybozu. All rights reserved.
//
import UIKit

public class AttachmentInputConfiguration {
    public var photoQuality: Float = 0.8
    public var videoQuality: UIImagePickerController.QualityType = .type640x480
    public var videoOutputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("AttachmentInput", isDirectory: true)
    public var fileSizeLimit: Int64 = 1024 * 1000 * 1000 // 1GB
    public var thumbnailSize = CGSize(width: 128 * UIScreen.main.scale , height:  128 * UIScreen.main.scale)
    public var photoCellCountLimit = 100
    public init() {}
}
