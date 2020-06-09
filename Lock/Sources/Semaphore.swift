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
    // <=0: wait
    private var lockValue: Int64
    private var waitThreads = [thread_t]()
    private var waitThreadsValue: Int32 = 0
    
    public init(value: Int64) {
        self.lockValue = value
    }
    
    public func wait() {
        while true {
            /* (Bool, Bool)
               第一个为true。表示当前线程有能力获取锁，但是在第二步，被其他线程抢先获取了锁。因此`continue`继续尝试
               第二个为true。表示获取了锁
            */
            let getLock = { () -> (Bool, Bool) in
                let oldValue = OSAtomicAdd64(0, &self.lockValue)  // get value
                if oldValue > 0 {
                    let newValue = oldValue - 1
                    if OSAtomicCompareAndSwap64(oldValue, newValue, &self.lockValue) {
                        return (true, true)
                    }
                    return (true, false)
                }
                return (false, false)
            }
            
            let getLockResult = getLock()
            if getLockResult.1 {
                break
            } else if getLockResult.0 {
                continue
            } else {
                if !yield(tryGetLock: getLock) { break }
            }
        }
    }
    
    @discardableResult
    public func signal() -> Int {
        let _value = OSAtomicIncrement64(&lockValue)
        if _value > 0 {
            resume()
        }
        return Int(_value)
    }
    
    private func yield(tryGetLock: ()->(Bool,Bool)) -> Bool {
        while !OSAtomicCompareAndSwap32(0, 1, &waitThreadsValue) {}
        
        // 防止竞争bug(当获取到锁的线程释放锁了，调用完resume()了。但还有没获取锁的线程正在执行yield()，但未加入等待队列中，造成该线程永远在等待队列)
        if tryGetLock().1 {
            waitThreadsValue = 0
            return false
        }
        
        // 加入wait队列
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
func TestSemaphore() {
    
}
