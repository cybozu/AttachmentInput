//
//  MainViewController.swift
//  Example
//
//  Created by daiki-matsumoto on 2018/08/08.
//  Copyright © 2018 Cybozu. All rights reserved.
//

import UIKit
import AttachmentInput
import RxSwift
import RxDataSources
import TouchVisualizer

class MainViewController: UICollectionViewController {
    private let disposeBag = DisposeBag()
    private var attachmentInput: AttachmentInput!
    private var viewModel = MainViewModel()
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<MainViewController.SectionOfPhotoData>!
    private var bottomView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Visualizer.start()

        self.setupCollectionView()
        self.setupAttachmentInput()
        self.setupBottomView()
    }

    private func setupCollectionView() {
        self.collectionView?.delegate = nil
        self.collectionView?.dataSource = nil
        
        if #available(iOS 11.0, *) {
        } else {
            self.collectionView.contentInset.top = UIApplication.shared.statusBarFrame.size.height
        }

        self.dataSource = RxCollectionViewSectionedAnimatedDataSource<MainViewController.SectionOfPhotoData>(configureCell: {
            (_: CollectionViewSectionedDataSource<MainViewController.SectionOfPhotoData>, collectionView: UICollectionView, indexPath: IndexPath, item: PhotoData) in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
            cell.setup(data: item, delegate: self)
            return cell
        }, configureSupplementaryView: { _,_,_,_ in
            fatalError()
        })

        self.viewModel.dataList.map { data in
            var ret = [SectionOfPhotoData]()
            ret.append(SectionOfPhotoData.Photos(items: data))
            return ret
            }.bind(to: self.collectionView!.rx.items(dataSource: self.dataSource))
            .disposed(by: self.disposeBag)
    }

    private func setupAttachmentInput() {
        let config = AttachmentInputConfiguration()
        config.thumbnailSize = CGSize(width: 105 * UIScreen.main.scale, height: 105 * UIScreen.main.scale)
        self.attachmentInput = AttachmentInput(configuration: config)
        self.attachmentInput.delegate = self
    }

    private func setupBottomView() {
        self.bottomView = ButtonAccessoryView.getView(target: self, action: #selector(toggleFirstResponder), inputView: self.attachmentInput.view)

        // show BottomView
        self.becomeFirstResponder()

        // self.bottomView.resignFirstResponder is not call when dismiss the keyboard interactively
        NotificationCenter.default.rx
            .notification(UIResponder.keyboardDidHideNotification)
            .subscribe(onNext: { (_) in
                self.becomeFirstResponder()
            }).disposed(by: self.disposeBag)
    }

    @objc func toggleFirstResponder() {
        if self.bottomView.isFirstResponder {
            self.bottomView.resignFirstResponder()
        } else {
            self.bottomView.becomeFirstResponder()
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var inputAccessoryView: UIView? {
        return self.bottomView
    }

    enum SectionOfPhotoData {
        case Photos(items: [PhotoData])
    }
}

extension MainViewController: ImageCellDelegate {
    func tapedRemove(fileId: String) {
        self.attachmentInput.removeFile(identifier: fileId)
        self.viewModel.removeData(fileId: fileId)
    }
}

extension PhotoData: IdentifiableType {
    typealias Identity = String
    var identity: String {
        return self.fileId
    }
}

extension MainViewController.SectionOfPhotoData: AnimatableSectionModelType {
    typealias Item = PhotoData
    typealias Identity = String
    
    var identity: String {
        return "PhotoSection"
    }
    
    var items: [PhotoData] {
        switch self {
        case .Photos(items: let items):
            return items
        }
    }
    
    init(original: MainViewController.SectionOfPhotoData, items: [PhotoData]) {
        self = .Photos(items: items)
    }
}

extension MainViewController: AttachmentInputDelegate {
    func inputImage(imageData: Data, fileName: String, fileSize: Int64, fileId: String, imageThumbnail: Data?) {
        self.viewModel.addData(fileName: fileName, fileSize: fileSize, fileId: fileId, imageThumbnail: imageThumbnail)
    }
    
    func inputMedia(url: URL, fileName: String, fileSize: Int64, fileId: String, imageThumbnail: Data?) {
        self.viewModel.addData(fileName: fileName, fileSize: fileSize, fileId: fileId, imageThumbnail: imageThumbnail)
    }
    
    func removeFile(fileId: String) {
        self.viewModel.removeData(fileId: fileId)
    }
    
    func imagePickerControllerDidDismiss() {
        // Do nothing
    }
    
    func onError(error: Error) {
        let nserror = error as NSError
        if let attachmentInputError = error as? AttachmentInputError {
            print(attachmentInputError.debugDescription)
        } else {
            print(nserror.localizedDescription)
        }
    }
}
