//
//  ObservableTypeExtension.swift
//  AttachmentInput
//
//  Created by minoru_kojima on 2018/02/22.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {
    /**
     Takes a sequence of optional elements and returns a sequence of non-optional elements, filtering out any nil values.
     - returns: An observable sequence of non-optional elements
     */
    public func unwrap<T>() -> Observable<T> where E == T? {
        return self.filter { $0 != nil }.map { $0! }
    }
}
