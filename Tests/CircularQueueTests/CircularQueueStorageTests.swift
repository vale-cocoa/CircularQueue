//
//  CircularQueueStorageTests.swift
//  CircularQueueTests
//
//  Created by Valeriano Della Longa on 28/11/20.
//

import XCTest
@testable import CircularQueue
@testable import Queue

final class CircularQueueStorageTests: XCTestCase {
    var sut: CircularQueueStorage<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = CircularQueueStorage<Int>()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialize tests
    func testInit() {
        sut = CircularQueueStorage<Int>()
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
    }
    
    func testInitCapacity() {
        sut = CircularQueueStorage<Int>(0)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        
        for k in 1...10 {
            sut = CircularQueueStorage<Int>(k)
            XCTAssertNotNil(sut)
            XCTAssertNotNil(sut.elements)
            XCTAssertEqual(sut.capacity, k)
            XCTAssertEqual(sut.count, 0)
            XCTAssertEqual(sut.head, 0)
            XCTAssertEqual(sut.tail, 0)
        }
    }
    
    func testInitSequence() {
        // when sequence implements withContiguousStorageIfAvailable(_:)
        // …and sequence is empty:
        var elements: Array<Int> = []
        sut = CircularQueueStorage(elements)
        var result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        XCTAssertEqual(result, elements)
        
        // …sequence is not empty:
        elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage(elements)
        result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, elements.count)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        XCTAssertEqual(result, elements)
        
        // when sequence doesn't implement withContiguousStorageIfAvailable(_:)
        // …and is empty:
        elements = []
        var seq = AnySequence<Int>(elements)
        sut = CircularQueueStorage(seq)
        result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        XCTAssertEqual(result, elements)
        
        // …sequence is not empty, and its underestimatedCount is greater than zero:
        elements = [1, 2, 3, 4, 5]
        seq = AnySequence<Int>(elements)
        XCTAssertGreaterThan(seq.underestimatedCount, 0)
        sut = CircularQueueStorage(seq)
        result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, elements.count)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        XCTAssertEqual(result, elements)
        
        // …sequence is not empty, and its underestimatedCount is smaller than its actual
        // count:
        seq = AnySequence<Int>({ () -> AnyIterator<Int> in
            var i = elements.startIndex
            
            return AnyIterator<Int> {
                defer { i += 1 }
                
                return i < elements.endIndex ? elements[i] : nil
            }
        })
        XCTAssertLessThan(seq.underestimatedCount, elements.count)
        sut = CircularQueueStorage(seq)
        result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, elements.count)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        XCTAssertEqual(result, elements)
        
        // when sequence is another CircularQueue:
        var other = CircularQueue([1, 2, 3, 4, 5])
        other.dequeue()
        other.dequeue()
        other.enqueue(6)
        other.enqueue(7)
        sut = CircularQueueStorage(other)
        XCTAssertEqual(sut.capacity, other.capacity)
        XCTAssertEqual(sut.count, elements.count)
        XCTAssertEqual(sut.head, other.storage.head)
        XCTAssertEqual(sut.tail, other.storage.tail)
        result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertEqual(result, Array(other))
        
    }
    
    func testInitRepeatingValue() {
        // when count is zero:
        sut = CircularQueueStorage(repeating: 1, count: 0)
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, 0)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        
        // when count is greater than zero:
        let repElement = Int.random(in: 1...100)
        let count = Int.random(in: 1...10)
        let expectedResult = Array(repeating: repElement, count: count)
        sut = CircularQueueStorage(repeating: repElement, count: count)
        let result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.elements)
        XCTAssertEqual(sut.capacity, count)
        XCTAssertEqual(sut.count, count)
        XCTAssertEqual(sut.head, 0)
        XCTAssertEqual(sut.tail, 0)
        XCTAssertEqual(result, expectedResult)
    }
    
    // MARK: - Deinitialization tests
    func testDeinitialize() {
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        sut = nil
        XCTAssertNil(sut?.elements)
        
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        sut = nil
        XCTAssertNil(sut?.elements)
        
        sut = CircularQueueStorage<Int>.testInstanceWithElementsWrappingAroundCapacity(headShift: 3, elements: [1, 2, 3, 4, 5])
        XCTAssertGreaterThan(sut.head + sut.count, sut.capacity)
        sut = nil
        XCTAssertNil(sut?.elements)
    }
    
    
    // MARK: - Computed properties tests
    func testIsEmpty() {
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        XCTAssertGreaterThan(sut.count, 0)
        XCTAssertFalse(sut.isEmpty)
    }
    
    func testIsFull() {
        XCTAssertEqual(sut.count, sut.capacity)
        XCTAssertTrue(sut.isFull)
        
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        XCTAssertEqual(sut.count, sut.capacity)
        XCTAssertTrue(sut.isFull)
        
        sut.popFront()
        XCTAssertLessThan(sut.count, sut.capacity)
        XCTAssertFalse(sut.isFull)
    }
    
    func testResidualCapacity() {
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        
        var prevResidualCapacity = sut.residualCapacity
        XCTAssertNotNil(sut.popFront())
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        XCTAssertEqual(sut.residualCapacity, prevResidualCapacity + 1)
        
        prevResidualCapacity = sut.residualCapacity
        XCTAssertNotNil(sut.popBack())
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        XCTAssertEqual(sut.residualCapacity, prevResidualCapacity + 1)
        
        prevResidualCapacity = sut.residualCapacity
        sut.pushBack(10)
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        XCTAssertEqual(sut.residualCapacity, prevResidualCapacity - 1)
        
        prevResidualCapacity = sut.residualCapacity
        sut.pushFront(11)
        XCTAssertEqual(sut.residualCapacity, sut.capacity - sut.count)
        XCTAssertEqual(sut.residualCapacity, prevResidualCapacity - 1)
        
        XCTAssertEqual(sut.residualCapacity, 0)
        XCTAssertTrue(sut.isFull)
        sut.pushBack(30)
        XCTAssertEqual(sut.residualCapacity, 0)
    }
    
    // MARK: - Subscript tests
    func testSubscriptGetter() {
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        for idx in elements.indices {
            XCTAssertEqual(sut[idx], elements[idx])
        }
    }
    
    func testSubscriptSetter() {
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        for idx in elements.indices {
            sut[idx] *= 10
            XCTAssertEqual(sut[idx], elements[idx] * 10)
        }
    }
    
    // MARK: - methods tests
    func testForEach() {
        XCTAssertTrue(sut.isEmpty)
        var result = [Int]()
        sut.forEach { result.append($0) }
        XCTAssertEqual(result, [])
        
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        result = []
        sut.forEach { result.append($0 * 10) }
        XCTAssertEqual(result, [10, 20, 30, 40, 50])
        
        sut = CircularQueueStorage<Int>.testInstanceWithElementsWrappingAroundCapacity(headShift: 3, elements: [1, 2, 3, 4, 5])
        XCTAssertGreaterThan(sut.head + sut.count, sut.capacity)
        result = []
        sut.forEach { result.append($0 * 10) }
        XCTAssertEqual(result, [10, 20, 30, 40 ,50])
        
        let alwaysThrowingClosure: (Int) throws -> Void = { _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(try sut.forEach(alwaysThrowingClosure))
        do {
            try sut.forEach(alwaysThrowingClosure)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testAllSatisfy() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertTrue(sut.allSatisfy { $0 == 10 })
        
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
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
    
    func testReserveCapacity() {
        var prevElements = sut.elements
        sut.reserveCapacity(20)
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, 20)
        XCTAssertNotEqual(sut.elements, prevElements)
        
        // when there are already enough free spots to cover it,
        // buffer doesn't get reallocated:
        sut.pushBack(contentsOf: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        let prevResidualCapacity = sut.residualCapacity
        XCTAssertGreaterThanOrEqual(prevResidualCapacity, 0)
        prevElements = sut.elements
        sut.reserveCapacity(prevResidualCapacity)
        XCTAssertEqual(sut.elements, prevElements)
        XCTAssertGreaterThanOrEqual(sut.residualCapacity, prevResidualCapacity)
        
        // otherwise buffer gets reallocated to a bigger one:
        let prevStoredElements = sut.withUnsafeBufferPointer { Array($0) }
        prevElements = sut.elements
        sut.reserveCapacity(prevResidualCapacity + 1)
        XCTAssertNotEqual(sut.elements, prevElements)
        XCTAssertEqual(sut.residualCapacity, prevResidualCapacity + 1)
        let result = sut.withUnsafeBufferPointer { Array($0) }
        XCTAssertEqual(result, prevStoredElements)
    }
    
    func testCopy() {
        var copy = sut.copy()
        XCTAssertEqual(sut.capacity, copy.capacity)
        XCTAssertNotEqual(sut.elements, copy.elements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, copy.withUnsafeBufferPointer { Array($0) })
        
        sut = CircularQueueStorage([1, 2, 3, 4, 5])
        let prevCapacity = sut.capacity
        copy = sut.copy(5)
        XCTAssertEqual(copy.capacity, prevCapacity + 5)
        XCTAssertNotEqual(sut.elements, copy.elements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, copy.withUnsafeBufferPointer { Array($0) })
        
        sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: 3, elements: [1, 2, 3, 4, 5])
        XCTAssertGreaterThan(sut.head + sut.count, sut.capacity)
        copy = sut.copy()
        XCTAssertEqual(sut.capacity, copy.capacity)
        XCTAssertNotEqual(sut.elements, copy.elements)
        XCTAssertEqual(sut.head, copy.head)
        XCTAssertEqual(sut.tail, copy.tail)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, copy.withUnsafeBufferPointer { Array($0) })
    }
    
    func testRemoveAll() {
        var prevCapacity = sut.capacity
        XCTAssertTrue(sut.isEmpty)
        sut.removeAll(keepingCapacity: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, 0)
        
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage(elements)
        prevCapacity = sut.capacity
        sut.removeAll(keepingCapacity: false)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, 0)
        
        sut = CircularQueueStorage(elements)
        prevCapacity = sut.capacity
        let prevElements = sut.elements
        sut.removeAll(keepingCapacity: true)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.elements, prevElements)
    }
    
    func testReplaceSubrange_whenSubrangeCountIsZero() {
        // these tests are for inserting elements
        var subrange: Range<Int> = 0..<0
        XCTAssertTrue(subrange.isEmpty)
        
        var newElements: Array<Int> = []
        // when sut.isEmpty == true and newElements.isEmpty == true,
        // then nothing happens
        XCTAssertTrue(sut.isEmpty)
        var prevStoredElements = sut.withUnsafeBufferPointer { Array($0) }
        var prevCapacity = sut.capacity
        sut.replaceSubrange(subrange, with: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevStoredElements)
        XCTAssertEqual(sut.capacity, prevCapacity)
        
        // when sut.isEmpty == true and newElements.isEmpty == false,
        // then newElements gets inserted in sut:
        newElements = [1, 2, 3, 4, 5]
        sut.replaceSubrange(subrange, with: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, newElements)
        XCTAssertGreaterThan(sut.capacity, prevCapacity)
        XCTAssertEqual(sut.capacity, newElements.count)
        
        // when sut.isEmpty == false and newElements.isEmpty == true,
        // then nothing happens:
        prevStoredElements = [1, 2, 3, 4, 5]
        newElements = []
        for idx in 0...sut.count {
            sut = CircularQueueStorage(prevStoredElements)
            subrange = idx..<idx
            prevCapacity = sut.capacity
            sut.replaceSubrange(subrange, with: newElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevStoredElements)
            XCTAssertEqual(sut.capacity, prevCapacity)
            
            // let's also test it when elements are wrapping around in the storage:
            for headShift in 1...prevStoredElements.count {
                sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: prevStoredElements)
                prevCapacity = sut.capacity
                sut.replaceSubrange(subrange, with: newElements)
                XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevStoredElements)
                XCTAssertEqual(sut.capacity, prevCapacity)
            }
        }
        
        // when sut.isEmpty = false and newElements.isEmpty == false,
        // then newElements gets inserted at index:
        newElements = [10, 20, 30, 40]
        for idx in prevStoredElements.startIndex...prevStoredElements.endIndex {
            subrange = idx..<idx
            let expectedResult = Array(prevStoredElements[prevStoredElements.startIndex..<idx]) + newElements + Array(prevStoredElements[idx..<prevStoredElements.endIndex])
            sut = CircularQueueStorage(prevStoredElements)
            let prevCount = sut.count
            sut.replaceSubrange(subrange, with: newElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            XCTAssertEqual(sut.capacity, prevCount + newElements.count)
            
            // let's also test it when elements are wrapping around in the storage:
            for headShift in 1...prevStoredElements.count {
                sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: prevStoredElements)
                let prevCount = sut.count
                sut.replaceSubrange(subrange, with: newElements)
                XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
                XCTAssertEqual(sut.capacity, prevCount + newElements.count)
            }
        }
    }
    
    func testReplaceSubrange_whenSubrangeIsNotEmptyAndNewElementsIsEmpty() {
        // these tests are for removing elements
        let prevElements = [1, 2, 3, 4, 5]
        for lowerBound in prevElements.indices {
            for toRemoveCount in 1...(prevElements.count - lowerBound) {
                let subrange = lowerBound..<(lowerBound + toRemoveCount)
                var expectedResult = prevElements
                expectedResult.replaceSubrange(subrange, with: [])
                sut = CircularQueueStorage(prevElements)
                sut.replaceSubrange(subrange, with: [])
                XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
                XCTAssertEqual(sut.capacity, sut.count)
                
                // let's also test it when elements are wrapping around in the storage:
                for headShift in 1...prevElements.count {
                    sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: prevElements)
                    sut.replaceSubrange(subrange, with: [])
                    XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
                    XCTAssertEqual(sut.capacity, sut.count)
                }
            }
        }
    }
    
    func testReplaceSubrange_whenSubrangeIsNotEmptyAndNewElementsIsNotEmpty() {
        // these tests are for really replacing elements:
        let prevElements = [1, 2, 3, 4, 5]
        let newElements = [10, 20 ,30 , 40, 50]
        for lowerBound in prevElements.indices {
            for toRemoveCount in 1...(prevElements.count - lowerBound) {
                let subrange = lowerBound..<(lowerBound + toRemoveCount)
                var expectedResult = prevElements
                expectedResult.replaceSubrange(subrange, with: newElements)
                sut = CircularQueueStorage(prevElements)
                sut.replaceSubrange(subrange, with: newElements)
                XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
                XCTAssertEqual(sut.capacity, sut.count)
                
                // let's also test it when elements are wrapping around in the storage:
                for headShift in 1...prevElements.count {
                    sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: prevElements)
                    sut.replaceSubrange(subrange, with: newElements)
                    XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
                    XCTAssertEqual(sut.capacity, sut.count)
                }
            }
        }
    }
    
    func testAppendSequence_whenNewElementsIsCircularQueue() {
        // when sut.isEmpty == true and newElements.isEmpty == true,
        // then nothing happens:
        var newElements = CircularQueue<Int>()
        XCTAssertTrue(sut.isEmpty)
        var prevElements: Array<Int> = []
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevElements)
        
        // when sut.isEmpty == true and newElements.isEmpty == false,
        // then newElements gets appended to sut:
        newElements = [10, 20, 30 ,40, 50]
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, newElements.map { $0 })
        
        // when sut.isEmpty == false and newElements.isEmpty == true,
        // then nothing happens:
        prevElements = [1, 2, 3, 4, 5]
        newElements = []
        sut = CircularQueueStorage(prevElements)
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevElements)
        
        // when sut.isEmpty == false and newElements.isEmpty == false,
        // then newElements gets appended to sut:
        newElements = [10, 20, 30 ,40, 50]
        let expectedResult = prevElements + newElements.map { $0 }
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        
        // let's also do this test with elements wrapping around in the storage:
        for headShift in 1...prevElements.count {
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: prevElements)
            sut.append(contentsOf: newElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
    }
    
    func testAppendSequence_whenNewElementsImplementsWithContiguousStorageWhenAvailable() {
        // when sut.isEmpty == true and newElements.isEmpty == true,
        // then nothing happens:
        var newElements: Array<Int> = []
        XCTAssertTrue(sut.isEmpty)
        var prevElements: Array<Int> = []
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevElements)
        
        // when sut.isEmpty == true and newElements.isEmpty == false,
        // then newElements gets appended to sut:
        newElements = [10, 20, 30 ,40, 50]
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, newElements)
        
        // when sut.isEmpty == false and newElements.isEmpty == true,
        // then nothing happens:
        prevElements = [1, 2, 3, 4, 5]
        newElements = []
        sut = CircularQueueStorage(prevElements)
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevElements)
        
        // when sut.isEmpty == false and newElements.isEmpty == false,
        // then newElements gets appended to sut:
        newElements = [10, 20, 30 ,40, 50]
        let expectedResult = prevElements + newElements
        sut.append(contentsOf: newElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        
        // let's also do this test with elements wrapping around in the storage:
        for headShift in 1...prevElements.count {
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: prevElements)
            sut.append(contentsOf: newElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
    }
    
    func testAppendSequence_whenNewElementsDoesntImplementsWithContiguousStorageWhenAvailable() {
        // when sut.isEmpty == true and newElements.isEmpty == true,
        // then nothing happens:
        var newElements: Array<Int> = []
        XCTAssertTrue(sut.isEmpty)
        var prevElements: Array<Int> = []
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevElements)
        
        // when sut.isEmpty == true and newElements.isEmpty == false,
        // then newElements gets appended to sut:
        newElements = [10, 20, 30 ,40, 50]
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, newElements)
        
        // when sut.isEmpty == false and newElements.isEmpty == true,
        // then nothing happens:
        prevElements = [1, 2, 3, 4, 5]
        newElements = []
        sut = CircularQueueStorage(prevElements)
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, prevElements)
        
        // when sut.isEmpty == false and newElements.isEmpty == false,
        // then newElements gets appended to sut:
        newElements = [10, 20, 30 ,40, 50]
        let expectedResult = prevElements + newElements
        sut.append(contentsOf: AnySequence(newElements))
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        XCTAssertEqual(sut.capacity, expectedResult.count)
        
        // let's also do this test with elements wrapping around in the storage:
        for headShift in 1...prevElements.count {
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: prevElements)
            sut.append(contentsOf: AnySequence(newElements))
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            XCTAssertEqual(sut.capacity, expectedResult.count)
        }
    }
    
    func testAppendSequence_whenSequenceUnderEstimatedCountIsLessThanCount() {
        // This one covers specifically when newElements is a sequence which doesn't
        // implement withContiguousStorageIfAvaialable(_:) and its underestimatedCount
        // value is less than the real count of the sequence.
        let newElements = [10, 20, 30 ,40, 50]
        let seq = AnySequence<Int> { () -> AnyIterator<Int>  in
            var idx = newElements.startIndex
            
            return AnyIterator<Int> {
                guard idx < newElements.endIndex else { return nil }
                
                defer { idx += 1 }
                
                return newElements[idx]
            }
        }
        
        var expectedResult = newElements
        sut.append(contentsOf: seq)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        XCTAssertEqual(sut.capacity, expectedResult.count)
        
        let prevElements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage(prevElements)
        expectedResult = prevElements + newElements
        sut.append(contentsOf: seq)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        XCTAssertEqual(sut.capacity, expectedResult.count)
    }
    
    func testPopFront() {
        // when isEmpty, returns nil:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popFront())
        
        // when not empty, removes and return first, capacity stays the same:
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage(elements)
        let expectedCapacity = sut.capacity
        for i in 0..<elements.count {
            let prevFirst = sut[0]
            let expectedResult = Array(elements[(i + 1)..<elements.endIndex])
            XCTAssertEqual(sut.popFront(), prevFirst)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
    }
    
    func testPushFrontNewElement() {
        // when capacity is 0 nothing happens:
        XCTAssertEqual(sut.capacity, 0)
        sut.pushFront(10)
        XCTAssertEqual(sut.capacity, 0)
        
        // when residualCapacity is greater than 0, then element is stored as new first:
        sut.reserveCapacity(5)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        let expectedCapacity = sut.capacity
        var newElement = 5
        var expectedResult: Array<Int> = []
        while sut.residualCapacity > 0 {
            expectedResult.insert(newElement, at: 0)
            sut.pushFront(newElement)
            XCTAssertEqual(sut[0], newElement)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement -= 1
        }
        
        // when residualCapacity is equal to 0, then element is stored as new first, and
        // old last gets trumped:
        XCTAssertEqual(sut.residualCapacity, 0)
        newElement = 50
        for i in 1...10 {
            let _ = expectedResult.popLast()
            expectedResult.insert(newElement, at: 0)
            sut.pushFront(newElement)
            XCTAssertEqual(sut[0], newElement)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement += i*10
        }
    }
    
    func testPushFrontSequence_whenSequenceImplementsWithContiguousStorageIfAvailable() {
        // when capacity is 0 nothing happens:
        var otherElements = [10, 20, 30, 40, 50]
        XCTAssertEqual(sut.capacity, 0)
        sut.pushFront(contentsOf: otherElements)
        XCTAssertEqual(sut.capacity, 0)
        
        // when capacity is greater than zero, sequence is empty,
        // then nothing happens:
        let sutPrevElements = [1, 2, 3, 4, 5]
        otherElements = []
        sut = CircularQueueStorage(sutPrevElements)
        XCTAssertGreaterThan(sut.capacity, 0)
        XCTAssertTrue(otherElements.isEmpty)
        sut.pushFront(contentsOf: otherElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, sutPrevElements)
        
        // when sequence is not empty, sut residualCapacity is enough
        // to store all new elements, then all sequence elements are sequentially pushed
        // in sut front and no element previously stored in sut is trumped:
        for i in 1...5 {
            otherElements.append(i * 10)
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(5)
            XCTAssertFalse(otherElements.isEmpty)
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, otherElements.count)
            let expectedResult = otherElements.reversed() + sutPrevElements
            sut.pushFront(contentsOf: otherElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
        
        // when sequence is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially pushed in sut,
        // while sut drops elements from its back to make room for new elements:
        let sutExpectedResidualCapacity = 3
        let sutExpectedCapacity = sutPrevElements.count + sutExpectedResidualCapacity
        otherElements = []
        for i in 1...sutExpectedResidualCapacity + 1 {
            otherElements.append(i * 10)
        }
        XCTAssertGreaterThan(otherElements.count, sutExpectedResidualCapacity)
        
        // here we'll just trump previously stored elements to make room for new elements
        var lastOther = otherElements.last!
        for countOfTrumped in 1...sutPrevElements.count {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = otherElements.reversed() + Array(sutPrevElements[0..<(sutPrevElements.endIndex - countOfTrumped)])
            sut.pushFront(contentsOf: otherElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep making room for new elements
        lastOther = otherElements.last!
        for countOfTrumped in 1...sutExpectedCapacity {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = Array(otherElements.dropFirst(countOfTrumped).reversed())
            sut.pushFront(contentsOf: otherElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
    }
    
    func testPushFrontSequence_whenSequenceDoesntImplementsWithContiguousStorageIfAvailable() {
        // when capacity is 0 nothing happens:
        var otherElements = [10, 20, 30, 40, 50]
        XCTAssertEqual(sut.capacity, 0)
        sut.pushFront(contentsOf: AnySequence(otherElements))
        XCTAssertEqual(sut.capacity, 0)
        
        // when capacity is greater than zero, sequence is empty,
        // then nothing happens:
        let sutPrevElements = [1, 2, 3, 4, 5]
        otherElements = []
        sut = CircularQueueStorage(sutPrevElements)
        XCTAssertGreaterThan(sut.capacity, 0)
        XCTAssertTrue(otherElements.isEmpty)
        sut.pushFront(contentsOf: AnySequence(otherElements))
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, sutPrevElements)
        
        // when sequence is not empty, sut residualCapacity is enough
        // to store all new elements, then all sequence elements are sequentially pushed
        // in sut front and no element previously stored in sut is trumped:
        for i in 1...5 {
            otherElements.append(i * 10)
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(5)
            XCTAssertFalse(otherElements.isEmpty)
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, otherElements.count)
            let expectedResult = otherElements.reversed() + sutPrevElements
            sut.pushFront(contentsOf: AnySequence(otherElements))
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
        
        // when sequence is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially pushed in sut,
        // while sut drops elements from its back to make room for new elements:
        let sutExpectedResidualCapacity = 3
        let sutExpectedCapacity = sutPrevElements.count + sutExpectedResidualCapacity
        otherElements = []
        for i in 1...sutExpectedResidualCapacity + 1 {
            otherElements.append(i * 10)
        }
        XCTAssertGreaterThan(otherElements.count, sutExpectedResidualCapacity)
        
        // here we'll just trump previously stored elements to make room for new elements
        var lastOther = otherElements.last!
        for countOfTrumped in 1...sutPrevElements.count {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = otherElements.reversed() + Array(sutPrevElements[0..<(sutPrevElements.endIndex - countOfTrumped)])
            sut.pushFront(contentsOf: AnySequence(otherElements))
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep meaking room for new elements
        lastOther = otherElements.last!
        for countOfTrumped in 1...sutExpectedCapacity {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = Array(otherElements.dropFirst(countOfTrumped).reversed())
            sut.pushFront(contentsOf: AnySequence(otherElements))
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
    }
    
    func testPopBack() {
        // when isEmpty, returns nil:
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.popBack())
        
        // when not empty, removes and return last, capacity stays the same:
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage(elements)
        let expectedCapacity = sut.capacity
        for i in 1...elements.count {
            let prevLast = sut[sut.count - 1]
            let expectedResult = Array(elements[0..<(elements.endIndex - i)])
            XCTAssertEqual(sut.popBack(), prevLast)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
    }
    
    func testPushBackNewElement() {
        // when capacity is 0 nothing happens:
        XCTAssertEqual(sut.capacity, 0)
        sut.pushBack(10)
        XCTAssertEqual(sut.capacity, 0)
        
        // when residualCapacity is greater than 0, then element is stored as new last:
        sut.reserveCapacity(5)
        XCTAssertGreaterThan(sut.residualCapacity, 0)
        let expectedCapacity = sut.capacity
        var newElement = 5
        var expectedResult: Array<Int> = []
        while sut.residualCapacity > 0 {
            expectedResult.append(newElement)
            sut.pushBack(newElement)
            XCTAssertEqual(sut[sut.count - 1], newElement)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement -= 1
        }
        
        // when residualCapacity is equal to 0, then element is stored as new last, and
        // old first gets trumped:
        XCTAssertEqual(sut.residualCapacity, 0)
        newElement = 50
        for i in 1...10 {
            let _ = expectedResult.remove(at: 0)
            expectedResult.append(newElement)
            sut.pushBack(newElement)
            XCTAssertEqual(sut[sut.count - 1], newElement)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            XCTAssertEqual(sut.capacity, expectedCapacity)
            
            newElement += i*10
        }
    }
    
    func testPushBackSequence_whenSequenceImplementsWithContiguousStorageIfAvailable() {
        // when capacity is 0 nothing happens:
        var otherElements = [10, 20, 30, 40, 50]
        XCTAssertEqual(sut.capacity, 0)
        sut.pushBack(contentsOf: otherElements)
        XCTAssertEqual(sut.capacity, 0)
        
        // when capacity is greater than zero, sequence is empty,
        // then nothing happens:
        let sutPrevElements = [1, 2, 3, 4, 5]
        otherElements = []
        sut = CircularQueueStorage(sutPrevElements)
        XCTAssertGreaterThan(sut.capacity, 0)
        XCTAssertTrue(otherElements.isEmpty)
        sut.pushBack(contentsOf: otherElements)
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, sutPrevElements)
        
        // when sequence is not empty, sut residualCapacity is enough
        // to store all new elements, then all sequence elements are appended to sut
        // and no element previously stored in sut is trumped:
        for i in 1...5 {
            otherElements.append(i * 10)
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(5)
            XCTAssertFalse(otherElements.isEmpty)
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, otherElements.count)
            let expectedResult = sutPrevElements + otherElements
            sut.pushBack(contentsOf: otherElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
        
        // when sequence is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially appended to sut,
        // while sut drops elements from its front to make room for new elements:
        let sutExpectedResidualCapacity = 3
        let sutExpectedCapacity = sutPrevElements.count + sutExpectedResidualCapacity
        otherElements = []
        for i in 1...sutExpectedResidualCapacity + 1 {
            otherElements.append(i * 10)
        }
        XCTAssertGreaterThan(otherElements.count, sutExpectedResidualCapacity)
        
        // here we'll just trump previously stored elements to make room for new elements
        var lastOther = otherElements.last!
        for countOfTrumped in 1...sutPrevElements.count {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = Array(sutPrevElements[countOfTrumped..<sutPrevElements.endIndex]) + otherElements
            sut.pushBack(contentsOf: otherElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep meaking room for new elements
        lastOther = otherElements.last!
        for countOfTrumped in 1...sutExpectedCapacity {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = Array(otherElements.dropFirst(countOfTrumped))
            sut.pushBack(contentsOf: otherElements)
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
    }
 
    func testPushBackSequence_whenSequenceDoesntImplementsWithContiguousStorageIfAvailable() {
        // when capacity is 0 nothing happens:
        var otherElements = [10, 20, 30, 40, 50]
        XCTAssertEqual(sut.capacity, 0)
        sut.pushBack(contentsOf: AnySequence(otherElements))
        XCTAssertEqual(sut.capacity, 0)
        
        // when capacity is greater than zero, sequence is empty,
        // then nothing happens:
        let sutPrevElements = [1, 2, 3, 4, 5]
        otherElements = []
        sut = CircularQueueStorage(sutPrevElements)
        XCTAssertGreaterThan(sut.capacity, 0)
        XCTAssertTrue(otherElements.isEmpty)
        sut.pushBack(contentsOf: AnySequence(otherElements))
        XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, sutPrevElements)
        
        // when sequence is not empty, sut residualCapacity is enough
        // to store all new elements, then all sequence elements are appended to sut
        // and no element previously stored in sut is trumped:
        for i in 1...5 {
            otherElements.append(i * 10)
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(5)
            XCTAssertFalse(otherElements.isEmpty)
            XCTAssertGreaterThanOrEqual(sut.residualCapacity, otherElements.count)
            let expectedResult = sutPrevElements + otherElements
            sut.pushBack(contentsOf: AnySequence(otherElements))
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
        }
        
        // when sequence is not empty, and sut residual capacity is not enough to
        // store all newElements, then sequence elements are sequentially appended to sut,
        // while sut drops elements from its front to make room for new elements:
        let sutExpectedResidualCapacity = 3
        let sutExpectedCapacity = sutPrevElements.count + sutExpectedResidualCapacity
        otherElements = []
        for i in 1...sutExpectedResidualCapacity + 1 {
            otherElements.append(i * 10)
        }
        XCTAssertGreaterThan(otherElements.count, sutExpectedResidualCapacity)
        
        // here we'll just trump previously stored elements to make room for new elements
        var lastOther = otherElements.last!
        for countOfTrumped in 1...sutPrevElements.count {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = Array(sutPrevElements[countOfTrumped..<sutPrevElements.endIndex]) + otherElements
            sut.pushBack(contentsOf: AnySequence(otherElements))
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
        
        // From now on we'll have to trump all previously stored elements, and then
        // also newly stored elements to keep meaking room for new elements
        lastOther = otherElements.last!
        for countOfTrumped in 1...sutExpectedCapacity {
            sut = CircularQueueStorage(sutPrevElements)
            sut.reserveCapacity(sutExpectedResidualCapacity)
            let expectedResult = Array(otherElements.dropFirst(countOfTrumped))
            sut.pushBack(contentsOf: AnySequence(otherElements))
            XCTAssertEqual(sut.withUnsafeBufferPointer { Array($0) }, expectedResult)
            
            otherElements.append(lastOther + (countOfTrumped * 10))
        }
    }
    
    func testWithUnsafeBufferPointer_whenElementsDontWrapAroundInStorage() {
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage(elements)
        XCTAssertLessThanOrEqual(sut.head + sut.count, sut.capacity)
        
        let exp1 = expectation(description: "completion completes")
        let arr: Array<Int> = sut.withUnsafeBufferPointer {
            exp1.fulfill()
            
            return Array($0)
        }
        wait(for: [exp1], timeout: 0.1)
        XCTAssertEqual(arr, elements)
        
        let throwingClosure: (UnsafeBufferPointer<Int>) throws -> Bool = { _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(try sut.withUnsafeBufferPointer(throwingClosure))
        do {
            let _ = try sut.withUnsafeBufferPointer(throwingClosure)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testWithUnsafeBufferPointer_whenElementsWrapAroundInStorage() {
        let throwingClosure: (UnsafeBufferPointer<Int>) throws -> Bool = { _ in
            throw testThrownError
        }
        let elements = [1, 2, 3, 4, 5]
        for headShift in 1...elements.count {
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: elements)
            XCTAssertGreaterThan(sut.head + sut.count, sut.capacity)
            
            let exp1 = expectation(description: "completion completes")
            let arr: Array<Int> = sut.withUnsafeBufferPointer {
                exp1.fulfill()
                
                return Array($0)
            }
            wait(for: [exp1], timeout: 0.1)
            XCTAssertEqual(arr, elements)
            
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: elements)
            XCTAssertThrowsError(try sut.withUnsafeBufferPointer(throwingClosure))
            
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: elements)
            do {
                let _ = try sut.withUnsafeBufferPointer(throwingClosure)
            } catch {
                XCTAssertEqual(error as NSError, testThrownError)
            }
        }
    }
    
    func testWithUnsafeMutableBufferPointer_whenElementsDontWrapAroundInStorage() {
        let elements = [1, 2, 3, 4, 5]
        sut = CircularQueueStorage(elements)
        XCTAssertLessThanOrEqual(sut.head + sut.count, sut.capacity)
        
        let exp1 = expectation(description: "completion completes")
        let result: Bool = sut.withUnsafeMutableBufferPointer { buffer in
            for idx in buffer.startIndex..<buffer.endIndex {
                buffer[idx] *= 10
            }
            exp1.fulfill()
            
            return true
        }
        wait(for: [exp1], timeout: 0.1)
        XCTAssertTrue(result)
        XCTAssertEqual(sut.count, elements.count)
        for idx in elements.indices {
            XCTAssertEqual(sut[idx], elements[idx] * 10)
        }
        
        let throwingClosure: (inout UnsafeMutableBufferPointer<Int>) throws -> Bool = { _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(try sut.withUnsafeMutableBufferPointer(throwingClosure))
        do {
            let _ = try sut.withUnsafeMutableBufferPointer(throwingClosure)
        } catch {
            XCTAssertEqual(error as NSError, testThrownError)
        }
    }
    
    func testWithUnsafeMutableBufferPointer_whenElementsWrapAroundInStorage() {
        let throwingClosure: (inout UnsafeMutableBufferPointer<Int>) throws -> Bool = { _ in
            throw testThrownError
        }
        let elements = [1, 2, 3, 4, 5]
        for headShift in 1...elements.count {
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: elements)
            XCTAssertGreaterThan(sut.head + sut.count, sut.capacity)
            
            let exp1 = expectation(description: "completion completes")
            let result: Bool = sut.withUnsafeMutableBufferPointer { buffer in
                for idx in buffer.startIndex..<buffer.endIndex {
                    buffer[idx] *= 10
                }
                exp1.fulfill()
                
                return true
            }
            wait(for: [exp1], timeout: 0.1)
            XCTAssertTrue(result)
            XCTAssertEqual(sut.count, elements.count)
            for idx in elements.indices {
                XCTAssertEqual(sut[idx], elements[idx] * 10)
            }
            
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: elements)
            XCTAssertThrowsError(try sut.withUnsafeMutableBufferPointer(throwingClosure))
            
            sut = CircularQueueStorage.testInstanceWithElementsWrappingAroundCapacity(headShift: headShift, elements: elements)
            do {
                let _ = try sut.withUnsafeMutableBufferPointer(throwingClosure)
            } catch {
                XCTAssertEqual(error as NSError, testThrownError)
            }
        }
    }
    
}
