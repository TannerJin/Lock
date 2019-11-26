//
//  SpinLock.swift
//  Lock
//
//  Created by jintao on 2019/11/21.
//  Copyright © 2019 jintao. All rights reserved.
//

import Foundation

// 自旋锁

public class SpinLock {
    private var value: Int32 = 0
    private static var PreQosClassKey: pthread_key_t = 0

    public func lock() {
        while !OSAtomicCompareAndSwap32(0, 1, &value) {}

        // QOS_CLASS_BACKGROUND        : 9
        // QOS_CLASS_UTILITY           : 17
        // QOS_CLASS_DEFAULT           : 21
        // QOS_CLASS_USER_INITIATED    : 25
        // QOS_CLASS_USER_INTERACTIVE  : 33

        // fix优先级反转(提高获取到锁的线程优先级, 目前是这个) or (降低没获取到锁的线程优先级)
        // lock   提升优先级
        // unlock 恢复线程优先级
        let preQosClassSelf = qos_class_self()

        if preQosClassSelf.rawValue <= QOS_CLASS_DEFAULT.rawValue {
            let pointer = malloc(MemoryLayout<qos_class_t>.size)
            pointer?.bindMemory(to: qos_class_t.self, capacity: 1).initialize(to: preQosClassSelf)

            if SpinLock.PreQosClassKey == 0 {
                pthread_key_create(&SpinLock.PreQosClassKey, nil)
            }
            pthread_setspecific(SpinLock.PreQosClassKey, pointer)

            pthread_set_qos_class_self_np(QOS_CLASS_USER_INITIATED, 0)
        }
    }

    public func unlock() {
        var preQosClassSelf: UnsafeMutablePointer<qos_class_t>?

        if SpinLock.PreQosClassKey != 0 {
            preQosClassSelf = pthread_getspecific(SpinLock.PreQosClassKey)?.assumingMemoryBound(to: qos_class_t.self)
            pthread_setspecific(SpinLock.PreQosClassKey, nil)
        }

        value = 0
        
        if preQosClassSelf != nil {
            pthread_set_qos_class_self_np(preQosClassSelf!.pointee, 0)
            free(preQosClassSelf)
        }
    }
}


// MARK: Test
func TestSpinLock() {
    let thread_count = 1000
    let lock = SpinRecursiveLock()
    var value = 0

    for _ in 0..<thread_count {
        Thread.detachNewThread {
            Thread.sleep(forTimeInterval: 1)  // for concurrent

            pthread_set_qos_class_self_np(QOS_CLASS_BACKGROUND, 0)   // 降低优先级测试
            lock.lock()
            value += 1
            lock.unlock()
        }
    }

    RunLoop.current.run(until: Date() + 3) // for concurrent of child thread

    assert(value == thread_count)
}
