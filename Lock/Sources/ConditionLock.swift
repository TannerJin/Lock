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
    private var _condition: Int64
    private var value: Int32 = 0
    private var lock_msg_port: mach_port_t
    
    init?(condition: Int64) {
        if let port = allocatePort() {
            lock_msg_port = port
            _condition = condition
        } else {
            return nil
        }
    }
    
    deinit {
        freePort(lock_msg_port)
    }
    
    public func lock() {
        while !OSAtomicCompareAndSwap32(0, 1, &value) {
            lock_message_receive(at: lock_msg_port)
        }
    }
    
    public func unlock() {
        while true {
            let old_value = OSAtomicAdd32(0, &value)
            if OSAtomicCompareAndSwap32(old_value, 0, &value) {
                break
            }
        }
        lock_message_send(to: lock_msg_port)
    }
    
    public func lock(whenCondition condition: Int64) {
        while true {
            if OSAtomicCompareAndSwap32(0, 1, &value) {   // 先抢占锁
                if OSAtomicAdd64(0, &_condition) == condition {  // 再判断条件是否符合
                    break
                } else {
                    unlock()
                }
            }
            lock_message_receive(at: lock_msg_port)
        }
    }
    
    public func unlock(withCondition condition: Int64) {
        while !OSAtomicCompareAndSwap64(_condition, condition, &_condition) {}  // _condition加载非原子性(缓存/内存加载到rsi寄存器(x86))，&_condition加载原子性
        unlock()
    }
}


// MARK: Test

func TestConditionLock() {
    let thread_count = 2000
    let conditionLock = ConditionLock(condition: 2001)
    var value = 0
    
    assert(conditionLock != nil)
    
    for i in 0..<thread_count {
        Thread.detachNewThread {
            conditionLock!.lock()
            value = i
            conditionLock!.unlock(withCondition: Int64(i))
        }
        Thread.detachNewThread {
            conditionLock!.lock(whenCondition: Int64(i))
            assert(value == i)
            conditionLock!.unlock()
        }
    }
    
    RunLoop.current.run(until: Date() + 3)
}
