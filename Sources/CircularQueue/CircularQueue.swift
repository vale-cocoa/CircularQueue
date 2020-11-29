//
//  CircularQueue.swift
//  CircularQueue
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

import Queue

/// A queue data structure adopting the *FIFO* (first-in, first-out) policy and able to store a predefined
/// and static number of elements only; that is attempting to enqueue new elements when its storage is full,
/// then older elements will be overwritten.
///
/// The `CircularQueue` type  is an ordered, random-access collection, it basically presents the same
/// interface and behavior of an array (including value semantics), but with the advantage
/// of an amortized O(1) complexity for operations on the first position of its storage,
/// rather than O(*n*) as arrays do.
/// A `CircularQueue` is a *FIFO* (first in, first out) queue, thus it'll dequeue elements respecting the order in
/// which they were enqueued. This queue also doesn't resize automatically its storage when full, thus new elements
/// enqueued when there is no more available storage space will result in overwriting older elements:
///
///     var queue = CircularQueue<Int>(1...10)
///
///     print(queue)
///     // Prints: "CircularQueue(capacity: 10)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
///     print(queue.isFull)
///     // Prints: "true"
///
///     queue.enqueue(11)
///
///     print(queue)
///     Prints: CircularQueue(capacity: 10)["2, 3, 4, 5, 6, 7, 8, 9, 10, 11"]
///     print(queue.isFull)
///     // Prints: "true"
///
/// On the other hand, using `RangeReplaceableCollection` methods, will affect the capacity of the circular queue,
/// allowing the operation to take effect as it would on an array:
///
///     var queue = CircularQueue<Int>(1...10)
///
///     print(queue)
///     // Prints: "CircularQueue(capacity: 10)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
///     print(queue.isFull)
///     // Prints: "true"
///
///     queue.append(11)
///
///     print(queue)
///     // Prints: CircularQueue(capacity: 11)["1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11"]
///     print(queue.isFull)
///     // Prints: "true"
///
///     queue.removeFirst(2)
///
///     print(queue)
///     //Prints: CircularQueue(capacity: 9)["3, 4, 5, 6, 7, 8, 9, 10, 11"]
///     print(queue.isFull)
///     // Prints: "true"
///
/// By the way the storage capacity of a circular queue instance can always be increased statically via the
/// `reserveCapacity(_:)` method:
///
///     var queue = CircularQueue<Int>(1...10)
///
///     print(queue)
///     // Prints: "CircularQueue(capacity: 10)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
///     print(queue.isFull)
///     // Prints: "true"
///
///     queue.reserveCapacity(5)
///
///     print(queue.isFull)
///     // Prints: "false"
///
///     queue.append(11)
///
///     print(queue)
///     //Prints: CircularQueue(capacity: 15)["1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11"]
///     print(queue.isFull)
///     // Prints: "false"
///
/// The `CircularQueue` type presents also its own interface for executing operations on both its storage ends,
/// the *front* and the *back*:
///
///     var queue = CircularQueue<Int>(1...10)
///     queue.reserveCapacity(2)
///
///     print(queue)
///     // Prints: "CircularQueue(capacity: 12)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
///     print(queue.isFull)
///     // Prints: "false"
///
///     queue.pushFront(0)
///
///     print(queue)
///     // Prints: "CircularQueue(capacity: 12)[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
///
///     queue.pushBack(11)
///
///      print(queue)
///     // Prints: "CircularQueue(capacity: 12)[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]"
///
///     queue.popBack()
///
///     print(queue)
///     // Prints: "CircularQueue(capacity: 12)[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
///
///     queue.popFront()
///
///     print(queue)
///     // Prints: "CircularQueue(capacity: 12)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
///
public struct CircularQueue<Element> {
    private(set) var storage: CircularQueueStorage<Element>
    
    /// Returns a new empty `CircularQueue` instance, with a `capacity` value of `0`.
    ///
    /// - Returns: A new empty `CircularQueue` instance, initialized with a `capacity` value of `0`.
    public init() {
        self.storage = CircularQueueStorage()
    }
    
    /// Returns a new empty `CircularQueue` instance, able to hold the specified count of elements.
    ///
    /// - Parameter _:  An `Int` value representing the number of elements the instance can hold.
    ///                 **Must not be negative**.
    /// - Returns:  A new empty queue instance, able to hold the specified count of elements.
    public init(_ k: Int = 0) {
        self.storage = CircularQueueStorage(k)
    }
    
    /// Returns a new `CircularQueue` instance initialized with the contents of the given
    /// sequence of elements, with a `capacity` value equal to the count of the elements of the
    /// specified sequence.
    ///
    /// - Parameter _: The sequence of elements to store. **Must be a finite sequence**.
    /// - Returns:  A new `CircularQueue` instance containing all the elements of the given
    ///             sequence, stored in the same order of the sequence iteration, with a `capacity` value equal
    ///             to the count of elements stored in the specified sequence.
    public init<S: Sequence>(_ elements: S) where S.Iterator.Element == Element {
        guard
            let other = elements as? Self
        else {
            self.storage = CircularQueueStorage(elements)
            
            return
        }
        
        self.storage = other.storage
    }
    
    public init(repeating repeatedValue: Element, count: Int) {
        self.storage = CircularQueueStorage(repeating: repeatedValue, count: count)
    }
    
}

// MARK: - Computed properties
extension CircularQueue {
    /// The total number of elements this queue can store.
    public var capacity: Int { storage.capacity }
    
    /// The number of remaining free slots in this instance for storing additional elements.
    ///
    /// - Complexity: O(1)
    public var residualCapacity: Int { storage.residualCapacity }
    
    /// Whether this queue's storage is full or not.
    ///
    /// - Complexity: O(1)
    public var isFull: Bool { storage.isFull }
    
}

// MARK: - Collection protocols conformance
extension CircularQueue: MutableCollection, BidirectionalCollection, RandomAccessCollection {
    public typealias Index = Int
    
    public typealias Indices = CountableRange<Int>
    
    public typealias Iterator = IndexingIterator<CircularQueue<Element>>
    
    public typealias SubSequence = CircularQueueSlice<Element>
    
    public var count: Int { storage.count }
    
    public var underestimatedCount: Int { storage.count }
    
    public var isEmpty: Bool { storage.isEmpty }
    
    public var startIndex: Int { 0 }
    
    public var endIndex: Int { storage.count }
    
    public func index(after i: Int) -> Int {
        i + 1
    }
    
    public func formIndex(after i: inout Int) {
        i += 1
    }
    
    public func index(before i: Int) -> Int {
        i - 1
    }
    
    public func formIndex(before i: inout Int) {
        i -= 1
    }
    
    public func index(_ i: Int, offsetBy distance: Int) -> Int {
        i + distance
    }
    
    public func index(_ i: Int, offsetBy distance: Int, limitedBy limit: Int) -> Int? {
        let l = limit - i
        
        if distance > 0 ? (l >= 0 && l < distance) : (l <= 0 && distance < l) {
            
            return nil
        }
        
        return i + distance
    }
    
    public func distance(from start: Int, to end: Int) -> Int {
        end - start
    }
    
    public var first: Element? {
        guard !isEmpty else { return nil }
        
        return storage[0]
    }
    
    public var last: Element? {
        guard !isEmpty else { return nil }
        
        return storage[storage.count - 1]
    }
    
    public subscript(position: Int) -> Element {
        get {
            storage[position]
        }
        
        set {
            _makeUnique()
            storage[position] = newValue
        }
    }
    
    public subscript(bounds: Range<Int>) -> CircularQueueSlice<Element> {
        get {
            CircularQueueSlice(base: self, bounds: bounds)
        }
        
        set {
            replaceSubrange(bounds, with: newValue)
        }
    }
    
    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R? {
        try storage.withUnsafeBufferPointer(body)
    }
    
    public mutating func withContiguousMutableStorageIfAvailable<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) rethrows -> R? {
        _makeUnique()
        
        // Ensure that body can't invalidate the storage or its
        // bounds by moving self into a temporary working CicrularQueue.
        // NOTE: The stack promotion optimization that keys of the
        // "circularQueue.withContiguousMutableStorageIfAvailable"
        // semantics annotation relies on the Deque buffer not
        // being able to escape in the closure.
        // It can do this because we swap the Deque buffer in self
        // with an empty buffer here.
        // Any escape via the address of self in the closure will
        // therefore escape the empty Deque.
        var work = CircularQueue()
        (work, self) = (self, work)
        
        // Put back in place the Deque
        defer {
            (work, self) = (self, work)
        }
        
        // Invoke body taking advantage of CircularQueueStorage's
        // withUnsafeMutableBufferPointer(_:) method.
        return try work.storage
            .withUnsafeMutableBufferPointer(body)
    }
    
    // MARK: - Functional methods
    public func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        try storage.allSatisfy(predicate)
    }
    
    public func forEach(_ body: (Element) throws -> ()) rethrows {
        try storage.forEach(body)
    }
    
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        try compactMap { try isIncluded($0) ? $0 : nil }
    }
    
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        var result = [T]()
        try storage.forEach { element in
            let transformed = try transform(element)
            result.append(transformed)
        }
        
        return result
    }
    
    public func flatMap<SegmentOfResult>(_ transform: (Element) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult: Sequence {
        var result = [SegmentOfResult.Element]()
        try storage.forEach {
            result.append(contentsOf: try transform($0))
        }
        
        return result
    }
    
    @available(swift, deprecated: 4.1, renamed: "compactMap(_:)", message: "Please use compactMap(_:) for the case where closure returns an optional value")
    public func flatMap<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult] {
        
        return try compactMap(transform)
    }
    
    public func compactMap<T>(_ transform: (Element) throws -> T?) rethrows -> [T] {
        var result = [T]()
        try storage.forEach { element in
            try transform(element).map { result.append($0) }
        }
        
        return result
    }
    
    public func reduce<Result>(into initialResult: Result, _ updateAccumulatingResult: (inout Result, Element) throws -> ()) rethrows -> Result {
        var finalResult = initialResult
        try storage.forEach {
            try updateAccumulatingResult(&finalResult, $0)
        }
        
        return finalResult
    }
    
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, Element) throws -> Result) rethrows -> Result {
        try reduce(into: initialResult) { accumulator, element in
            accumulator = try nextPartialResult(accumulator, element)
        }
    }
    
}

// MARK: - RangeReplaceableCollection
extension CircularQueue: RangeReplaceableCollection {
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "minimumCapacity must not be negative")
        let additionalSpots = minimumCapacity - residualCapacity
        guard additionalSpots > 0 else { return }
        
        _makeUnique(additionalCapacity: additionalSpots)
    }
    
    public mutating func replaceSubrange<C: Collection>(_ subrange: Range<Int>, with other: C) where Element == C.Iterator.Element {
        if subrange.count == 0 && other.count == 0 { return }
        
        _makeUnique()
        storage.replaceSubrange(subrange, with: other)
    }
    
    public mutating func insert(_ newElement: Element, at i: Int) {
        _makeUnique()
        storage.replaceSubrange(i..<i, with: CollectionOfOne(newElement))
    }
    
    public mutating func insert<C: Collection>(contentsOf newElements: C, at i: Int) where Element == C.Iterator.Element {
        guard newElements.count > 0 else { return }
        
        _makeUnique()
        storage.replaceSubrange(i..<i, with: newElements)
    }
    
    public mutating func append(_ newElement: Self.Element) {
        _makeUnique()
        storage.replaceSubrange(storage.count..<storage.count, with: CollectionOfOne(newElement))
    }
    
    public mutating func append<S>(contentsOf newElements: S) where S : Sequence, Self.Element == S.Iterator.Element {
        _makeUnique()
        storage.append(contentsOf: newElements)
    }
    
    public mutating func removeSubrange(_ bounds: Range<Int>) {
        guard bounds.count > 0 else { return }
        
        _makeUnique()
        storage.replaceSubrange(bounds, with: [])
    }
    
    public mutating func remove(at i: Int) -> Element {
        defer {
            self._makeUnique()
            self.storage.replaceSubrange(i..<(i + 1), with: [])
        }
        
        return self[i]
    }
    
    public mutating func removeFirst() -> Element {
        remove(at: startIndex)
    }
    
    public mutating func removeLast() -> Element {
        remove(at: endIndex - 1)
    }
    
    public mutating func removeFirst(_ k: Int) {
        precondition(k >= 0 && k <= count, "k must not be negative and less than or equal count")
        _makeUnique()
        replaceSubrange(0..<k, with: [])
    }
    
    public mutating func removeLast(_ k: Int) {
        precondition(k >= 0 && k <= count, "k must not be negative and less than or equal count")
        _makeUnique()
        let position = storage.count - k
        storage.replaceSubrange(position..<count, with: [])
    }
    
    @available(*, deprecated, renamed: "removeAll(keepingCapacity:)")
    public mutating func removeAll(keepCapacity: Bool) {
        removeAll(keepingCapacity: keepCapacity)
    }
    
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        _makeUnique()
        storage.removeAll(keepingCapacity: keepCapacity)
    }
    
    @discardableResult
    public mutating func popFirst() -> Element? {
        guard
            !isEmpty
        else { return nil }
        
        return removeFirst()
    }
    
    @discardableResult
    public mutating func popLast() -> Element? {
        guard
            !isEmpty
        else { return nil }
        
        return removeLast()
    }
    
}

// MARK: - ExpressibleByArrayLiteral conformance
extension CircularQueue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
}

// MARK: - Specific CircularQueue methods
extension CircularQueue {
    /// Removes and returns, if present, the first element of the circular queue.
    ///
    /// - Returns: Either the element stored at the initial position of the circular queue, or nil when empty.
    /// - Complexity: O(1)
    @discardableResult
    public mutating func popFront() -> Element? {
        _makeUnique()
        
        return storage.popFront()
    }
    
    /// Stores the specified element as the first one.
    ///
    /// - Parameter _: The new element to store at the initial position of the circular queue storage.
    /// - Complexity: O(1)
    /// - Note: When the storage is full, it will first drop the element stored at last position in the storage to make room
    ///         for the new element.
    public mutating func pushFront(_ newElement: Element) {
        _makeUnique()
        storage.pushFront(newElement)
    }
    
    /// Sequentially pushes each element contained in the specified sequence at the initial storage position.
    ///
    /// - Parameter contentsOf: The sequence of elements to push on the front of the circular queue storage.
    /// - Note: When the storage is full or if it will become full during the operation, it will drop elements from the last
    ///         position of the storage to make room for new element to store from the sequence.
    public mutating func pushFront<S: Sequence>(contentsOf newElements: S) where Element == S.Iterator.Element {
        _makeUnique()
        storage.pushFront(contentsOf: newElements)
    }
    
    /// Removes and returns, if present, the last element of the circular queue.
    ///
    /// - Returns: Either the element stored at the last position of the circular queue, or nil when empty.
    /// - Complexity: O(1)
    @discardableResult
    public mutating func popBack() -> Element? {
        _makeUnique()
        
        return storage.popBack()
    }
    
    /// Stores the specified element as the last one.
    ///
    /// - Parameter _: The new element to store at the last position of the circular queue storage.
    /// - Complexity: O(1)
    /// - Note: When the storage is full, it will first drop the element stored at initial position in the storage to make room
    ///         for the new element.
    public mutating func pushBack(_ newElement: Element) {
        _makeUnique()
        storage.pushBack(newElement)
    }
    
    /// Sequentially pushes each element contained in the specified sequence at the last storage position.
    ///
    /// - Parameter contentsOf: The sequence of elements to push on the back of the circular queue storage.
    /// - Note: When the storage is full or if it will become full during the operation, it will drop elements from the initial
    ///         position of the storage to make room for new element to store from the sequence.
    public mutating func pushBack<S: Sequence>(contentsOf newElements: S) where Element == S.Iterator.Element {
        _makeUnique()
        storage.pushBack(contentsOf: newElements)
    }
    
}

// MARK: - Queue conformance
extension CircularQueue: Queue {
    public func peek() -> Element? {
        first
    }
    
    @discardableResult
    public mutating func dequeue() -> Element? {
        popFront()
    }
    
    /// Stores specified element in this queue.
    /// Eventually makes room for the new element when the storage is full by dropping the oldest stored element.
    ///
    /// - Parameter _: The element to store.
    /// - Complexity: O(1)
    /// - Note: same as using `pushBack(_:)`.
    public mutating func enqueue(_ newElement: Element) {
        pushBack(newElement)
    }
    
    /// Stores in this queue all elements contained in the given sequence.
    /// Eventually makes room for the new elements when the storage is full by dropping enough oldest stored elements.
    ///
    /// - Parameter contentsOf: The sequence of elements to store.
    /// - Note: Same as using `pushBack(contentsOf:)`
    public mutating func enqueue<S>(contentsOf newElements: S) where S : Sequence, Self.Element == S.Element {
        pushBack(contentsOf: newElements)
    }
    
}

// MARK: - Equatable Conformance
extension CircularQueue: Equatable where Element: Equatable {
    public static func ==(lhs: CircularQueue<Element>, rhs: CircularQueue<Element>) -> Bool {
        guard lhs.storage !== rhs.storage else { return true }
        
        guard
            lhs.count == rhs.count
        else { return false }
        
        for idx in 0..<lhs.count where lhs[idx] != rhs[idx] {
            
            return false
        }
        
        return true
    }
    
}

// MARK: - Hashable Conformance
extension CircularQueue: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(capacity)
        hasher.combine(count)
        forEach { hasher.combine($0) }
    }
    
}

// MARK: - Codable conformance
extension CircularQueue: Codable where Element: Codable {
    public enum Error: Swift.Error {
        case decodingError(String)
    }
    
    private enum CodingKeys: String, CodingKey {
        case storage
        case capacity
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let elements = map { $0 }
        try container.encode(elements, forKey: .storage)
        try container.encode(capacity, forKey: .capacity)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let capacity = try container.decode(Int.self, forKey: .capacity)
        let elements = try container.decode(Array<Element>.self, forKey: .storage)
        let residualCapacity = capacity - elements.count
        guard
            residualCapacity >= 0
        else {
            throw Error.decodingError("capacity is less greater than stored elements count")
        }
        
        self.storage = CircularQueueStorage(elements)
        self.storage.reserveCapacity(residualCapacity)
    }
    
}

// MARK: CustomStringConvertible and CustomDebugStringConvertible conformances
extension CircularQueue: CustomStringConvertible, CustomDebugStringConvertible {
    private func makeDescription(debug: Bool) -> String {
        var result = debug ? "\(String(reflecting: CircularQueue.self))((capacity: \(capacity))[" : "CircularQueue(capacity: \(capacity))["
            var first = true
            for item in self {
                if first {
                    first = false
                } else {
                    result += ", "
                }
                if debug {
                    debugPrint(item, terminator: "", to: &result)
                }
                else {
                    print(item, terminator: "", to: &result)
                }
            }
            result += debug ? "])" : "]"
            return result
        }

    public var description: String {
        return makeDescription(debug: false)
    }
    
    public var debugDescription: String {
        return makeDescription(debug: true)
    }
    
}

// MARK: - CircularQueue private interface
// MARK: - Uniqueness for value semantics
extension CircularQueue {
    private var _isUnique: Bool {
        mutating get {
            isKnownUniquelyReferenced(&storage)
        }
    }
    
    private mutating func _makeUnique(additionalCapacity: Int = 0) {
        if !_isUnique {
            self.storage = storage.copy(additionalCapacity)
        } else if additionalCapacity > 0 {
            storage.reserveCapacity(residualCapacity + additionalCapacity)
        }
    }
    
}

