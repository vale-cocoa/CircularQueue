//
//  Helpers.swift
//  CircularQueueTests
//
//  Created by Valeriano Della Longa on 25/11/20.
//

import XCTest
@testable import CircularQueue

let testThrownError: NSError = NSError(domain: "com.vdl.circularStorage", code: 1, userInfo: nil)

protocol EquatableCollectionUsingID: Collection where Element: Equatable {
    var storage: CircularQueueStorage<Element> { get }
}

extension CircularQueue: EquatableCollectionUsingID where Element: Equatable { }

extension CircularQueueSlice: EquatableCollectionUsingID where Element: Equatable {
    var storage: CircularQueueStorage<Element> { base.storage }
}

func assertAreDifferentValuesAndHaveDifferentStorage<C: EquatableCollectionUsingID, D: EquatableCollectionUsingID>(lhs: C, rhs: D, file: StaticString = #file, line: UInt = #line) where C.Element == D.Element {
    XCTAssertFalse(lhs.elementsEqual(rhs), "copy contains same elements of original after mutation", file: file, line: line)
    XCTAssertFalse(lhs.storage === rhs.storage, "copy has same storage instance of original", file: file, line: line)
}
