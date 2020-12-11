//
//  CircularQueueTests.swift
//  CircularQueueTests
//
//  Created by Valeriano Della Longa on 2020/11/15.
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
@testable import CircularQueue
@testable import Queue

final class CircularQueueTests: XCTestCase {
    var sut: CircularQueue<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularQueue.init()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialize tests
    func testInit() {
        sut = CircularQueue()
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
    }
    
    func testInitCapacity() {
        // when capacity is equal to zero
        sut = CircularQueue(0)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        
        // when capacity is greater than zero
        for k in 1...10 {
            sut = CircularQueue(k)
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.storage)
            XCTAssertEqual(sut.capacity, k)
            XCTAssertEqual(sut.count, 0)
        }
    }
    
    func testInitSequence() {
        // when sequence is empty:
        var elements: Array<Int> = []
        sut = CircularQueue(elements)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.elementsEqual(elements))
        
        //  when sequence is not empty:
        elements = [1, 2, 3, 4, 5]
        sut = CircularQueue(elements)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.capacity, elements.count)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertTrue(sut.elementsEqual(elements))
        
        // when sequence is another CircularQueue:
        var other = CircularQueue([6, 7, 8, 9, 10])
        sut = CircularQueue(other)
        XCTAssertEqual(sut.capacity, other.capacity)
        XCTAssertTrue(sut.storage === other.storage)
        
        // …since we are storing the other's storage, let's check that
        // C.O.W. when mutating:
        other.dequeue()
        assertValueSemantics(other)
    }
    
    func testInitRepeatingValue() {
        // when count is zero:
        sut = CircularQueue(repeating: 1, count: 0)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        
        // when count is greater than zero:
        let repElement = Int.random(in: 1...100)
        let count = Int.random(in: 1...10)
        let expectedResult = Array(repeating: repElement, count: count)
        sut = CircularQueue(repeating: repElement, count: count)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.capacity, count)
        XCTAssertEqual(sut.count, count)
        XCTAssertTrue(sut.elementsEqual(expectedResult))
    }
    
    func testInitFromArrayLiteral() {
        sut = [1, 2, 3, 4, 5]
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.elementsEqual([1, 2, 3, 4, 5]))
        
        sut = []
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
    }
    
    // MARK: - Computed properties tests
    func testResidualCapacity() {
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        
        sut = CircularQueue(1...5)
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        
        XCTAssertNotNil(sut.popBack())
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
    }
    
    func testIsFull() {
        XCTAssertEqual(sut.isFull, sut.capacity == sut.count)
        
        sut = CircularQueue(1...5)
        XCTAssertEqual(sut.isFull, sut.capacity == sut.count)
        
        XCTAssertNotNil(sut.popBack())
        XCTAssertEqual(sut.isFull, sut.capacity == sut.count)
    }
    
    // MARK: Collection, BidirectionalCollection, MutableCollection, RandomAccessCollection tests
    // MARK: - Index tests
    func testIndex() {
        // startIndex, endIndex
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.startIndex, 0)
        XCTAssertEqual(sut.startIndex, sut.endIndex)
        XCTAssertEqual(sut.endIndex, sut.count)
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.startIndex, 0)
        XCTAssertGreaterThan(sut.endIndex, sut.startIndex)
        XCTAssertEqual(sut.endIndex, sut.count)
        
        // index(after:), index(before:),
        //formIndex(after:), formIndexBefore(:)
        var idx = sut.startIndex
        let nextIdx = sut.index(after: idx)
        XCTAssertGreaterThan(nextIdx, idx)
        XCTAssertEqual(nextIdx, idx + 1)
        
        sut.formIndex(after: &idx)
        XCTAssertEqual(idx, nextIdx)
        let beforeIdx = sut.index(before: idx)
        XCTAssertLessThan(beforeIdx, idx)
        XCTAssertEqual(beforeIdx, idx - 1)
        
        sut.formIndex(before: &idx)
        XCTAssertEqual(idx, beforeIdx)
        XCTAssertLessThan(idx, nextIdx)
        
        // index(_:, offsetBy:)
        let offsetBy3 = sut.index(sut.startIndex, offsetBy: 3)
        idx = sut.startIndex
        for _ in 1...3 {
            sut.formIndex(after: &idx)
        }
        XCTAssertEqual(offsetBy3, idx)
        
        let offsetByNegative3 = sut.index(sut.endIndex, offsetBy: -3)
        idx = sut.endIndex
        for _ in 1...3 {
            sut.formIndex(before: &idx)
        }
        XCTAssertEqual(offsetByNegative3, idx)
        
        // index(:_, offsetBy:, limitedBy:)
        let offsetByCountPlusOne = sut.index(sut.startIndex, offsetBy: (sut.count + 1), limitedBy: sut.endIndex)
        XCTAssertNil(offsetByCountPlusOne)
        
        let offsetByNegativeCountPlusOne = sut.index(sut.endIndex, offsetBy: -(sut.count + 1), limitedBy: sut.startIndex)
        XCTAssertNil(offsetByNegativeCountPlusOne)
        
        let limitedByEndIndex = sut.index(sut.startIndex, offsetBy: sut.count, limitedBy: sut.endIndex)
        XCTAssertNotNil(limitedByEndIndex)
        XCTAssertEqual(limitedByEndIndex, sut.index(sut.startIndex, offsetBy: sut.count))
        
        let limitedByStartIndex = sut.index(sut.endIndex, offsetBy: -sut.count, limitedBy: sut.startIndex)
        XCTAssertNotNil(limitedByStartIndex)
        XCTAssertEqual(limitedByStartIndex, sut.index(sut.endIndex, offsetBy: -sut.count))
        
        // distance(from:to:)
        XCTAssertGreaterThan(sut.endIndex, sut.startIndex)
        XCTAssertEqual(sut.distance(from: sut.startIndex, to: sut.endIndex), sut.count)
        XCTAssertGreaterThan(sut.distance(from: sut.startIndex, to: sut.endIndex), 0)
        
        XCTAssertGreaterThan(sut.endIndex, sut.startIndex)
        XCTAssertEqual(sut.distance(from: sut.endIndex, to: sut.startIndex), -sut.count)
        XCTAssertLessThan(sut.distance(from: sut.endIndex, to: sut.startIndex), 0)
        
        XCTAssertEqual(sut.distance(from: sut.startIndex, to: sut.startIndex), 0)
        XCTAssertEqual(sut.distance(from: sut.endIndex, to: sut.endIndex), 0)
        
        let midIdx = sut.endIndex / 2
        XCTAssertEqual(sut.distance(from: midIdx, to: sut.index(after: midIdx)), 1)
        XCTAssertEqual(sut.distance(from: midIdx, to: sut.index(before: midIdx)), -1)
    }
    
    // MARK: - subscripts tests
    func testSubscriptIndex() {
        sut = [1, 2, 3, 4, 5]
        XCTAssertEqual(sut[0], sut.first)
        XCTAssertEqual(sut[sut.count - 1], sut.last)
        for idx in 0..<sut.count {
            let expectedValue = idx + 1
            XCTAssertEqual(sut[idx], expectedValue)
            
            sut[idx] = expectedValue + 10
            XCTAssertEqual(sut[idx], expectedValue + 10)
        }
        
        // value semantics:
        var copy = sut!
        for idx in copy.startIndex..<copy.endIndex {
            copy[idx] -= 10
            XCTAssertNotEqual(sut[idx], copy[idx])
        }
        assertValueSemantics(copy)
    }
    
    func testSubscriptRange() {
        sut = [1, 2, 3, 4, 5]
        
        let slice = sut[1...3]
        for idx in slice.startIndex..<slice.endIndex {
            XCTAssertEqual(slice[idx], sut[idx])
        }
        
        var mutSlice = sut[1...3]
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            mutSlice[idx] += 10
        }
        
        sut[1...3] = mutSlice
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            XCTAssertEqual(sut[idx], mutSlice[idx])
        }
        
        // Value semantics:
        // sut was mutated after first slice was extracted, therefore:
        for idx in slice.startIndex..<slice.endIndex {
            XCTAssertNotEqual(slice[idx], sut[idx])
        }
        XCTAssertFalse(sut.storage === slice.base.storage)
        
        // Let's also check when mutating a slice:
        sut = [1, 2, 3, 4, 5]
        mutSlice = sut[1...3]
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            mutSlice[idx] += 10
        }
        
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            XCTAssertNotEqual(mutSlice[idx], sut[idx])
        }
        XCTAssertFalse(sut.storage === mutSlice.base.storage)
    }
    
    func testIsEmpty() {
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertFalse(sut.isEmpty)
        
        while let _ = sut.dequeue() { }
        XCTAssertTrue(sut.isEmpty)
        
        sut.enqueue(10)
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testCountAndUnderestimatedCount() {
        var expectedResult = 0
        for _ in sut { expectedResult += 1 }
        
        XCTAssertEqual(sut.count, expectedResult)
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        
        expectedResult = 0
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueue(elements)
        for _ in sut { expectedResult += 1 }
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.count, expectedResult)
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        
        expectedResult = 0
        var prevCount = sut.count
        XCTAssertNotNil(sut.dequeue())
        for _ in sut { expectedResult += 1 }
        XCTAssertEqual(sut.count, prevCount - 1)
        XCTAssertEqual(sut.count, expectedResult)
        XCTAssertEqual(sut.underestimatedCount, sut.count)
        
        expectedResult = 0
        prevCount = sut.count
        sut.enqueue(10)
        for _ in sut { expectedResult += 1 }
        XCTAssertEqual(sut.count, prevCount + 1)
        XCTAssertEqual(sut.count, expectedResult)
        XCTAssertEqual(sut.underestimatedCount, sut.count)
    }
    
    func testFirst() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.first)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = [1]
        XCTAssertEqual(sut.first, 1)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = [1, 2, 3]
        XCTAssertEqual(sut.first, 1)
        XCTAssertGreaterThan(sut.count, 1)
        XCTAssertNotEqual(sut.first, sut.last)
    }
    
    func testLast() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.first)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = [1]
        XCTAssertEqual(sut.last, 1)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = [1, 2, 3]
        XCTAssertEqual(sut.last, 3)
        XCTAssertGreaterThan(sut.count, 1)
        XCTAssertNotEqual(sut.first, sut.last)
    }
    
    // MARK: - withContiguousMutableStorageIfAvailable(_:) and withContiguousStorageIfAvailable(_:) tests
    func testWithContiguousMutableStorageIfAvailable() {
        XCTAssertTrue(sut.isEmpty)
        let exp1 = expectation(description: "closure completes")
        let result1: Bool? = sut.withContiguousMutableStorageIfAvailable { _ in
            exp1.fulfill()
            
            return true
        }
        wait(for: [exp1], timeout: 1)
        XCTAssertNotNil(result1)
        
        sut = [1, 2, 3, 4, 5]
        let expectedResult1 = [10, 20, 30, 40, 50]
        let exp2 = expectation(description: "closure completes")
        let result2: Bool? = sut.withContiguousMutableStorageIfAvailable { buff in
            for i in buff.startIndex..<buff.endIndex {
                buff[i] *= 10
            }
            exp2.fulfill()
            
            return true
        }
        wait(for: [exp2], timeout: 1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(Array(sut), expectedResult1)
        
        // value semantics:
        var copy = sut!
        let exp3 = expectation(description: "closure completes")
        copy.withContiguousMutableStorageIfAvailable { buffer in
            exp3.fulfill()
            for i in buffer.startIndex..<buffer.endIndex {
                buffer[i] /= 10
            }
        }
        wait(for: [exp3], timeout: 1)
        assertValueSemantics(copy)
        
        // Slice implementation works too:
        sut = CircularQueue(1...10)
        var slice = sut[1...3]
        var sliceBuffElements: Array<Int>!
        let exp4 = expectation(description: "closure completes")
        let result4 = slice.withContiguousMutableStorageIfAvailable { buff -> Bool in
            defer { exp4.fulfill() }
            sliceBuffElements = []
            for i in buff.startIndex..<buff.endIndex {
                buff[i] *= 10
                sliceBuffElements.append(buff[i])
            }
            
            return true
        }
        wait(for: [exp4], timeout: 0.1)
        XCTAssertNotNil(result4)
        XCTAssertEqual(sliceBuffElements, Array(slice))
        
        // value semantics on Slice:
        XCTAssertNotEqual(sut, slice.base)
    }
    
    func testWithContiguousStorageIfAvailable() {
        XCTAssertTrue(sut.isEmpty)
        let exp1 = expectation(description: "closure completes")
        let result1: Bool? = sut.withContiguousStorageIfAvailable { _ in
            exp1.fulfill()
            
            return true
        }
        wait(for: [exp1], timeout: 1)
        XCTAssertNotNil(result1)
        
        sut = [1, 2, 3, 4, 5]
        let exp2 = expectation(description: "closure completes")
        let rangeToPick = 1...3
        var copiedValues = [Int]()
        let result2: Bool? = sut.withContiguousStorageIfAvailable { buff in
            for i in rangeToPick {
                copiedValues.append(buff[i])
            }
            exp2.fulfill()
            
            return true
        }
        wait(for: [exp2], timeout: 1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(copiedValues, Array(sut[rangeToPick]))
        
        // Slice implementation works too:
        sut = CircularQueue(1...10)
        let slice = sut[1...3]
        var sliceBuffElements: Array<Int>!
        let exp4 = expectation(description: "closure completes")
        let result3 = slice.withContiguousStorageIfAvailable { buff -> Bool in
            defer { exp4.fulfill() }
            sliceBuffElements = Array(buff)
            
            return true
        }
        wait(for: [exp4], timeout: 0.1)
        XCTAssertNotNil(result3)
        XCTAssertEqual(sliceBuffElements, Array(slice))
    }
    
    // MARK: - Functional Programming methods
    func testAllSatisfy() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertTrue(sut.allSatisfy { $0 == 10 })
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertFalse(sut.allSatisfy { $0 == 10 })
        XCTAssertTrue(sut.allSatisfy { $0 <= 5 })
        
        let throwingPred: (Int) throws -> Bool = { _ in
            throw testThrownError
        }
        XCTAssertThrowsError(try sut.allSatisfy(throwingPred))
        
        do {
            let _ = try sut.allSatisfy(throwingPred)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testForEach() {
        XCTAssertTrue(sut.isEmpty)
        var result = [Int]()
        sut.forEach { result.append($0) }
        XCTAssertEqual(result, [])
        
        sut = [1, 2, 3, 4, 5]
        result = []
        sut.forEach { result.append($0 * 10) }
        XCTAssertEqual(result, [10, 20, 30, 40 ,50])
    }
    
    func testFilter() {
        XCTAssertTrue(sut.isEmpty)
        var result = [Int]()
        result = sut.filter { $0 > 1 }
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        result = sut.filter { $0 % 2 == 0 }
        XCTAssertEqual(result, [2, 4])
        
        let throwingPred: (Int) throws -> Bool = { _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(try sut.filter(throwingPred))
        do {
            let _ = try sut.filter(throwingPred)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testMap() {
        XCTAssertTrue(sut.isEmpty)
        var result: [String] = sut.map { String($0) }
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        result = sut.map { String($0) }
        XCTAssertEqual(result.count, sut.count)
        XCTAssertEqual(result, ["1", "2", "3", "4", "5"])
        
        let throwingTransform: (Int) throws -> String = { _ in
            throw testThrownError
        }
        XCTAssertThrowsError(result = try sut.map(throwingTransform))
        
        do {
            let _ = try sut.map(throwingTransform)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testFlatMap() {
        XCTAssertTrue(sut.isEmpty)
        var result: [Int] = sut.flatMap {
            return [$0 * 10, $0 * 100, $0 * 1000]
        }
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        result = sut.flatMap {
            return [$0 * 10, $0 * 100, $0 * 1000]
        }
        var expectedResult: [Int] = []
        for element in sut {
            let iterResult = [element * 10, element * 100, element * 1000]
            expectedResult.append(contentsOf: iterResult)
        }
        XCTAssertEqual(result, expectedResult)
        
        let throwingTransform: (Int) throws -> [Int] = { _ in
            throw testThrownError
        }
        XCTAssertThrowsError(result = try sut.flatMap(throwingTransform))
        
        do {
            let _ = try sut.flatMap(throwingTransform)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testCompactMap() {
        XCTAssertTrue(sut.isEmpty)
        var result: [Int] = sut.compactMap { return $0 % 2 == 0 ? $0 : nil }
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        result = sut.compactMap { return $0 % 2 == 0 ? $0 : nil }
        XCTAssertEqual(result, [2, 4])
        
        let throwingTransform: (Int) throws -> Int? = { _ in
            throw testThrownError
        }
        XCTAssertThrowsError(result = try sut.compactMap(throwingTransform))
        
        do {
            let _ = try sut.compactMap(throwingTransform)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testReduce() {
        XCTAssertTrue(sut.isEmpty)
        var result: Int = sut.reduce(0, +)
        XCTAssertEqual(result, 0)
        
        sut = [1, 2, 3, 4, 5]
        result = sut.reduce(0, +)
        XCTAssertEqual(result, 0 + 1 + 2 + 3 + 4 + 5)
        
        let throwingUpdateAccumulatingResult: (Int, Int) throws -> Int = { _, _ in
            throw testThrownError
        }
        XCTAssertThrowsError(result = try sut.reduce(0, throwingUpdateAccumulatingResult))
        
        do {
            let _ = try sut.reduce(0, throwingUpdateAccumulatingResult)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    // MARK: - RangeReplaceableCollection tests
    func testReserveCapacity() {
        sut.reserveCapacity(20)
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, 20)
        
        // when there are already enough free spots to cover it,
        // buffer doesn't get reallocated:
        sut.pushBack(contentsOf: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        let prevResidualCapacity = sut.residualCapacity
        XCTAssertGreaterThanOrEqual(prevResidualCapacity, 0)
        let prevStorage = sut.storage
        sut.reserveCapacity(prevResidualCapacity)
        XCTAssertTrue(sut.storage === prevStorage)
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, prevResidualCapacity)
        
        // otherwise buffer gets reallocated to a bigger one:
        let prevElements = sut.storage.withUnsafeBufferPointer { Array($0) }
        sut.reserveCapacity(prevResidualCapacity + 1)
        XCTAssertFalse(sut.storage === prevStorage)
        XCTAssertEqual(sut.residualCapacity, prevResidualCapacity + 1)
        XCTAssertTrue(sut.elementsEqual(prevElements))
    }
    
    func testReplaceSubrange() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // Let's test for value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.replaceSubrange(copy.startIndex..., with: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
        assertValueSemantics(copy)
    }
    
    func testAppendElement() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        var copy = sut!
        copy.append(1)
        assertValueSemantics(copy)
    }
    
    func testAppendContentsOfSequence() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        var copy = sut!
        copy.append(contentsOf: [1, 2, 3, 4, 5])
        assertValueSemantics(copy)
    }
    
    func testInsertElementAt() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.insert(0, at: 0)
        assertValueSemantics(copy)
    }
    
    func testInsertCollectionAt() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.insert(contentsOf: [10, 20, 30, 40, 50], at: 1)
        assertValueSemantics(copy)
    }
    
    func testRemoveElementAt() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        let _ = copy.remove(at: 1)
        assertValueSemantics(copy)
    }
    
    func testRemoveSubrange() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.removeSubrange(copy.startIndex..<copy.index(before: sut.endIndex))
        assertValueSemantics(copy)
    }
    
    func testRemoveFirstElement() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        let _ = copy.removeFirst()
        assertValueSemantics(copy)
    }
    
    func testRemoveFirstKElements() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.removeFirst(2)
        assertValueSemantics(copy)
    }
    
    func testRemoveAllKeepingCapacity() {
        var prevCapacity = sut.capacity
        sut.removeAll(keepingCapacity: true)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        sut = [1, 2, 3, 4, 5]
        prevCapacity = sut.capacity
        sut.removeAll(keepingCapacity: true)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        sut = [1, 2, 3, 4, 5]
        prevCapacity = sut.capacity
        sut.removeAll(keepingCapacity: false)
        XCTAssertNotEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, 0)
    }
    
    func testPopLast() {
        var elements = [1, 2, 3, 4, 5]
        sut = CircularQueue(elements)
        for _ in 0..<elements.count {
            XCTAssertEqual(sut.popLast(), elements.popLast())
            XCTAssertTrue(sut.elementsEqual(elements))
        }
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.popLast()
        assertValueSemantics(copy)
    }
    
    func testPopFirst() {
        var elements = [1, 2, 3, 4, 5]
        sut = CircularQueue(elements)
        for _ in 0..<elements.count {
            XCTAssertEqual(sut.popFirst(), elements.remove(at: 0))
            XCTAssertTrue(sut.elementsEqual(elements))
        }
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.popFirst()
        assertValueSemantics(copy)
    }
    
    func testRemoveLastElement() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        let _ = copy.removeLast()
        assertValueSemantics(copy)
    }
    
    func testRemoveLastKElements() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.removeLast(2)
        assertValueSemantics(copy)
    }
    
    // MARK: - Specific CircularQueue methods tests
    func testPopFront() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.popFront()
        assertValueSemantics(copy)
    }
    
    func testPushFrontNewElement() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        sut = [1 ,2, 3, 4, 5]
        var copy = sut!
        copy.pushFront(1000)
        assertValueSemantics(copy)
    }
    
    
    func testPushFrontSequence() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.pushFront(contentsOf: [10, 20, 30, 40])
        assertValueSemantics(copy)
    }
    
    func testPopBack() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.popBack()
        assertValueSemantics(copy)
    }
    
    func testPushBackNewElement() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.pushBack(1000)
        assertValueSemantics(copy)
    }
    
    func testPushBackSequence() {
        // Leverages on CircularBuffer thus it is guaranteed
        // by CircularBufferTests.
        
        // let's test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.pushBack(contentsOf: [10, 20, 30, 40])
        assertValueSemantics(copy)
    }
    
    // MARK: - Queue conformance tests
    func testPeek() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.peek(), sut.first)
        XCTAssertNil(sut.peek())
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertEqual(sut.peek(), sut.first)
        XCTAssertNotNil(sut.peek())
        
        sut.pushFront(0)
        XCTAssertEqual(sut.peek(), sut.first)
        XCTAssertNotNil(sut.peek())
    }
    
    func testEnqueueElement() {
        // since enqueue(_:) just wraps pushBack(_:), we'll only do basic tests:
        sut.reserveCapacity(5)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        sut.enqueue(10)
        XCTAssertEqual(sut.last, 10)
        
        // test value semantics:
        var copy = sut!
        copy.enqueue(11)
        assertValueSemantics(copy)
    }
    
    func testEnqueueSequence() {
        // since enqueue(contentsOf:) wraps pushBack(contentsOf:),
        //we'll only do basic tests:
        sut.reserveCapacity(5)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        sut.enqueue(contentsOf: [1, 2, 3, 4, 5])
        XCTAssertTrue(sut.elementsEqual([1, 2, 3, 4, 5]))
        
        // test value semantics:
        var copy = sut!
        copy.enqueue(contentsOf: [10, 20, 30, 40, 50])
        assertValueSemantics(copy)
    }
    
    // MARK: - Equatable and Hashable conformance tests
    func testEquatable() {
        XCTAssertEqual(sut, CircularQueue<Int>())
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertNotEqual(sut, CircularQueue<Int>())
        
        var other = sut!
        XCTAssertTrue(sut.storage === other.storage)
        XCTAssertEqual(sut, other)
        
        sut.pushBack(10)
        XCTAssertNotEqual(sut, other)
        
        other.pushBack(10)
        XCTAssertFalse(sut.storage === other.storage)
        XCTAssertEqual(sut.count, other.count)
        for idx in 0..<sut.count {
            XCTAssertEqual(sut[idx], other[idx])
        }
        XCTAssertEqual(sut, other)
        
        other.reserveCapacity(5)
        XCTAssertNotEqual(sut.capacity, other.capacity)
        XCTAssertEqual(sut, other)
        
        other[other.endIndex - 1] = 1000
        XCTAssertEqual(sut.count, other.count)
        var indexesWhereDifferent = [Int]()
        for idx in 0..<sut.count where sut[idx] != other[idx] {
            indexesWhereDifferent.append(idx)
        }
        XCTAssertFalse(indexesWhereDifferent.isEmpty)
        XCTAssertNotEqual(sut, other)
    }
    
    func testHashable() {
        var set = Set<CircularQueue<Int>>()
        set.insert(sut)
        XCTAssertTrue(set.contains(sut))
        
        var copy = sut!
        let (inserted, _) = set.insert(copy)
        XCTAssertFalse(inserted)
        
        copy.append(1)
        let afterMutation = set.insert(copy)
        XCTAssertTrue(afterMutation.inserted)
        XCTAssertTrue(afterMutation.memberAfterInsert.storage === copy.storage)
        XCTAssertEqual(afterMutation.memberAfterInsert.hashValue, copy.hashValue)
    }
    
    // MARK: - Codable conformance
    func testEncode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(sut))
    }
    
    func testDecode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(sut)
        
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(CircularQueue<Int>.self, from: data))
    }
    
    func testEncodeThanDecode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(sut)
        
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(CircularQueue<Int>.self, from: data)
        XCTAssertEqual(decoded, sut)
        XCTAssertEqual(decoded.capacity, sut.capacity)
    }
    
    // MARK: - Custom(Debug)StringConvertible conformance tests
    func testDescription() {
        sut = [1, 2, 3, 4, 5]
        XCTAssertEqual(sut.description, "CircularQueue(capacity: 5)[1, 2, 3, 4, 5]")
    }
    
    func testDebugDescription() {
        sut = [1, 2, 3, 4, 5]
        XCTAssertEqual(sut.debugDescription, "Optional(CircularQueue.CircularQueue<Swift.Int>((capacity: 5)[1, 2, 3, 4, 5]))")
    }
    
    // MARK: - Private tests helepers
    func assertValueSemantics(_ copy: CircularQueue<Int>, file: StaticString = #file, line: UInt = #line) {
        assertAreDifferentValuesAndHaveDifferentStorage(lhs: sut, rhs: copy, file: file, line: line)
    }
    
}
