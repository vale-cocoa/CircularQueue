# CircularQueue

A queue data structure adopting the *FIFO* (first-in, first-out) policy and able to store a predefined
and static number of elements only; that is attempting to enqueue new elements when its storage is full,
then older elements will be overwritten.

The `CircularQueue` type  is an ordered, random-access collection, it basically presents the same
interface and behavior of an array (including value semantics), but with the advantage
of an amortized O(1) complexity for operations on the first position of its storage,
rather than O(*n*) as arrays do.
A `CircularQueue` is a *FIFO* (first in, first out) queue, thus it'll dequeue elements respecting the order in which they were enqueued. This queue also doesn't resize automatically its storage when full, thus new elements enqueued when there is no more available storage space will result in overwriting older elements:

     var queue = CircularQueue<Int>(1...10)

     print(queue)
     // Prints: "CircularQueue(capacity: 10)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
     print(queue.isFull)
     // Prints: "true"

     queue.enqueue(11)

     print(queue)
     Prints: CircularQueue(capacity: 10)["2, 3, 4, 5, 6, 7, 8, 9, 10, 11"]
     print(queue.isFull)
     // Prints: "true"

On the other hand, using `RangeReplaceableCollection` methods, will affect the capacity of the circular queue, allowing the operation to take effect as it would on an array:

     var queue = CircularQueue<Int>(1...10)

     print(queue)
     // Prints: "CircularQueue(capacity: 10)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
     print(queue.isFull)
     // Prints: "true"

     queue.append(11)

     print(queue)
     // Prints: CircularQueue(capacity: 11)["1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11"]
     print(queue.isFull)
     // Prints: "true"

     queue.removeFirst(2)

     print(queue)
     //Prints: CircularQueue(capacity: 9)["3, 4, 5, 6, 7, 8, 9, 10, 11"]
     print(queue.isFull)
     // Prints: "true"

By the way the storage capacity of a circular queue instance can always be increased statically via the  `reserveCapacity(_:)` method:

     var queue = CircularQueue<Int>(1...10)

     print(queue)
     // Prints: "CircularQueue(capacity: 10)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
     print(queue.isFull)
     // Prints: "true"

     queue.reserveCapacity(5)

     print(queue.isFull)
     // Prints: "false"

     queue.append(11)

     print(queue)
     //Prints: CircularQueue(capacity: 15)["1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11"]
     print(queue.isFull)
     // Prints: "false"

The `CircularQueue` type presents also its own interface for executing operations on both its storage ends, the *front* and the *back*:

     var queue = CircularQueue<Int>(1...10)
     queue.reserveCapacity(2)

     print(queue)
     // Prints: "CircularQueue(capacity: 12)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
     print(queue.isFull)
     // Prints: "false"

     queue.pushFront(0)

     print(queue)
     // Prints: "CircularQueue(capacity: 12)[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"

     queue.pushBack(11)

      print(queue)
     // Prints: "CircularQueue(capacity: 12)[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]"

     queue.popBack()

     print(queue)
     // Prints: "CircularQueue(capacity: 12)[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"

     queue.popFront()

     print(queue)
     // Prints: "CircularQueue(capacity: 12)[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"

