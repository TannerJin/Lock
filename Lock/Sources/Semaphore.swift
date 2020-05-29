//
//  Semaphore.swift
//  Lock
//
//  Created by jintao on 2019/11/26.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// MARK: 信号量

public class Semaphore {
    // >0: pass
    // =0: wait
    private var value: Int64
    
    private var waitThreads = [thread_t]()
    private var waitThreadsValue: Int32 = 0
    
    public init(value: Int64) {
        self.value = value
    }
    
    public func wait() {
        while true {
            let old_value = OSAtomicAdd64(0, &value)  // get value
            if old_value > 0 {
                let new_value = old_value - 1
                if OSAtomicCompareAndSwap64(old_value, new_value, &value) {
                    break
                }
            } else {
                yield()
            }
        }
    }
    
    @discardableResult
    public func signal() -> Int {
        let _value = OSAtomicIncrement64(&value)
        if _value > 0 {
            resume()
        }
        return Int(_value)
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
            thread = waitThreads.removeFirst()  // FIFO
        }
        waitThreadsValue = 0
        if thread != nil { thread_resume(thread!) }
    }
}


// MARK: Test
func TestSemaphore() {
    
}
