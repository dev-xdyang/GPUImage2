import Foundation

public var standardProcessingQueue: DispatchQueue {
    if #available(iOS 10, OSX 10.10, *) {
        return DispatchQueue.global(qos: .default)
    } else {
        return DispatchQueue.global(priority: .default)
    }
}

public var lowProcessingQueue: DispatchQueue {
    if #available(iOS 10, OSX 10.10, *) {
        return DispatchQueue.global(qos: .background)
    } else {
        return DispatchQueue.global(priority: .low)
    }
}

func runAsynchronouslyOnMainQueue(_ mainThreadOperation: @escaping () -> Void) {
    if Thread.isMainThread {
        mainThreadOperation()
    } else {
        DispatchQueue.main.async(execute: mainThreadOperation)
    }
}

func runOnMainQueue(_ mainThreadOperation: () -> Void) {
    if Thread.isMainThread {
        mainThreadOperation()
    } else {
        DispatchQueue.main.sync(execute: mainThreadOperation)
    }
}

func runOnMainQueue<T>(_ mainThreadOperation: () -> T) -> T {
    var returnedValue: T!
    runOnMainQueue {
        returnedValue = mainThreadOperation()
    }
    return returnedValue
}

// MARK: -

// MARK: SerialDispatch extension

public protocol SerialDispatch {
    var serialDispatchQueue: DispatchQueue { get }
    var dispatchQueueKey: DispatchSpecificKey<Int> { get }
    func makeCurrentContext()
}

public extension SerialDispatch {
    func runOperationAsynchronously(_ operation: @escaping () -> Void) {
        serialDispatchQueue.async {
            self.makeCurrentContext()
            operation()
        }
    }

    func runOperationSynchronously(_ operation: () -> Void) {
        // TODO: Verify this works as intended
        if DispatchQueue.getSpecific(key: dispatchQueueKey) == 81 {
            operation()
        } else {
            serialDispatchQueue.sync {
                self.makeCurrentContext()
                operation()
            }
        }
    }

    func runOperationSynchronously(_ operation: () throws -> Void) throws {
        var caughtError: Error?
        runOperationSynchronously {
            do {
                try operation()
            } catch {
                caughtError = error
            }
        }
        if caughtError != nil { throw caughtError! }
    }

    func runOperationSynchronously<T>(_ operation: () throws -> T) throws -> T {
        var returnedValue: T!
        try runOperationSynchronously {
            returnedValue = try operation()
        }
        return returnedValue
    }

    func runOperationSynchronously<T>(_ operation: () -> T) -> T {
        var returnedValue: T!
        runOperationSynchronously {
            returnedValue = operation()
        }
        return returnedValue
    }
}