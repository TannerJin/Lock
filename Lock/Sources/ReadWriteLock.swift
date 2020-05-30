//
//  ReadWriteLock.swift
//  Lock
//
//  Created by jintao on 2019/11/22.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// 读写锁

public class ReadWriteLock {
    
    public enum RWType {
        case read
        case write
    }
    
    // =-1 : one write thread
    // = 0 : no write and read threads
    // > 0 : count of read threads
    private var readThreadsCount: Int64 = 0
    private var writeThread: thread_t = 0
    
    private var waitThreads = [thread_t]()      // include read and write threads
    private var waitThreadsValue: Int32 = 0
    
    
    public func lock(_ type: RWType) {
        if type == .read {
            lockRead()
        } else {
            lockWrite()
        }
    }
    
    public func unlock() {
        if writeThread == mach_thread_self() {
            unlockWrite()
        } else {
            unlockRead()
        }
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
    
    private func lockRead() {
        while true {
            // 没有写线程 (read_threads_count != -1)
            let old_read_count = OSAtomicAdd64(0, &readThreadsCount)
            
            if old_read_count >= 0 {
                let new_read_count = old_read_count + 1
                if OSAtomicCompareAndSwap64(old_read_count, new_read_count, &readThreadsCount) {
                    break
                }
            } else {
                yield()
            }
        }
    }
    
    private func lockWrite() {
        while true {
            // 没有写线程and读线程 (read_threads_count = 0)
            let old_read_count = OSAtomicAdd64(0, &readThreadsCount)
            
            if old_read_count == 0 {
                let new_read_count: Int64 = -1
                if OSAtomicCompareAndSwap64(old_read_count, new_read_count, &readThreadsCount) {
                    writeThread = mach_thread_self()
                    break
                }
            } else {
                yield()
            }
        }
    }
    
    private func unlockWrite() {
        writeThread = 0
        OSAtomicCompareAndSwap64(-1, 0, &readThreadsCount)
        resume()
    }
    
    private func unlockRead() {
        let oldValue = OSAtomicAdd64(0, &readThreadsCount)
        if oldValue > 0 {
            if OSAtomicIncrement64(&readThreadsCount) == 0 {
                resume()
            }
        }
    }
}


// MARK: Test
func TestReadWriteLock() {
    
}
