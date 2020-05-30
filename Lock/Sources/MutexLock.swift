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
    private var waitThreads = [qos_class_t.RawValue: [thread_t]]()
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
        let qos = qos_class_self().rawValue
        
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        
        if waitThreads[qos] != nil {
            waitThreads[qos]?.append(thread)
        } else {
            waitThreads[qos] = [thread]
        }
        
        waitThreadsValue = 0
        thread_suspend(thread)
    }
    
    private func resume() {
        var thread: thread_t?
        
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        if let maxQos = waitThreads.keys.max() {
            thread = waitThreads[maxQos]?.removeFirst()     // FIFO
            if waitThreads[maxQos]?.count == 0 {
                waitThreads[maxQos] = nil
            }
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
    let queue1 = DispatchQueue(label: "MutexLockQueue2", qos: .userInteractive, attributes: .concurrent)
    
    for i in 0..<concurrentCount {
        if i % 2 == 0 {
            queue.async {
                lock.lock()
                value += 1
                lock.unlock()
            }
        } else {
            queue1.async {
                lock.lock()
                value += 1
                lock.unlock()
            }
        }
    }

    queue.sync(flags: .barrier, execute: {})
    queue1.sync(flags: .barrier, execute: {})
    
    assert(value == concurrentCount)
    print("MutexLock Test Success")
}
