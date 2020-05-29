//
//  MutexLock.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// MARK: 互斥锁

public class MutexLock {
    private var lockValue: Int32 = 0
    private var waitThreads = [thread_t]()
    private var waitThreadsValue: Int32 = 0

    public func lock() {
        while !OSAtomicCompareAndSwap32(0, 1, &lockValue) {
            yield()
        }
    }

    public func unlock() {
        lockValue = 0
        resume()
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
            thread = waitThreads.removeFirst()
        }
        waitThreadsValue = 0
        
        if thread != nil { thread_resume(thread!) }
    }
}



// MARK: Test
func TestMutexLock() {
    let concurrentCount = 2000
    let lock = MutexLock()
    var value = 0

    let queue = DispatchQueue(label: "MutexLockQueue", qos: .default, attributes: .concurrent)
    
    for _ in 0..<concurrentCount {
        queue.async {
            lock.lock()
            value += 1
            lock.unlock()
        }
    }

    queue.sync(flags: .barrier) { () -> Void in
        assert(value == concurrentCount)
        print("MutexLock Test Success")
    }
}
