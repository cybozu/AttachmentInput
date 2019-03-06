//
//  BehaviorSubjectExtension.swift
//  AttachmentInput
//
//  Created by daiki-matsumoto on 2017/10/12.
//  Copyright © 2017 Cybozu, Inc. All rights reserved.
//

import Foundation
import RxSwift

extension BehaviorSubject {
    func value(_ defaultValue: Element) -> Element {
        return (try? self.value()) ?? defaultValue
    }
}
