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
    private var thread: Int = -1  // valatile 或者使用load-linked指令加载该值
    private var recursive_count = 0
    
    public func lock() {
        let currentThread = Int(mach_thread_self())
        while !OSAtomicCompareAndSwapLong(-1, currentThread, &thread) {
            if thread == currentThread {
                break
            }
        }
        recursive_count += 1
    }
    
    public func unlock() {
        let currentThread = Int(mach_thread_self())
        if currentThread == thread {
            recursive_count -= 1
            if recursive_count == 0 {
                thread = -1
            }
        }
    }
}


// MARK: Test
func TestSpinRecursiveLock() {
    let concurrentCount = 2000
    let recursiveCount = 3
    let lock = SpinRecursiveLock()
    var value = 0

    let queue = DispatchQueue(label: "SpinRecursiveLockQueue", qos: .default, attributes: .concurrent)
    
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
        print("SpinRecursiveLock Test Success")
    }
}
