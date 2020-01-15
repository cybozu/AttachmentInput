//
//  ObservableTypeExtension.swift
//  AttachmentInput
//
//  Created by minoru_kojima on 2018/02/22.
//  Copyright © 2018 Cybozu, Inc. All rights reserved.
//

import Foundation
import RxSwift

public protocol Optionable {
    associatedtype Wrapped
    func flatMap<U>(_ transform: (Wrapped) throws -> U?) rethrows -> U?
    func map<U>(_ transform: (Wrapped) throws -> U) rethrows -> U?
}

extension Optional: Optionable {}

extension ObservableType where Element: Optionable {
    /**
    Takes a sequence of optional elements and returns a sequence of non-optional elements, filtering out any nil values.
    - returns: An observable sequence of non-optional elements
    */
    public func unwrap() -> Observable<Element.Wrapped> {
        return self
            .filter { $0.map { $0 } != nil } // filter{ Type? != nil }
            .map { ($0.map { $0 })! } // map{ (Type?)! }
    }
}
