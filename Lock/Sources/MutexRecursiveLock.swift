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
            if thread == mach_thread_self() || !yield() {
                break
            }
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
    
    private func yield() -> Bool {
        let selfThread = mach_thread_self()
        
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        
        if OSAtomicCompareAndSwapLong(-1, Int(selfThread), &thread) {     // 防止竞争bug
            waitThreadsValue = 0
            return false
        }
        
        waitThreads.append(selfThread)
        waitThreadsValue = 0
        
        var ret: kern_return_t = -1
        repeat {
           ret = thread_suspend(selfThread)
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
func TestMutexRecursiveLock() {
    let concurrentCount = 500
    let lock = MutexRecursiveLock()
    let recursiveCount = 5
    var value = 0

    let queue = DispatchQueue(label: "MutexRecursiveLockQueue", qos: .userInteractive, attributes: .concurrent)
    
    for _ in 0..<concurrentCount {
        queue.async {
            Thread.sleep(forTimeInterval: 0.01)
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
