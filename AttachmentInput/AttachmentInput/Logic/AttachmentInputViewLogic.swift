//
//  AttachmentInputViewLogic.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/02/28.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import Photos
import RxSwift

class AttachmentInputViewLogic {
    private static let PHOTO_TILE_THUMBNAIL_LENGTH: CGFloat = 128
    static let PHOTO_TILE_THUMBNAIL_SIZE = CGSize(width: PHOTO_TILE_THUMBNAIL_LENGTH * UIScreen.main.scale , height:  PHOTO_TILE_THUMBNAIL_LENGTH * UIScreen.main.scale)

    private let disposeBag = DisposeBag()
    // imageManager is "lazy" because display the permission dialog at the first use timing
    lazy private var imageManager = PHImageManager()
    private let configuration: AttachmentInputConfiguration
    private let pHFetchResultSubject = BehaviorSubject<PHFetchResult<PHAsset>?>(value: nil)
    private let photosWithStatusSubject = BehaviorSubject<[(photo: AttachmentInputPhoto, status: AttachmentInputPhotoStatus)]>(value: [])
    private let fileManager = FileManager.default
    
    // Status and Photos are managed separately
    // Because Photos is changed every time an image stored in the terminal is updated,
    // Status is not updated when changing files in the terminal
    private var statusDictionary: Dictionary<String, AttachmentInputPhotoStatus> = [:]

    weak var delegate: AttachmentInputDelegate?

    // input
    let pHFetchResultObserver: AnyObserver<PHFetchResult<PHAsset>?>
    
    // output
    var pHFetchResult: PHFetchResult<PHAsset>? {
        return self.pHFetchResultSubject.value(nil)
    }
    var photosWithStatus: Observable<[(photo: AttachmentInputPhoto, status: AttachmentInputPhotoStatus)]>
    
    init(configuration: AttachmentInputConfiguration) {
        self.configuration = configuration
        self.pHFetchResultObserver = self.pHFetchResultSubject.asObserver()
        self.photosWithStatus = self.photosWithStatusSubject.asObservable()
        self.pHFetchResultSubject.unwrap()
            .map { [weak self] fetchResult in
                return self?.loadPhotosWithStatus(pHFetchResult: fetchResult) ?? []
            }.subscribe(onNext: { [weak self] photosWithStatus in
                self?.photosWithStatusSubject.onNext(photosWithStatus)
            }).disposed(by: self.disposeBag)
    }
    
    func removeFile(identifier: String) {
        if self.statusDictionary[identifier]?.status != .unSelected {
            self.statusDictionary[identifier]?.input.onNext(.unSelected)
        }
    }

    func addNewImage(data: Data) {
        if let image = UIImage(data: data) {
            self.addNewImage(image: image, data: data)
        }
    }

    func addNewImageAfterCompress(image: UIImage) {
        if let imageData = AttachmentInputUtil.compressImage(image: image, photoQuality: self.configuration.photoQuality) {
            self.addNewImage(image: image, data: imageData)
        }
    }

    // Create file name and add photo
    private func addNewImage(image: UIImage, data: Data) {
        let fileSize = Int64(data.count)
        if self.configuration.fileSizeLimit <= fileSize {
            self.onError(error: AttachmentInputError.overLimitSize)
            return
        }
        let fileName = "image " + AttachmentInputUtil.datetimeForDisplay(from: Date()) + ".jpeg"
        let id = NSUUID().uuidString
        if let thumbnail = AttachmentInputUtil.resizeFill(image: image, size: AttachmentInputViewLogic.PHOTO_TILE_THUMBNAIL_SIZE) {
            self.inputImage(imageData: data, fileName: fileName, fileSize: fileSize, fileId: id, imageThumbnail: thumbnail.pngData())
        } else {
            self.inputImage(imageData: data, fileName: fileName, fileSize: fileSize, fileId: id, imageThumbnail: nil)
        }
    }

    // Create a file name and add a video
    func addNewVideo(url: URL) {
        let fileSize = AttachmentInputUtil.getSizeFromFileUrl(fileUrl: url) ?? 0
        if self.configuration.fileSizeLimit <= fileSize {
            self.onError(error: AttachmentInputError.overLimitSize)
            return
        }
        let fileName = "video " + AttachmentInputUtil.datetimeForDisplay(from: Date()) + ".MOV"
        let id = NSUUID().uuidString
        self.inputMedia(url: url, fileName: fileName, fileSize: fileSize, fileId: id, imageThumbnail: nil)
    }

    func onSelectPickerMedia(phAsset: PHAsset, videoUrl: URL?) {
        if let photo = AttachmentInputPhoto(asset: phAsset, uploadSizeLimit: self.configuration.fileSizeLimit, imageManager: self.imageManager) {
            photo.initializeIfNeed(loadThumbnail: false)
            _ = photo.properties.take(1).subscribe(onNext: { [weak self] properties in
                if properties.exceededSizeLimit {
                    self?.onError(error: AttachmentInputError.overLimitSize)
                    return
                }

                if let status = self?.statusDictionary[photo.identifier] {
                    if status.status != .unSelected {
                        // do nothing when inputting already or inputting
                        return
                    }
                    status.input.onNext(.selected)
                    if let videoUrl = videoUrl {
                        // Since the video is compressed on the premise that the video is called from the imagePickerController, there is no need to compress it
                        let fileSize = AttachmentInputUtil.getSizeFromFileUrl(fileUrl: videoUrl) ?? 0
                        self?.inputMedia(url: videoUrl, fileName: properties.filename, fileSize: fileSize, fileId: photo.identifier, imageThumbnail: nil)
                    } else {
                        self?.addImageAfterFetchAndCompress(photo: photo, fileName: properties.filename, status: status)
                    }
                } else {
                    self?.statusDictionary[photo.identifier] = AttachmentInputPhotoStatus()
                    self?.statusDictionary[photo.identifier]?.input.onNext(.selected)
                }
                }, onError: { [weak self] error in
                    self?.onError(error: error)
            })
        }
    }

    func onTapPhotoCell(photo: AttachmentInputPhoto) {
        _ = photo.properties.take(1).subscribe(onNext: { [weak self] properties in
            if properties.exceededSizeLimit {
                self?.onError(error: AttachmentInputError.overLimitSize)
                return
            }
            if let status = self?.statusDictionary[photo.identifier] {
                // Delete if already added
                if status.status == .selected {
                    self?.removeFile(fileId: photo.identifier)
                    status.input.onNext(.unSelected)
                    return
                }
                
                if status.status != .unSelected {
                    // do nothing when inputting already or inputting
                    return
                }

                if photo.isVideo {
                    self?.addVideoAfterFetchAndCompress(photo: photo, fileName: properties.filename, status: status)
                } else {
                    self?.addImageAfterFetchAndCompress(photo: photo, fileName: properties.filename, status: status)
                }
            }
        }, onError: { [weak self] error in
            self?.onError(error: error)
        })
    }

    private func addVideoAfterFetchAndCompress(photo: AttachmentInputPhoto, fileName: String, status: AttachmentInputPhotoStatus) {
        status.input.onNext(.loading)
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.progressHandler = { [weak self] (progress, error, stop, info) in
            // for debug print("progress: \(progress)")
            if let error = error {
                self?.onError(error: error)
                status.input.onNext(.unSelected)
            } else {
                status.input.onNext(.downloading)
            }
        }
        self.imageManager.requestAVAsset(forVideo: photo.asset, options: options, resultHandler: { (avAsset, avAudioMix, _) in
            if let avAsset = avAsset {
                try? self.fileManager.createDirectory(at: self.configuration.videoOutputDirectory, withIntermediateDirectories: true, attributes: nil)
                let fileUrl = self.configuration.videoOutputDirectory.appendingPathComponent(NSUUID().uuidString, isDirectory: false)
                status.input.onNext(.compressing)
                let (result, _) = AttachmentInputUtil.compressVideo(avAsset: avAsset, outputUrl: fileUrl, videoQuality: self.configuration.videoQuality)
                let _ = result.subscribe(onNext: { [weak self] _ in
                    if let fileSizeLimit = self?.configuration.fileSizeLimit {
                        let fileName = AttachmentInputUtil.addFilenameExtension(fileName: fileName, extensionString: "MOV")
                        let fileSize = AttachmentInputUtil.getSizeFromFileUrl(fileUrl: fileUrl) ?? 0
                        if fileSizeLimit <= fileSize {
                            self?.onError(error: AttachmentInputError.overLimitSize)
                            status.input.onNext(.unSelected)
                            return
                        }
                        self?.inputMedia(url: fileUrl, fileName: fileName, fileSize: fileSize, fileId: photo.identifier, imageThumbnail: nil)
                        status.input.onNext(.selected)
                    } else {
                        self?.onError(error: AttachmentInputError.compressVideoFailed)
                        status.input.onNext(.unSelected)
                    }
                }, onError: { error in
                    self.onError(error: error)
                    status.input.onNext(.unSelected)
                })
            }
        })
    }

    private func addImageAfterFetchAndCompress(photo: AttachmentInputPhoto, fileName: String, status: AttachmentInputPhotoStatus) {
        status.input.onNext(.loading)
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.progressHandler = { [weak self] (progress, error, stop, info) in
            // for debug print("progress: \(progress)")
            if let error = error {
                self?.onError(error: error)
                status.input.onNext(.unSelected)
            } else {
                status.input.onNext(.downloading)
            }
        }
        self.imageManager.requestImageData(for: photo.asset, options: options, resultHandler: { (imageData, _, _, _) in
            if let imageData = imageData, let image = UIImage(data: imageData) {
                // compress image
                if let compressedData = AttachmentInputUtil.compressImage(image: image, photoQuality: self.configuration.photoQuality) {
                    let fileSize = Int64(compressedData.count)
                    if self.configuration.fileSizeLimit <= fileSize {
                        self.onError(error: AttachmentInputError.overLimitSize)
                        status.input.onNext(.unSelected)
                        return
                    }

                    // get thumbnail
                    var disposable: Disposable?
                    disposable = photo.loadThumbnail(photoSize: self.configuration.thumbnailSize, resizeMode: .exact).subscribe(onNext: { [weak self] imageThumbnail in
                        let jpegFileName = AttachmentInputUtil.addFilenameExtension(fileName: fileName, extensionString: "jpeg")
                        self?.inputImage(imageData: compressedData, fileName: jpegFileName, fileSize: fileSize, fileId: photo.identifier, imageThumbnail: imageThumbnail)
                        status.input.onNext(.selected)
                        disposable?.dispose()
                    }, onError: { error in
                        self.onError(error: error)
                        status.input.onNext(.unSelected)
                    })
                } else {
                    self.onError(error: AttachmentInputError.compressImageFailed)
                    status.input.onNext(.unSelected)
                }
            } else {
                self.onError(error: AttachmentInputError.compressImageFailed)
                status.input.onNext(.unSelected)
            }
        })
    }

    private func loadPhotosWithStatus(pHFetchResult: PHFetchResult<PHAsset>) -> [(AttachmentInputPhoto, AttachmentInputPhotoStatus)] {
        var items = [(AttachmentInputPhoto, AttachmentInputPhotoStatus)]()
        if 0 < pHFetchResult.count {
            let indexSet = IndexSet(integersIn: 0..<pHFetchResult.count)
            let photosItems = pHFetchResult.objects(at: indexSet)
            photosItems.forEach({ asset in
                if let photo = AttachmentInputPhoto(asset: asset, uploadSizeLimit: self.configuration.fileSizeLimit, imageManager: self.imageManager) {
                    // The photo is newly created every time
                    // but Status is reused if it is already stored
                    if self.statusDictionary[asset.localIdentifier] == nil {
                        self.statusDictionary[asset.localIdentifier] = AttachmentInputPhotoStatus()
                    }
                    items.append((photo, self.statusDictionary[asset.localIdentifier]!))
                }
            })
        }
        return items
    }
}


// Extensions for running Callback on main thread
extension AttachmentInputViewLogic {
    private func inputImage(imageData: Data, fileName: String, fileSize: Int64, fileId: String, imageThumbnail: Data?) {
        DispatchQueue.main.async {
            self.delegate?.inputImage(imageData: imageData, fileName: fileName, fileSize: fileSize, fileId: fileId, imageThumbnail: imageThumbnail)
        }
    }
    
    private func inputMedia(url: URL, fileName: String, fileSize: Int64, fileId: String, imageThumbnail: Data?) {
        DispatchQueue.main.async {
            self.delegate?.inputMedia(url: url, fileName: fileName, fileSize: fileSize, fileId: fileId, imageThumbnail: imageThumbnail)
        }
    }
    
    private func removeFile(fileId: String) {
        DispatchQueue.main.async {
            self.delegate?.removeFile(fileId: fileId)
        }
    }
    
    private func onError(error: Error) {
        DispatchQueue.main.async {
            self.delegate?.onError(error: error)
        }
    }
}
