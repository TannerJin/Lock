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
    private var lockValue: Int32 = 0
    
    private var waitThreads = [thread_t]()
    private var waitThreadsValue: Int32 = 0
    
    public init(condition: Int64) {
        self.condition = condition
    }
    
    public func lock() {
        while !OSAtomicCompareAndSwap32(0, 1, &lockValue) {
            if !yield(tryGetLock: { () -> Bool in
                return OSAtomicCompareAndSwap32(0, 1, &lockValue)
            }) { break }
        }
    }
    
    public func lock(whenCondition condition: Int64) {
        while true {
            let getLock = { () -> Bool in
                if OSAtomicCompareAndSwap32(0, 1, &self.lockValue) {        // 先抢占锁
                    if OSAtomicAdd64(0, &self.condition) == condition {     // 再判断条件是否符合
                        return true
                    }
                    self.lockValue = 0      //  条件不匹配, 抢占锁后释放
                }
                return false
            }
            
            if getLock() {
                break
            } else {
                if !yield(tryGetLock: getLock) { break }
            }
        }
    }
    
    public func unlock() {
        lockValue = 0
        resume()
    }
    
    public func unlock(withCondition condition: Int64) {
        self.condition = condition
        unlock()
    }
    
    private func yield(tryGetLock: ()->Bool) -> Bool {
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
       
        // 防止竞争bug(当获取到锁的线程释放锁了，调用完resume()了。但还有没获取锁的线程正在执行yield()，但未加入等待队列中，造成该线程永远在等待队列)
        if tryGetLock() {
            waitThreadsValue = 0
            return false
        }
       
        let thread = mach_thread_self()
        waitThreads.append(thread)
        waitThreadsValue = 0
       
        var ret: kern_return_t = -1
        repeat {
            ret = thread_suspend(thread)
        } while ret != KERN_SUCCESS
       
        return true
    }
    
    private func resume() {
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        defer {
            waitThreadsValue = 0
        }
        
        if waitThreads.count > 0 {
            let thread = waitThreads.removeFirst()     // FIFO
            var ret: kern_return_t = -1
            while true {
                ret = thread_resume(thread)
                if ret == KERN_SUCCESS {        // 极极少数情况下, 等待队列中的thread正在执行上面的yield中的thread_suspend函数，此时线程还在running
                    break
                } else {
                    sched_yield()               // 让出一个时间片, 等待thread_suspend执行完
                }
            }
        }
    }
}


// MARK: Test

func TestConditionLock() {
    
}
