//
//  CircularQueueStorage.swift
//  CircularQueue
//
//  Created by Valeriano Della Longa on 26/11/20.
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

final class CircularQueueStorage<Element> {
    private(set) var elements: UnsafeMutablePointer<Element>
    
    private(set) var capacity: Int
    
    private(set) var count: Int
    
    private(set) var head: Int
    
    private(set) var tail: Int
    
    var isEmpty: Bool { count == 0 }
    
    var isFull: Bool { capacity == count }
    
    var residualCapacity: Int { capacity - count }
    
    init() {
        self.elements = UnsafeMutablePointer.allocate(capacity: 0)
        self.capacity = 0
        self.count = 0
        self.head = 0
        self.tail = 0
    }
    
    init(_ capacity: Int = 0) {
        precondition(capacity >= 0, "CircularQueueStorage: capacity must not be negative")
        self.elements = UnsafeMutablePointer.allocate(capacity: capacity)
        self.capacity = capacity
        self.count = 0
        self.head = 0
        self.tail = 0
    }
    
    convenience init<S: Sequence>(_ elements: S) where Element == S.Iterator.Element {
        if let other = elements as? CircularQueue<Element> {
            self.init(other.storage)
            
            return
        }
        
        var buff: UnsafeMutablePointer<Element>!
        var newCount: Int = 0
        let done: Bool = elements
            .withContiguousStorageIfAvailable { seqBuff -> Bool in
                newCount = seqBuff.count
                buff = UnsafeMutablePointer<Element>.allocate(capacity: newCount)
                if seqBuff.baseAddress != nil && newCount > 0 {
                    buff.initialize(from: seqBuff.baseAddress!, count: newCount)
                }
                
                return true
            } ?? false
        if !done {
            var seqIter = elements.makeIterator()
            if let firstSeqElement = seqIter.next() {
                let initialCap = elements.underestimatedCount > 0 ? elements.underestimatedCount : 1
                buff = UnsafeMutablePointer<Element>.allocate(capacity: initialCap)
                buff.initialize(to: firstSeqElement)
                newCount += 1
                while let newElement = seqIter.next() {
                    if newCount + 1 > initialCap {
                        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCount + 1)
                        newBuff.moveInitialize(from: buff, count: newCount)
                        buff.deallocate()
                        buff = newBuff
                    }
                    buff.advanced(by: newCount).initialize(to: newElement)
                    newCount += 1
                }
                
            } else {
                buff = UnsafeMutablePointer<Element>.allocate(capacity: 0)
            }
        }
        
        self.init(elements: buff, capacity: newCount, count: newCount, head: 0, tail: 0)
    }
    
    init(repeating repeatedValue: Element, count: Int) {
        self.elements = UnsafeMutablePointer<Element>.allocate(capacity: count)
        self.elements.initialize(repeating: repeatedValue, count: count)
        self.capacity = count
        self.count = count
        self.head = 0
        self.tail = 0
    }
    
    private init(_ other: CircularQueueStorage) {
        self.capacity = other.capacity
        self.elements = UnsafeMutablePointer<Element>.allocate(capacity: other.capacity)
        if other.head + other.count > other.capacity {
            let rightCount = other.capacity - other.head
            self.elements.advanced(by: other.head).initialize(from: other.elements.advanced(by: other.head), count: rightCount)
            self.elements.initialize(from: other.elements, count: other.count - rightCount)
        } else {
            self.elements.advanced(by: other.head).initialize(from: other.elements.advanced(by: other.head), count: other.count)
        }
        self.count = other.count
        self.head = other.head
        self.tail = other.tail
    }
    
    private init(elements: UnsafeMutablePointer<Element>, capacity: Int, count: Int, head: Int, tail: Int) {
        self.elements = elements
        self.capacity = capacity
        self.count = count
        self.head = head
        self.tail = tail
    }
    
    deinit {
        _deinitializeElements(advancedToBufferIndex: head, count: count)
        elements.deallocate()
    }
    
    subscript(position: Int) -> Element {
        get {
            _checkSubscriptBounds(for: position)
            let buffIdx = _bufferIndex(from: position)
            
            return elements.advanced(by: buffIdx).pointee
        }
        
        set {
            _checkSubscriptBounds(for: position)
            let buffIdx = _bufferIndex(from: position)
            elements.advanced(by: buffIdx).pointee = newValue
        }
    }
    
    func forEach(_ body: (Element) throws -> ()) rethrows {
        var adv = 0
        while adv < count {
            let buffIdx = _bufferIndex(from: adv)
            try body(elements.advanced(by: buffIdx).pointee)
            adv += 1
        }
    }
    
    func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        var adv = 0
        while adv < count {
            let buffIdx = _bufferIndex(from: adv)
            if try predicate(elements.advanced(by: buffIdx).pointee) == false {
                
                return false
            }
            adv += 1
        }
        
        return true
    }
    
    func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "minimumCapacity must not be negative")
        let additionalSpots = minimumCapacity - residualCapacity
        guard additionalSpots > 0 else { return }
        
        _fastResizeElements(to: capacity + additionalSpots)
    }
    
    func copy(_ additionalCapacity: Int = 0) -> CircularQueueStorage {
        precondition(additionalCapacity >= 0, "CircularQueueStorage copy: additional capacity must be positive.")
        guard additionalCapacity > 0 else {
            
            return CircularQueueStorage(self)
        }
        
        let newCapacity = capacity + additionalCapacity
        let copy = CircularQueueStorage(newCapacity)
        if !isEmpty {
            _initializeFromElements(advancedToBufferIndex: head, count: count, to: copy.elements)
        }
        
        copy.count = count
        copy.head = 0
        copy.tail = copy._incrementIndex(copy.count - 1)
        
        return copy
    }
    
    func removeAll(keepingCapacity keepCapacity: Bool) {
        _deinitializeElements(advancedToBufferIndex: head, count: count)
        count = 0
        head = 0
        tail = 0
        if !keepCapacity {
            elements.deallocate()
            capacity = 0
            elements = UnsafeMutablePointer<Element>.allocate(capacity: 0)
        }
    }
    
    func replaceSubrange<C: Collection>(_ subrange: Range<Int>, with other: C) where Element == C.Iterator.Element {
        _checkBounds(subrange)
        if subrange.count == 0 {
            // It's an insertion operation
            _fastInsert(at: subrange.lowerBound, other: other)
        } else {
            // subrange.count > 0
            let otherCount = other.count
            if otherCount == 0 {
                // it's a removal operation:
                _fastRemove(at: subrange.lowerBound, count: subrange.count)
            } else {
                // it's a replacing operation:
                _fastReplace(subrange: subrange, with: other)
            }
        }
    }
    
    func append<S>(contentsOf newElements: S) where S : Sequence, Element == S.Iterator.Element {
        if
            let other = (newElements as? CircularQueue<Element>)?.storage
        {
            
            return other.withUnsafeBufferPointer { self._fastAppend($0) }
        }
        
        let done: Bool = newElements
            .withContiguousStorageIfAvailable { buff -> Bool in
                _fastAppend(buff)
                
                return true
            } ?? false
        
        if !done {
            var newElementsIter = newElements.makeIterator()
            if let firstNewElement = newElementsIter.next() {
                let initialCap = count + (newElements.underestimatedCount > 0 ? newElements.underestimatedCount : 1)
                var newBuff = UnsafeMutablePointer<Element>.allocate(capacity: initialCap)
                _moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
                newBuff.advanced(by: count).initialize(to: firstNewElement)
                var newCount = count + 1
                
                while let newElement = newElementsIter.next() {
                    if newCount + 1 > initialCap {
                        let temp = UnsafeMutablePointer<Element>.allocate(capacity: newCount + 1)
                        temp.moveInitialize(from: newBuff, count: newCount)
                        newBuff.deallocate()
                        newBuff = temp
                    }
                    newBuff.advanced(by: newCount).initialize(to: newElement)
                    newCount += 1
                }
                elements.deallocate()
                elements = newBuff
                capacity = newCount
                count = newCount
                head = 0
                tail = 0
            }
        }
    }
    
    @discardableResult
    func popFront() -> Element? {
        guard !isEmpty else { return nil }
        
        let firstElement = elements.advanced(by: head).move()
        defer {
            head = _incrementIndex(head)
            count -= 1
        }
        
        return firstElement
    }
    
    func pushFront(_ newElement: Element) {
        guard capacity > 0 else { return }
        
        head = _decrementIndex(head)
        if isFull {
            elements.advanced(by: head).pointee = newElement
            tail = _decrementIndex(tail)
        } else {
            elements.advanced(by: head).initialize(to: newElement)
            count += 1
        }
    }
    
    func pushFront<S: Sequence>(contentsOf newElements: S) where Element == S.Iterator.Element {
        guard capacity > 0 else { return }
        
        let done: Bool = newElements
            .withContiguousStorageIfAvailable { buff -> Bool in
                let addedCount = buff.count
                guard
                    buff.baseAddress != nil,
                    addedCount > 0
                else { return true }
                
                guard
                    addedCount > self.residualCapacity
                else {
                    self._fastPrepend(buff.reversed())
                    
                    return true
                }
                
                if addedCount > self.capacity {
                    let slice = buff[buff.endIndex - self.capacity..<buff.endIndex]
                        .reversed()
                    self._deinitializeElements(advancedToBufferIndex: self.head, count: self.count)
                    self._initializeElements(advancedToBufferIndex: 0, from: slice)
                    self.head = 0
                    self.tail = 0
                } else {
                    let countToDeinitialize = addedCount - self.residualCapacity >= self.count ? self.count : addedCount - self.residualCapacity
                    let newTail = self._bufferIndex(from: self.count - countToDeinitialize)
                    self._deinitializeElements(advancedToBufferIndex: newTail, count: countToDeinitialize)
                    self.tail = newTail
                    self._initializeElements(advancedToBufferIndex: newTail, from: buff.reversed())
                    self.head = newTail
                }
                self.count = self.capacity
                
                return true
            } ?? false
        
        if !done {
            for newElement in newElements {
                pushFront(newElement)
            }
        }
    }
    
    @discardableResult
    public func popBack() -> Element? {
        guard !isEmpty else { return nil }
        
        tail = _decrementIndex(tail)
        let lastElement = elements.advanced(by: tail).move()
        count -= 1
        
        return lastElement
    }
    
    public func pushBack(_ newElement: Element) {
        guard capacity > 0 else { return }
        
        if isFull {
            elements.advanced(by: tail).pointee = newElement
            tail = _incrementIndex(tail)
            head = _incrementIndex(head)
        } else {
            elements.advanced(by: tail).initialize(to: newElement)
            tail = _incrementIndex(tail)
            count += 1
        }
    }
    
    public func pushBack<S: Sequence>(contentsOf newElements: S) where Element == S.Iterator.Element {
        guard capacity > 0 else { return }
        
        let done: Bool = newElements
            .withContiguousStorageIfAvailable { buff -> Bool in
                let addedCount = buff.count
                guard
                    buff.baseAddress != nil,
                    addedCount > 0
                else { return true }
                
                guard
                    addedCount > self.residualCapacity
                else {
                    self._fastAppend(buff)
                    
                    return true
                }
                
                if addedCount > self.capacity {
                    let slice = buff[(buff.endIndex - self.capacity)..<buff.endIndex]
                    self._deinitializeElements(advancedToBufferIndex: self.head, count: self.count)
                    self._initializeElements(advancedToBufferIndex: 0, from: slice)
                    self.head = 0
                    self.tail = 0
                } else {
                    let countToDeinitialize = addedCount - self.residualCapacity >= self.count ? self.count : addedCount - self.residualCapacity
                    let newHead = self._deinitializeElements(advancedToBufferIndex: self.head, count: countToDeinitialize)
                    self._initializeElements(advancedToBufferIndex: self.tail, from: buff)
                    self.head = newHead
                    self.tail = self.head
                }
                self.count = self.capacity
                
                return true
            } ?? false
        
        if !done {
            for newElement in newElements {
                pushBack(newElement)
            }
        }
    }
    
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R ) rethrows -> R {
        if head + count > capacity {
            _fastRotateBufferHeadToZero()
        }
        let buffer = UnsafeBufferPointer<Element>(start: elements.advanced(by: head), count: count)
        
        return try body(buffer)
    }
    
    func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R {
        if head + count > capacity {
            _fastRotateBufferHeadToZero()
        }
        
        // save actual state:
        let prevElements = elements
        let prevCapacity = capacity
        let prevCount = count
        let prevHead = head
        let prevTail = tail
        
        // temporarly change internal state to empty
        elements = UnsafeMutablePointer<Element>.allocate(capacity: 0)
        capacity = 0
        count = 0
        head = 0
        tail = 0
        
        // prepare the buffer that will be passed to body
        var buffer = UnsafeMutableBufferPointer<Element>(start: prevElements.advanced(by: prevHead), count: prevCount)
        
        defer {
            // Once body has executed, restore the state:
            precondition(buffer.baseAddress == prevElements && buffer.count == prevCount, "CircularQueueStorage withUnsafeMutableBufferPointer: replacing the buffer is not allowed")
            self.elements.deallocate()
            self.elements = prevElements
            self.capacity = prevCapacity
            self.count = prevCount
            self.head = prevHead
            self.tail = prevTail
        }
        
        // execute body and return its result
        return try body(&buffer)
    }
    
}

// MARK: - Private helpers
// MARK: - Replace helpers
extension CircularQueueStorage {
    @inline(__always)
    private func _checkBounds(_ bounds: Range<Int>) {
        precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count, "range out of bounds")
    }
    
    private func _fastInsert<C: Collection>(at position: Int, other: C) where Element == C.Iterator.Element {
        guard
            position != 0
        else {
            _fastPrepend(other)
            
            return
        }
        
        guard position != count else {
            _fastAppend(other)
            
            return
        }
        
        let otherCount = other.count
        guard otherCount > 0 else { return }
        
        let newCapacity = count + otherCount
        let storageFirstHalfCount = position
        let storageSecondHalfCount = count - storageFirstHalfCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.advanced(by: storageFirstHalfCount).initialize(from: other)
        
        let next = storageFirstHalfCount > 0 ? _moveInitializeFromElements(advancedToBufferIndex: head, count: storageFirstHalfCount, to: newBuff) : head
        if storageSecondHalfCount > 0 {
            _moveInitializeFromElements(advancedToBufferIndex: next, count: storageSecondHalfCount, to: newBuff.advanced(by: storageFirstHalfCount + otherCount))
        }
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    private func _fastPrepend<C: Collection>(_ other: C) where Element == C.Iterator.Element {
        let otherCount = other.count
        guard otherCount > 0 else { return }
        
        let newCapacity = count + otherCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.initialize(from: other)
        
        _moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff.advanced(by: otherCount))
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    private func _fastAppend<C: Collection>(_ other: C) where Element == C.Iterator.Element {
        let otherCount = other.count
        guard otherCount > 0 else { return }
        
        let newCapacity = count + otherCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.advanced(by: count).initialize(from: other)
        
        _moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    private func _fastRemove(at position: Int, count k: Int) {
        guard k > 0 else { return }
        
        if position == 0 && k == count {
            removeAll(keepingCapacity: false)
            
            return
        }
        
        let storageFirstHalfCount = position
        let storageSecondHalfCount = count - (position + k)
        let newCapacity = count - k
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        var next = storageFirstHalfCount > 0 ? _moveInitializeFromElements(advancedToBufferIndex: head, count: storageFirstHalfCount, to: newBuff) : head
        next = _deinitializeElements(advancedToBufferIndex: next, count: k)
        if storageSecondHalfCount > 0 {
            _moveInitializeFromElements(advancedToBufferIndex: next, count: storageSecondHalfCount, to: newBuff.advanced(by: storageFirstHalfCount))
        }
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
    private func _fastReplace<C: Collection>(subrange: Range<Int>, with other: C) where Element == C.Iterator.Element {
        let otherCount = other.count
        let storageFirstHalfCount = subrange.lowerBound
        let storageSecondHalfCount = count - (subrange.lowerBound + subrange.count)
        let newCapacity = count - subrange.count + otherCount
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        newBuff.advanced(by: storageFirstHalfCount).initialize(from: other)
        
        let subrangeBuffIdx = storageFirstHalfCount > 0 ? _moveInitializeFromElements(advancedToBufferIndex: head, count: storageFirstHalfCount, to: newBuff) : head
        let next = _deinitializeElements(advancedToBufferIndex: subrangeBuffIdx, count: subrange.count)
        if storageSecondHalfCount > 0 {
            _moveInitializeFromElements(advancedToBufferIndex: next, count: storageSecondHalfCount, to: newBuff.advanced(by: storageFirstHalfCount + otherCount))
        }
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        count = newCapacity
        head = 0
        tail = 0
    }
    
}

// MARK: - Index helpers
extension CircularQueueStorage {
    @inline(__always)
    private func _checkSubscriptBounds(for position: Int) {
        precondition(position >= 0 && position < count, "subscript index out of bounds")
    }
    
    @inline(__always)
    private func _bufferIndex(from index: Int) -> Int {
        let advanced = head + index
        
        return advanced < capacity ? advanced : advanced - capacity
    }
    
    @inline(__always)
    private func _incrementIndex(_ index: Int) -> Int {
        index == capacity - 1 ? 0 : index + 1
    }
    
    @inline(__always)
    private func _decrementIndex(_ index: Int) -> Int {
        index == 0 ? capacity - 1 : index - 1
    }
    
}

// MARK: - Buffer helpers
extension CircularQueueStorage {
    @inline(__always)
    private func _fastResizeElements(to newCapacity: Int) {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)
        
        _moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        capacity = newCapacity
        head = 0
        tail = _incrementIndex(count - 1)
    }
    
    @inline(__always)
    private func _fastRotateBufferHeadToZero() {
        let newBuff = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        
        _moveInitializeFromElements(advancedToBufferIndex: head, count: count, to: newBuff)
        elements.deallocate()
        elements = newBuff
        head = 0
        tail = _incrementIndex(count - 1)
    }
    
    @inline(__always)
    @discardableResult
    private func _moveInitializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            destination.moveInitialize(from: elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).moveInitialize(from: elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.moveInitialize(from: elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _initializeFromElements(advancedToBufferIndex startIdx: Int, count k: Int, to destination: UnsafeMutablePointer<Element>) -> Int {
        let nextBufferIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            destination.initialize(from: elements.advanced(by: startIdx), count: segmentCount)
            destination.advanced(by: segmentCount).initialize(from: elements, count: k - segmentCount)
            nextBufferIdx = k - segmentCount
        } else {
            destination.initialize(from: elements.advanced(by: startIdx), count: k)
            nextBufferIdx = startIdx + k
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _initializeElements<C: Collection>(advancedToBufferIndex startIdx: Int, from newElements: C) -> Int where C.Iterator.Element == Element {
        let nextBufferIdx: Int
        if startIdx + newElements.count > capacity {
            let segmentCount = capacity - startIdx
            let firstSplitRange = newElements.startIndex..<newElements.index(newElements.startIndex, offsetBy: segmentCount)
            let secondSplitRange = newElements.index(newElements.startIndex, offsetBy: segmentCount)..<newElements.endIndex
            elements.advanced(by: startIdx).initialize(from: newElements[firstSplitRange])
            elements.initialize(from: newElements[secondSplitRange])
            nextBufferIdx = newElements.count - segmentCount
        } else {
            elements.advanced(by: startIdx).initialize(from: newElements)
            nextBufferIdx = startIdx + newElements.count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _moveInitializeToElements(advancedToBufferIndex startIdx: Int, from other: UnsafeMutablePointer<Element>, count k: Int) -> Int {
        let nextBuffIdx: Int!
        if startIdx + k > capacity {
            let segmentCount = capacity - startIdx
            elements.advanced(by: startIdx).moveInitialize(from: other, count: segmentCount)
            elements.moveInitialize(from: other.advanced(by: segmentCount), count: k - segmentCount)
            nextBuffIdx = k - segmentCount
        } else {
            elements.advanced(by: startIdx).moveInitialize(from: other, count: k)
            nextBuffIdx = startIdx + k
        }
        
        return nextBuffIdx == capacity ? 0 : nextBuffIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _deinitializeElements(advancedToBufferIndex startIdx : Int, count: Int) -> Int {
        let nextBufferIdx: Int!
        if startIdx + count > capacity {
            let segmentCount = capacity - startIdx
            elements.advanced(by: startIdx).deinitialize(count: segmentCount)
            elements.deinitialize(count: count - segmentCount)
            nextBufferIdx = count - segmentCount
        } else {
            elements.advanced(by: startIdx).deinitialize(count: count)
            nextBufferIdx = startIdx + count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
    @inline(__always)
    @discardableResult
    private func _assignElements<C: Collection>(advancedToBufferIndex startIdx: Int, from newElements: C) -> Int where Element == C.Iterator.Element {
        let nextBufferIdx: Int
        if startIdx + newElements.count > capacity {
            let segmentCount = capacity - startIdx
            let firstSplitRange = newElements.startIndex..<newElements.index(newElements.startIndex, offsetBy: segmentCount)
            let secondSplitRange = newElements.index(newElements.startIndex, offsetBy: segmentCount)..<newElements.endIndex
            elements.advanced(by: startIdx).assign(from: newElements[firstSplitRange])
            elements.assign(from: newElements[secondSplitRange])
            nextBufferIdx = newElements.count - segmentCount
        } else {
            elements.advanced(by: startIdx).assign(from: newElements)
            nextBufferIdx = startIdx + newElements.count
        }
        
        return nextBufferIdx == capacity ? 0 : nextBufferIdx
    }
    
}

// MARK: - Pointers helpers
extension UnsafeMutablePointer {
    fileprivate func initialize<C: Collection>(from newElements: C) where C.Iterator.Element == Pointee {
        guard !newElements.isEmpty else { return }
        
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    self.initialize(from: buff.baseAddress!, count: buff.count)
                    
                    return true
            })
        else {
            var i = 0
            for element in newElements {
                self.advanced(by: i).initialize(to: element)
                i += 1
            }
            
            return
        }
    }
    
    fileprivate func assign<C: Collection>(from newElements: C) where Pointee == C.Iterator.Element {
        guard !newElements.isEmpty else { return }
        
        guard
            let _ = newElements
                .withContiguousStorageIfAvailable({ buff -> Bool in
                    self.assign(from: buff.baseAddress!, count: buff.count)
                    
                    return true
                })
        else {
            var i = 0
            for element in newElements {
                self.advanced(by: i).pointee = element
                i += 1
            }
            
            return
        }
    }
    
}

// MARK: - Specific internal methods for testing purposes only:
#if DEBUG
extension CircularQueueStorage {
    static func testInstanceWithElementsWrappingAroundCapacity(headShift: Int, elements: [Element]) -> CircularQueueStorage {
        precondition(headShift > 0)
        let capacity = headShift < elements.count ? elements.count : headShift + 1
        let elementsToStore = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        guard
            elements.count > 0
        else {
            
            return CircularQueueStorage(elements: elementsToStore, capacity: capacity, count: 0, head: headShift, tail: headShift)
        }
        
        let tail = capacity == elements.count ? headShift :  headShift - 1
        elements.withUnsafeBufferPointer { buffer in
            let firstChunkCount = capacity - headShift
            let firstChunk = buffer[0..<firstChunkCount]
            let secondChunk = buffer[firstChunkCount..<buffer.endIndex]
            elementsToStore.advanced(by: headShift)
                .initialize(from: firstChunk)
            elementsToStore.initialize(from: secondChunk)
        }
        
        return CircularQueueStorage(elements: elementsToStore, capacity: capacity, count: elements.count, head: headShift, tail: tail)
    }
    
}
#endif


