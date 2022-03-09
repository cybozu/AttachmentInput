//
//  UICollectionViewFlowLayoutExtension.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2018/02/14.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionViewFlowLayout {
    /// Return recommended cell size for aspect ratio and number of rows
    /// @param aspectRatio (width:height)
    /// @param numberOfRows
    /// @return 1 cell size
    func propotionalScaledSize(aspectRatio: (width: Int, height: Int), numberOfRows: Int) -> CGSize {
        let height = self.preferredItemHeight(forNumberOfRows: numberOfRows)
        let width = CGFloat(aspectRatio.width) /  CGFloat(aspectRatio.height) * height
        return CGSize(width: width, height: height)
    }
    /// Returns the recommended height of items for the number of columns
    /// @param forNumberOfRows
    /// @return 1 cell height
    private func preferredItemHeight(forNumberOfRows: Int) -> CGFloat {
        guard forNumberOfRows > 0 else {
            return 0
        }
        guard let collectionView = self.collectionView else {
            fatalError()
        }
        
        let collectionViewHeight = collectionView.bounds.height
        let inset = self.sectionInset
        let spacing = self.minimumInteritemSpacing
        
        // Evenly divide the width excluding each margin from the width of the collection view
        return (collectionViewHeight - (inset.top + inset.bottom + spacing * CGFloat(forNumberOfRows - 1))) / CGFloat(forNumberOfRows)
    }
}
