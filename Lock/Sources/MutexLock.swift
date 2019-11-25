//
//  MutexLock.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

public class MutexLock {
    private var context: UnsafeMutableRawPointer
    private var lock_msg_port: mach_port_t
    
    private var value: Int32 = 0
    
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
        while !OSAtomicCompareAndSwap32(0, 1, &value) {
            // 非忙等，将线程加入到消息等待队列；等到解锁消息到来，重新调度尝试获取锁  or  thread_suspend(锁持有所有暂停线程)
            lock_message_receive(port: lock_msg_port)
        }
    }
    
    public func unlock() {
        value = 0
        // 发送解锁消息  or  thread_resume
        lock_message_send(port: lock_msg_port)
    }
}


// MARK: Test
func TestMutexLock() {
    let thread_count = 1000
    let lock = MutexLock()
    var value = 0
    
    assert(lock != nil)

    for _ in 0..<thread_count {
        Thread.detachNewThread {
            Thread.sleep(forTimeInterval: 1)  // for concurrent
            
            lock!.lock()
            value += 1
            lock!.unlock()
        }
    }

    RunLoop.current.run(until: Date() + 4)

    assert(value == thread_count)
}
