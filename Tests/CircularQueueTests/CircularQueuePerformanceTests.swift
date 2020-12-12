//
//  CircularQueuePerformanceTests.swift
//  CircularQueueTests
//
//  Created by Valeriano Della Longa on 2020/12/11.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import XCTest
import CircularQueue

final class CircularQueuePerformanceTests: XCTestCase {
    var sut: (outerCount: Int, innerCount: Int)!
    
    func testCircularQueuePerformanceAtSmallCount() {
        whenSmallCount()
        measure { performanceLoop(for: .circularQueue) }
    }
    
    func testArrayPerformanceAtSmallCount() {
        whenSmallCount()
        measure { performanceLoop(for: .array) }
    }
    
    func testCircularQueuePerformanceAtLargeCount() {
        whenLargeCount()
        measure { performanceLoop(for: .circularQueue) }
    }
    
    func testArrayPerformanceAtLargeCount() {
        whenLargeCount()
        measure { performanceLoop(for: .array) }
    }
    
    // MARK: - Private helpers
    private func performanceLoopCircularQueueSmallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var queue = CircularQueue<Int>()
            queue.reserveCapacity(innerCount)
            for i in 1...innerCount {
                queue.enqueue(i)
                accumulator ^= (queue.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (queue.first ?? 0)
                queue.dequeue()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopArraySmallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var array = Array<Int>()
            array.reserveCapacity(innerCount)
            for i in 1...innerCount {
                array.append(i)
                accumulator ^= (array.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (array.first ?? 0)
                array.remove(at: 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopCircularQueueLargeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            var queue = CircularQueue<Int>()
            queue.reserveCapacity(innerCount)
            for i in 1...innerCount {
                queue.enqueue(i)
                accumulator ^= (queue.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (queue.first ?? 0)
                queue.dequeue()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopArrayLargeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            var array = Array<Int>()
            array.reserveCapacity(innerCount)
            for i in 1...innerCount {
                array.append(i)
                accumulator ^= (array.last ?? 0)
            }
            for _ in 1...innerCount {
                accumulator ^= (array.first ?? 0)
                array.remove(at: 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func whenSmallCount() {
        sut = (10_000, 20)
    }
    
    private func whenLargeCount() {
        sut = (10, 20_000)
    }
    
    private func performanceLoop(for kind: KindOfTestable) {
        var accumulator = 0
        for _ in 1...sut.outerCount {
            var testable = kind.newTestable(capacity: sut.innerCount)
            for i in 1...sut.innerCount {
                testable.enqueue(i)
                accumulator ^= (testable.last ?? 0)
            }
            for _ in 1...sut.innerCount {
                accumulator ^= (testable.first ?? 0)
                testable.dequeue()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private enum KindOfTestable {
        case circularQueue
        case array
        
        func newTestable(capacity: Int) -> PerformanceTestable {
            switch self {
            case .circularQueue:
                return CircularQueue<Int>(capacity: capacity)
            case .array:
                return Array<Int>(capacity: capacity)
            }
        }
    }
    
}

fileprivate protocol PerformanceTestable {
    init(capacity: Int)
    
    var first: Int? { get }
    
    var last: Int? { get }
    
    mutating func enqueue(_ newElement: Int)
    
    @discardableResult
    mutating func dequeue() -> Int?

}

extension CircularQueue: PerformanceTestable where Element == Int {
    init(capacity: Int) {
        self.init(capacity)
    }
    
}

extension Array: PerformanceTestable where Element == Int {
    init(capacity: Int) {
        self.init()
        reserveCapacity(capacity)
    }
    
    mutating func enqueue(_ newElement: Int) {
        guard count + 1 < capacity else {
            remove(at: 0)
            append(newElement)
            
            return
        }
        
        append(newElement)
    }
    
    mutating func dequeue() -> Int? {
        isEmpty ? nil : removeFirst()
    }
    
    
}
