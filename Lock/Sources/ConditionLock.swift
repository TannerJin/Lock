//
//  ContionLock.swift
//  Lock
//
//  Created by jintao on 2019/11/27.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// 条件锁

public class ConditionLock {
    public var condition: Int64
    private var value: Int32 = 0
    
    private var waitThreads = [thread_t]()
    private var waitThreadsValue: Int32 = 0
    
    public init(condition: Int64) {
        self.condition = condition
    }
    
    public func lock() {
        while !OSAtomicCompareAndSwap32(0, 1, &value) {
            yield()
        }
    }
    
    public func unlock() {
        while true {
            let oldValue = OSAtomicAdd32(0, &value)
            if OSAtomicCompareAndSwap32(oldValue, 0, &value) {
                break
            }
        }
        resume()
    }
    
    public func lock(whenCondition condition: Int64) {
        while true {
            if OSAtomicCompareAndSwap32(0, 1, &value) {   // 先抢占锁
                if OSAtomicAdd64(0, &self.condition) == condition {  // 再判断条件是否符合
                    break
                } else {
                    unlock()    //  条件不匹配, 抢占锁后释放
                }
            }
            yield()
        }
    }
    
    public func unlock(withCondition condition: Int64) {
        self.condition = condition
        unlock()
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

func TestConditionLock() {
    
}
