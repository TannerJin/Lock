//
//  MutexRecursiveLock.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

class MutexRecursiveLock {
    private var context: UnsafeMutableRawPointer
    private var lock_msg_port: mach_port_t
    
    private var thread: Int = -1
    private var recursive_count = 0
    
    init?() {
        if let _context = malloc(MemoryLayout<UnsafeRawPointer>.size), let localPort = mallocPortWith(context: UInt(bitPattern: _context)) {
            context = _context
            lock_msg_port = localPort
        } else {
            return nil
        }
    }
    
    deinit {
        freePort(lock_msg_port)
        free(context)
    }
    
    public func lock() {
        while !OSAtomicCompareAndSwapLong(-1, Int(mach_thread_self()), &thread) {
            if thread == mach_thread_self() {
                break
            }
            // 非忙等，将线程加入到消息等待队列；等到解锁消息到来，重新加入调度队列尝试获取锁  or  thread_suspend(锁持有所有暂停线程)
            lock_message_receive(port: lock_msg_port)
        }
        
        recursive_count += 1
    }
    
    public func unlock() {
        recursive_count -= 1
        
        if recursive_count == 0 {
            thread = -1
            // 发送解锁消息  or  thread_resume
            lock_message_send(port: lock_msg_port)
        }
    }
}


// MARK: Test
func TestMutexRecursiveLock() {
    let thread_count = 500
    let recursive_count = 3
    let lock = MutexRecursiveLock()
    var value = 0
    
    assert(lock != nil)

    for _ in 0..<thread_count {
        Thread.detachNewThread {
            Thread.sleep(forTimeInterval: 1)  // for concurrent
            
            for _ in 0..<recursive_count {
                lock!.lock()
                value += 1
            }
            // .
            // .
            // .
            for _ in 0..<recursive_count {
                lock!.unlock()
            }
        }
    }

    RunLoop.current.run(until: Date() + 3)

    assert(value == thread_count*recursive_count)
}
