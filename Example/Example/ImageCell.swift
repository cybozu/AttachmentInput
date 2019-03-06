//
//  ImageCell.swift
//  Example
//
//  Created by daiki-matsumoto on 2018/08/17.
//  Copyright © 2018 Cybozu. All rights reserved.
//

import UIKit

protocol ImageCellDelegate: class {
    func tapedRemove(fileId: String)
}

class ImageCell: UICollectionViewCell {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var fileName: UILabel!
    @IBOutlet private var fileSize: UILabel!
    private var fileId: String = ""
    private weak var delegate: ImageCellDelegate?
    
    override func awakeFromNib() {
        self.imageView.layer.cornerRadius = 15
    }
    
    @IBAction func tapRemove() {
        self.delegate?.tapedRemove(fileId: self.fileId)
    }
    
    func setup(data: PhotoData, delegate: ImageCellDelegate?) {
        self.imageView.image = data.image
        self.fileName.text = data.fileName
        self.fileSize.text = data.fileSize
        self.fileId = data.fileId
        self.delegate = delegate
    }
}
