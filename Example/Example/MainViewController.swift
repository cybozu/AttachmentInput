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

class MainViewController: UICollectionViewController {
    private let disposeBag = DisposeBag()
    private var attachmentInput: AttachmentInput!
    private var viewModel = MainViewModel()
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<MainViewController.SectionOfPhotoData>!
    private var bottomView: UIView!
    private var showInputView = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionView()
        self.setupAttachmentInput()
        self.setupBottomView()
    }

    override func viewDidAppear(_ animated: Bool) {
        if !self.isFirstResponder {
            self.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if self.isFirstResponder {
            self.resignFirstResponder()
        }
    }

    private func setupCollectionView() {
        self.collectionView?.delegate = nil
        self.collectionView?.dataSource = nil

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
        self.bottomView = ButtonAccessoryView.getView(target: self, action: #selector(toggleFirstResponder))
    }

    @objc func toggleFirstResponder() {
        if self.showInputView {
            self.showInputView = false
            self.reloadInputViews()
        } else {
            self.showInputView = true
            self.reloadInputViews()
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var inputAccessoryView: UIView? {
        if self.isFirstResponder {
            return self.bottomView
        } else {
            return nil
        }
    }

    override var inputView: UIView? {
        if self.isFirstResponder && self.showInputView {
            return self.attachmentInput.view
        } else {
            return nil
        }
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
