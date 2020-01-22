//
//  ButtonAccessoryView.swift
//  Example
//
//  Created by daiki-matsumoto on 2019/02/06.
//  Copyright © 2019 cybozu. All rights reserved.
//

import UIKit

class ButtonAccessoryView: UIView {
    @IBOutlet weak var photoButton: UIButton!

    static func getView(target: UIViewController, action: Selector) -> ButtonAccessoryView? {
        let nib = UINib.init(nibName: "ButtonAccessoryView", bundle: nil)
        if let view = nib.instantiate(withOwner: self, options: nil).first as? ButtonAccessoryView {
            view.photoButton.addTarget(target, action: action, for: .touchUpInside)
            return view
        }
        return nil
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize.init(width: size.width, height: 46)
    }
    
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        self.invalidateIntrinsicContentSize()
    }
}
