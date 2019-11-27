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
    // =0: wait
    private var value: Int64
    private var signal_port: mach_port_t
    
    public init?(value: Int64) {
        if let port = allocatePort() {
            signal_port = port
            self.value = value
        } else {
            return nil
        }
    }
    
    deinit {
        mach_port_deallocate(mach_task_self_, signal_port)
    }
    
    public func wait() {
        while true {
            let old_value = OSAtomicAdd64(0, &value)  // get value
            if old_value > 0 {
                let new_value = old_value - 1
                if OSAtomicCompareAndSwap64(old_value, new_value, &value) {
                    break
                }
            } else {
                // 等待信号消息, 等待队列
                lock_message_receive(port: signal_port)
            }
        }
    }
    
    public func signal() {
        if OSAtomicIncrement64(&value) > 0 {
            // 发送信号消息
            lock_message_send(port: signal_port)
        }
    }
}


// MARK: Test

func TestSemaphore() {
    let concurrent_count = 1000
    let semaphore = Semaphore(value: Int64(concurrent_count))
    
    assert(semaphore != nil)
    
    var array = Array<Int>(repeating: 0, count: concurrent_count)
    let spinLock = SpinLock()
    
    for i in 0..<concurrent_count {
        Thread.detachNewThread {
            semaphore!.wait()
            Thread.sleep(forTimeInterval: 0.5)    // for semaphore wait
            
            spinLock.lock()
            array[i] = i                          // 多线程修改
            spinLock.unlock()
            
            Thread.sleep(forTimeInterval: 1)      // for semaphore wait
            semaphore!.signal()
        }
    }
    
    Thread.detachNewThread {
        Thread.sleep(forTimeInterval: 0.5)
        semaphore?.wait()
        
        let orig_result = Array<Int>(0..<concurrent_count).reduce(0) { (result, element) -> Int in
            result + element
        }
        let result = array.reduce(0) { (result, element) -> Int in
            result + element
        }
        assert(result == orig_result)
        
        semaphore?.signal()
    }
    
    RunLoop.current.run(until: Date() + 3)    
}
