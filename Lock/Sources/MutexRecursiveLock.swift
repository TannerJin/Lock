//
//  MutexRecursiveLock.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// MARK: 递归互斥锁
class MutexRecursiveLock {
    private var thread: Int = -1
    private var recursiveCount = 0
    
    private var waitThreads = [thread_t]()
    private var waitThreadsValue: Int32 = 0

    public func lock() {
        while !OSAtomicCompareAndSwapLong(-1, Int(mach_thread_self()), &thread) {
            if thread == mach_thread_self() {
                break
            }
            yield()
        }
        recursiveCount += 1
    }

    public func unlock() {
        recursiveCount -= 1
        if recursiveCount == 0 {
            thread = -1
            resume()
        }
    }
    
    private func yield() {
        let thread = mach_thread_self()
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        waitThreads.append(thread)
        waitThreadsValue = 0
        thread_suspend(thread)
    }
    
    private func resume() {
        var thread: thread_t?
        
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        if waitThreads.count > 0 {
            thread = waitThreads.removeFirst()      // FIFO
        }
        waitThreadsValue = 0
        
        if thread != nil { thread_resume(thread!) }
    }
}


// MARK: Test
func TestMutexRecursiveLock() {
    let concurrentCount = 2000
    let lock = MutexRecursiveLock()
    let recursiveCount = 5
    var value = 0

    let queue = DispatchQueue(label: "MutexRecursiveLockQueue", qos: .default, attributes: .concurrent)
    
    for _ in 0..<concurrentCount {
        queue.async {
            for _ in 0..<recursiveCount {
                lock.lock()
                value += 1
            }
            for _ in 0..<recursiveCount {
                lock.unlock()
            }
        }
    }

    queue.sync(flags: .barrier) { () -> Void in
        assert(value == concurrentCount * recursiveCount)
        print("MutexRecursiveLock Test Success")
    }
}
