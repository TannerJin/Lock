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
    private var waitThreads = [thread_t]()      // 可以考虑优先级队列
    private var waitThreadsValue: Int32 = 0

    public func lock() {
        while !OSAtomicCompareAndSwap32(0, 1, &lockValue) {
            if !yield() { break }   //  发现存在竞争bug(当获取到锁的线程释放锁了，调用完resume()了。但还有没获取锁的线程正在执行yield()，未加入等待队列中，造成该线程永远在等待队列)
        }
    }

    public func unlock() {
        lockValue = 0
        resume()
    }
    
    private func yield() -> Bool {
        let thread = mach_thread_self()
        
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        
        if OSAtomicCompareAndSwap32(0, 1, &lockValue) {     // 防止竞争bug
            waitThreadsValue = 0
            return false
        }
        
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
func TestMutexLock() {
    let concurrentCount = 500
    let lock = MutexLock()  // 可以换成NSLock比较下, 也会比较耗时
    var value = 0

    let queue = DispatchQueue(label: "MutexLockQueue", qos: .default, attributes: .concurrent)
    let queue1 = DispatchQueue(label: "MutexLockQueue2", qos: .userInteractive, attributes: .concurrent)
    
    for i in 0..<concurrentCount {
        if i % 2 == 0 {
            queue.async {
                lock.lock()
                Thread.sleep(forTimeInterval: 0.01)
                value += 1
                lock.unlock()
            }
        } else {
            queue1.async {
                lock.lock()
                Thread.sleep(forTimeInterval: 0.01)
                value += 1
                lock.unlock()
            }
        }
    }

    queue1.sync(flags: .barrier, execute: {})
    queue.sync(flags: .barrier, execute: {})
    
    assert(value == concurrentCount)
    print("MutexLock Test Success")
}
