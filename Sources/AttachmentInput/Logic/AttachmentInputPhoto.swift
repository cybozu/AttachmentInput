//
//  AttachmentInputPhoto.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/02/26.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import Photos

class AttachmentInputPhoto {
    private let disposeBag = DisposeBag()
    private var initialized: Bool = false
    private let thumbnailSubject = AsyncSubject<Data?>()
    private let propertiesSubject = AsyncSubject<PhotoProperties?>()
    private let uploadSizeLimit: Int64
    private let imageManager: PHImageManager

    // Output
    let asset: PHAsset
    let thumbnail: Observable<Data>
    let isVideo: Bool
    let identifier: String
    let properties: Observable<PhotoProperties>

    struct PhotoProperties {
        var filename: String
        var fileSize: Int64
        var exceededSizeLimit: Bool
    }

    /// @param asset: PHAsset
    /// @param uploadSizeLimit
    /// @param imageManager
    /// @return self or nil: Return nil if it is not a photo or video
    init?(asset: PHAsset, uploadSizeLimit: Int64, imageManager: PHImageManager) {
        if (asset.mediaType != .video && asset.mediaType != .image){
            return nil
        }

        self.asset = asset
        self.thumbnail = self.thumbnailSubject.unwrap().asObservable()
        self.properties = self.propertiesSubject.unwrap().asObservable()
        self.isVideo = (asset.mediaType == .video)
        self.identifier = asset.localIdentifier
        self.uploadSizeLimit = uploadSizeLimit
        self.imageManager = imageManager
    }
    
    func initializeIfNeed(loadThumbnail: Bool) {
        if self.initialized == true {
            return
        }
        self.initialized = true
        self.loadProperties(phAsset: asset)
        if loadThumbnail {
            let _ = self.loadThumbnail(photoSize: AttachmentInputViewLogic.PHOTO_TILE_THUMBNAIL_SIZE, resizeMode: .fast).take(1).bind(to: self.thumbnailSubject)
        }
    }
    
    func loadThumbnail(photoSize: CGSize, resizeMode: PHImageRequestOptionsResizeMode) -> Observable<Data?> {
        let dataSubject = AsyncSubject<Data?>()
        let option = PHImageRequestOptions()
        option.deliveryMode = .highQualityFormat
        option.resizeMode = resizeMode
        option.isSynchronous = false
        option.isNetworkAccessAllowed = true
        self.imageManager.requestImage(for: asset, targetSize: photoSize, contentMode: .aspectFill, options: option, resultHandler: { image, info in
            if let image = image {
                let data = image.jpegData(compressionQuality: 0.3) as Data?
                dataSubject.onNext(data)
                dataSubject.onCompleted()
            } else {
                dataSubject.onError(AttachmentInputError.thumbnailLoadFailed)
            }
        })
        return dataSubject.asObservable()
    }

    private static let serialDispatchQueue = DispatchQueue(label: "attachmentInputPhoto.dispatchqueue.serial")
    private func loadProperties(phAsset: PHAsset) {
        // get meta data
        // we acquire it asynchronously, Because "PHAssetResource.assetResources" are heavy
        AttachmentInputPhoto.serialDispatchQueue.async {
            var fileName: String = ""
            var sizeOnDisk: Int64 = 0
            let resources = PHAssetResource.assetResources(for: phAsset)
            let exceededSizeLimit: Bool
            if let resource = resources.first {
                let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
                sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
                fileName = resource.originalFilename
                if sizeOnDisk < self.uploadSizeLimit {
                    exceededSizeLimit = false
                } else {
                    exceededSizeLimit = true
                }
                self.propertiesSubject.onNext(PhotoProperties(
                    filename: fileName,
                    fileSize: sizeOnDisk,
                    exceededSizeLimit: exceededSizeLimit)
                )
                self.propertiesSubject.onCompleted()
                return
            }
            self.propertiesSubject.onError(AttachmentInputError.propertiesLoadFailed)
        }
    }
}
