//
//  MainViewModel.swift
//  Example
//
//  Created by daiki-matsumoto on 2018/08/17.
//  Copyright © 2018 Cybozu. All rights reserved.
//

import RxSwift

class MainViewModel {
    private let dataListSubject = BehaviorSubject<[PhotoData]>(value: [])
    private var dataListValue: [PhotoData] {
        let defaultValue = [PhotoData]()
        return (try? self.dataListSubject.value()) ?? defaultValue
    }

    let dataList: Observable<[PhotoData]>

    init() {
        self.dataList = self.dataListSubject.asObservable()
    }
    
    func addData(fileName: String, fileSize: Int64, fileId: String, imageThumbnail: Data?) {
        var image: UIImage?
        if let imageThumbnail = imageThumbnail {
            image = UIImage(data: imageThumbnail)
        } else {
            image = #imageLiteral(resourceName: "general-file-square")
        }
        let fileSizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: ByteCountFormatter.CountStyle.binary)
        let data = PhotoData(image: image, fileName: fileName, fileSize: fileSizeString, fileId: fileId)
        var newList = self.dataListValue
        newList.insert(data, at: 0)
        self.dataListSubject.onNext(newList)
    }
    
    func removeData(fileId: String) {
        let newList = self.dataListValue.filter({$0.fileId != fileId})
        self.dataListSubject.onNext(newList)
    }
}
