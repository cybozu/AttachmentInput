//
//  AttachmentInput.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/10/24.
//  Copyright © 2018 Cybozu. All rights reserved.
//

import Foundation
import UIKit
import RxDataSources
import RxSwift
import Photos
import MobileCoreServices

class AttachmentInputView: UIView {
    @IBOutlet private var collectionView: UICollectionView!
    
    private var dataSource: RxCollectionViewSectionedReloadDataSource<SectionType>!
    private let disposeBag = DisposeBag()
    private var logic: AttachmentInputViewLogic?
    private var initialized = false
    private var computedImagePickerCellSize = CGSize()
    private var computedCameraCellSize = CGSize()
    private var computedPhotoListCellSize = CGSize()
    
    fileprivate enum SectionType {
        case ImagePickerSection(items: [SectionItemType])
        case CameraSection(items: [SectionItemType])
        case PhotoListSection(items: [SectionItemType])
    }
    
    fileprivate enum SectionItemType {
        case ImagePickerItem
        case CameraItem
        case PhotoListItem(photo: AttachmentInputPhoto, status: AttachmentInputPhotoStatus)
    }
    
    public var delegate: AttachmentInputDelegate? {
        get {
            return self.logic?.delegate
        }
        set {
            self.logic?.delegate = newValue
        }
    }

    private var configuration: AttachmentInputConfiguration!

    static func createAttachmentInputView(configuration: AttachmentInputConfiguration) -> AttachmentInputView {
        let attachmentInputView = Bundle(for: self).loadNibNamed("AttachmentInputView", owner: self, options: nil)?.first as! AttachmentInputView
        attachmentInputView.configuration = configuration
        attachmentInputView.logic = AttachmentInputViewLogic(configuration: configuration)
        return attachmentInputView
    }
    
    private func initializeCollectionView() {
        let bundle = Bundle(for: self.classForCoder)
        self.collectionView.register(UINib(nibName: "ImagePickerCell", bundle: bundle), forCellWithReuseIdentifier: "ImagePickerCell")
        self.collectionView.register(UINib(nibName: "CameraCell", bundle: bundle), forCellWithReuseIdentifier: "CameraCell")
        self.collectionView.register(UINib(nibName: "PhotoCell", bundle: bundle), forCellWithReuseIdentifier: "PhotoCell")
        
        self.dataSource = RxCollectionViewSectionedReloadDataSource<SectionType>(configureCell: { (_, _, indexPath, item) -> UICollectionViewCell in
            switch item {
            case .ImagePickerItem:
                let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePickerCell", for: indexPath) as! ImagePickerCell
                cell.delegate = self
                cell.setup()
                return cell
            case .CameraItem:
                let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "CameraCell", for: indexPath) as! CameraCell
                cell.delegate = self
                cell.setup()
                return cell
            case .PhotoListItem(let photo, let status):
                let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
                cell.setup(photo: photo, status: status)
                return cell
            }
        })
        // Add picker control and camera section
        var ret = [SectionType]()
        ret.append(SectionType.ImagePickerSection(items: [SectionItemType.ImagePickerItem]))
        ret.append(SectionType.CameraSection(items: [SectionItemType.CameraItem]))
        let controllerObservable = Observable.just(ret)

        self.checkPhotoAuthorizationStatus { [weak self] authorized in
            if authorized {
                self?.fetchAssets()
            }
        }

        // show collectionView
        self.collectionView.delegate = self
        Observable<[SectionType]>.combineLatest(controllerObservable, self.logic!.photosWithStatus) { controller, output in
            let photoItems = output.map( { output in
                return SectionItemType.PhotoListItem(photo: output.photo, status: output.status)
            })
            return controller + [SectionType.PhotoListSection(items: photoItems)]
            }.bind(to: self.collectionView.rx.items(dataSource: self.dataSource)).disposed(by: self.disposeBag)
        
        // onTapPhotoCell
        self.collectionView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            if let item = self?.dataSource.sectionModels[indexPath.section].items[indexPath.item] {
                switch item {
                case .PhotoListItem(let photo, _):
                    self?.logic?.onTapPhotoCell(photo: photo)
                default:
                    // do nothing
                    break
                }
            }
        }).disposed(by: self.disposeBag)
    }

    private func checkPhotoAuthorizationStatus(completion: @escaping (_ authorized: Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch (status) {
        case .authorized:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                completion(status == .authorized)
            })
        @unknown default:
            fatalError()
        }
    }

    private func fetchAssets() {
        // postpone heavy processing to first display the keyboard
        DispatchQueue.main.async {
            // add Photos
            let photosOptions = PHFetchOptions()
            photosOptions.fetchLimit = self.configuration.photoCellCountLimit
            photosOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                                  PHAssetMediaType.image.rawValue,
                                                  PHAssetMediaType.video.rawValue)
            photosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.logic?.pHFetchResultObserver.onNext(PHAsset.fetchAssets(with: photosOptions))
        }
    }
    
    func initializeIfNeed() {
        guard !self.initialized else {
            return
        }
        self.initialized = true

        PHPhotoLibrary.shared().register(self)
        self.initializeCollectionView()
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillChangeFrameNotification).subscribe(onNext: { [weak self] _ in
            self?.keyboardWillChangeFrame()
        }).disposed(by: self.disposeBag)
    }
    
    func removeFile(identifier: String) {
        self.logic?.removeFile(identifier: identifier)
    }
    
    private func keyboardWillChangeFrame() {
        self.computeCellSize()
        self.collectionView.reloadData()
    }
    
    private func computeCellSize() {
        guard
            let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout
            else {
                fatalError()
        }
        let deviceOrientation = UIDevice.current.orientation
        let isLandscape = deviceOrientation.isLandscape
        // ImagePickerCell
        self.computedImagePickerCellSize = flowLayout.propotionalScaledSize(aspectRatio: (1, 2), numberOfRows: 1)
        // CameraCell
        if isLandscape {
            self.computedCameraCellSize = flowLayout.propotionalScaledSize(aspectRatio: (4, 3), numberOfRows: 1)
        } else {
            self.computedCameraCellSize = flowLayout.propotionalScaledSize(aspectRatio: (3, 4), numberOfRows: 1)
        }
        // PhotoCell
        self.computedPhotoListCellSize = flowLayout.propotionalScaledSize(aspectRatio: (1, 1), numberOfRows: 2)
    }
}

extension AttachmentInputView: ImagePickerCellDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // If you double tap a photo, it will be called many times
        // so check isBeingDismissed
        if picker.isBeingDismissed {
            return
        }
        
        if let phAsset = self.getPHAsset(didFinishPickingMediaWithInfo: info) {
            // When selecting from the photo library
            if let mediaType = info[.mediaType] as? String {
                if mediaType == kUTTypeImage as String {
                    self.logic?.onSelectPickerMedia(phAsset: phAsset, videoUrl: nil)
                } else if mediaType == kUTTypeMovie as String {
                    if let mediaUrl = info[.mediaURL] as? URL {
                        self.logic?.onSelectPickerMedia(phAsset: phAsset, videoUrl: mediaUrl)
                    }
                }
            }
        } else {
            // When took a picture
            if let image = info[.originalImage] as? UIImage {
                self.logic?.addNewImageAfterCompress(image: image)
            } else if let videoUrl = info[.mediaURL] as? URL {
                self.logic?.addNewVideo(url: videoUrl)
            }
        }
        
        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)
            self.delegate?.imagePickerControllerDidDismiss()
        }
    }
    
    private func getPHAsset(didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) -> PHAsset? {
        if #available(iOS 11.0, *) {
            return info[.phAsset] as? PHAsset
        } else {
            if let url = info[.referenceURL] as? URL {
                let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
                return fetchResult.firstObject
            }
        }
        return nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)
            self.delegate?.imagePickerControllerDidDismiss()
        }
    }
    
    var videoQuality: UIImagePickerController.QualityType {
        return self.configuration.videoQuality
    }
}

extension AttachmentInputView: CameraCellDelegate {
    func didTakePicture(imageData: Data) {
        self.logic?.addNewImage(data: imageData)
    }
    
    var photoQuality: Float {
        return self.configuration.photoQuality
    }
}

extension AttachmentInputView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            // ImagePickerCell
            return self.computedImagePickerCellSize
        } else if indexPath.section == 1 {
            // CameraCell
            return self.computedCameraCellSize
        } else if indexPath.section == 2 {
            // PhotoCell
            return self.computedPhotoListCellSize
        }
        fatalError()
    }
}

extension AttachmentInputView.SectionType: SectionModelType {
    typealias Item = AttachmentInputView.SectionItemType
    
    var items: [AttachmentInputView.SectionItemType] {
        switch self {
        case .ImagePickerSection(items: let items):
            return items.map {$0}
        case .CameraSection(items: let items):
            return items.map {$0}
        case .PhotoListSection(items: let items):
            return items.map {$0}
        }
    }
    
    init(original: AttachmentInputView.SectionType, items: [Item]) {
        switch original {
        case .ImagePickerSection:
            self = .ImagePickerSection(items: items)
        case .CameraSection:
            self = .CameraSection(items: items)
        case .PhotoListSection:
            self = .PhotoListSection(items: items)
        }
    }
}

extension AttachmentInputView: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            if let photosFetchResult = self.logic?.pHFetchResult, let changeDetails = changeInstance.changeDetails(for: photosFetchResult) {
                self.logic?.pHFetchResultObserver.onNext(changeDetails.fetchResultAfterChanges)
            }
        }
    }
}
