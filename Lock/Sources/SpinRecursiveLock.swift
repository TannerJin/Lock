//
//  SpinRecursiveLock.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// 递归自旋锁

public class SpinRecursiveLock {
    private var thread: Int = -1
    private var recursive_count = 0
    
    public func lock() {
        while !OSAtomicCompareAndSwapLong(-1, Int(mach_thread_self()), &thread) {
            if thread == mach_thread_self() {
                break
            }
        }
        recursive_count += 1
    }
    
    public func unlock() {
        recursive_count -= 1
        if recursive_count == 0 {
            thread = -1
        }
    }
}


// MARK: Test
func TestSpinRecursiveLock() {
    let thread_count = 500
    let recursive_count = 3
    let lock = SpinRecursiveLock()
    var value = 0

    for _ in 0..<thread_count {
        Thread.detachNewThread {
            Thread.sleep(forTimeInterval: 1)  // for concurrent
            
            for _ in 0..<recursive_count {
                lock.lock()
                value += 1
            }
            // .
            // .
            // .
            for _ in 0..<recursive_count {
                lock.unlock()
            }
        }
    }

    RunLoop.current.run(until: Date() + 3)

    assert(value == thread_count*recursive_count)
}
