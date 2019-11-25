//
//  ReadWriteLock.swift
//  Lock
//
//  Created by jintao on 2019/11/22.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

public class ReadWriteLock {
    
    public enum RWType {
        case read
        case write
    }
    
    // -1: has write thread
    // 0 : has not write and read threads
    // >0: count of read threads
    private var read_threads_count: Int64 = 0
    private var write_thread: UInt32 = 0
    
    private var read_msg_port: mach_port_t
    private var write_msg_port: mach_port_t
    
    public init?() {
        if let read_port = allocatePort(), let write_port = allocatePort() {
            read_msg_port = read_port
            write_msg_port = write_port
        } else {
           return nil
        }
    }
    
    deinit {
        mach_port_deallocate(mach_task_self_, read_msg_port)
        mach_port_deallocate(mach_task_self_, write_msg_port)
    }
    
    // MARK: - Lock
    public func lock(_ type: RWType) {
        if type == .read {
            lockRead()
        } else {
            lockWrite()
        }
    }
    
    private func lockRead() {
        while true {
            // 没有写线程 (read_threads_count != -1)
            let pre_read_count = OSAtomicAdd64(0, &read_threads_count)  // 原子加载read_threads_count
            
            if pre_read_count >= 0 {
                let new_read_count = pre_read_count + 1
                if OSAtomicCompareAndSwap64(pre_read_count, new_read_count, &read_threads_count) {
                    break
                }
            } else {
                // 暂停线程调度，等待写线程解锁唤醒
                lock_message_receive(port: read_msg_port)
            }
        }
    }
    
    private func lockWrite() {
        while true {
            // 没有写线程and读线程 (read_threads_count = 0)
            let pre_read_count = OSAtomicAdd64(0, &read_threads_count)
            
            if pre_read_count == 0 {
                let new_read_count: Int64 = -1
                if OSAtomicCompareAndSwap64(pre_read_count, new_read_count, &read_threads_count) {
                    write_thread = mach_thread_self()
                    break
                }
            } else {
                // 暂停线程调度，等待没有线程持有锁时唤醒
                lock_message_receive(port: write_msg_port)
            }
        }
    }
    
    // MARK: - Unlock
    public func unlock() {
        if write_thread == mach_thread_self() {
            unlockWrite()
        } else {
            unlockRead()
        }
    }
    
    private func unlockRead() {
        if OSAtomicAdd64(-1, &read_threads_count) == 0 {
            
            // 通知在等待的写线程
            lock_message_send(port: write_msg_port)
        }
    }
    
    private func unlockWrite() {
        write_thread = 0
        OSAtomicCompareAndSwap64(-1, 0, &read_threads_count)
        
        // 通知在等待的写线程
        lock_message_send(port: write_msg_port)
        // 通知在等待的读线程
        lock_message_send(port: read_msg_port)
    }
}


// MARK: Test
func TestReadWriteLock() {
    let thread_count = 1000
    let lock = ReadWriteLock()
    var value = 0
    
    assert(lock != nil)
        
    for _ in 0..<thread_count {
        Thread.detachNewThread {
            Thread.sleep(forTimeInterval: 0.99)  // for concurrent

            lock!.lock(.write)
            value += 1
            lock!.unlock()
        }
        
        Thread.detachNewThread {
            Thread.sleep(forTimeInterval: 1)  // for concurrent

            lock!.lock(.read)
//            print("readWriteLock => index \(i)  value \(value)")
            lock!.unlock()
        }
    }

    RunLoop.current.run(until: Date() + 5)

    assert(value == thread_count)
}

